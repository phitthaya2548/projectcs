import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final picker = ImagePicker();

  File? slipFile;

  // ✅ กันซ้ำ “จริง” ด้วย hash (ไม่ใช่ path)
  String? lastSlipHash;

  bool loading = false;

  // TODO: เปลี่ยนเป็น API ของคุณ
  final String verifySlipUrl = "http://10.0.2.2:3000/checkslip/verify";

  /// ✅ copy รูปจาก cache -> โฟลเดอร์ถาวรของแอป (กัน PathNotFoundException)
  Future<File> _persistSlip(XFile x) async {
    final dir = await getApplicationDocumentsDirectory();

    // บังคับให้มีนามสกุล (กัน lookupMimeType เดาไม่ได้)
    final ext = p.extension(x.path).isNotEmpty ? p.extension(x.path) : ".jpg";

    final newPath = p.join(
      dir.path,
      "slip_${DateTime.now().millisecondsSinceEpoch}$ext",
    );

    return File(x.path).copy(newPath);
  }

  /// ✅ ทำ hash ของรูป เพื่อกันแนบสลิปเดิมซ้ำแม้ path เปลี่ยน
  Future<String> _hashFile(File f) async {
    final bytes = await f.readAsBytes();
    return sha256.convert(bytes).toString();
  }

  Future<void> pickSlip() async {
    if (loading) return;

    final x = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x == null) return;

    // ✅ copy ไปถาวรก่อน
    final saved = await _persistSlip(x);

    // ✅ กันรูปเดิมซ้ำด้วย hash
    final h = await _hashFile(saved);
    if (lastSlipHash != null && h == lastSlipHash) {
      // ลบไฟล์ที่เพิ่ง copy มา (กันเปลืองพื้นที่)
      saved.delete().catchError((_) {});
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("สลิปนี้เคยแนบแล้ว กรุณาเลือกรูปใหม่")),
      );
      return;
    }

    setState(() {
      slipFile = saved;
      lastSlipHash = h;
    });
  }

  void clearSlip() {
    final f = slipFile;

    setState(() {
      slipFile = null;

      // ✅ ถ้าอยาก “ห้ามใช้สลิปเดิมซ้ำแม้กดลบ” ให้คง lastSlipHash ไว้
      // ถ้าอยากให้ลบแล้วเลือกเดิมได้ ให้เปิดบรรทัดนี้:
      // lastSlipHash = null;
    });

    // ✅ ลบไฟล์ที่ copy ไว้ (กันเปลืองพื้นที่)
    if (f != null) {
      f.delete().catchError((_) {});
    }
  }

  Future<void> submitTopup() async {
    if (loading) return;

    if (slipFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณาอัปโหลดสลิปก่อน")),
      );
      return;
    }

    // ✅ กันไฟล์หาย
    if (!await slipFile!.exists()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ไฟล์สลิปหาย กรุณาเลือกใหม่")),
      );
      clearSlip();
      return;
    }

    setState(() => loading = true);

    try {
      final req = http.MultipartRequest("POST", Uri.parse(verifySlipUrl));

      // ✅ ตั้ง mimetype ให้ชัด ลดโอกาสเป็น octet-stream
      final mimeType = lookupMimeType(slipFile!.path) ?? "image/jpeg";
      final parts = mimeType.split('/');
      final mediaType = MediaType(parts[0], parts.length > 1 ? parts[1] : "jpeg");

      req.files.add(await http.MultipartFile.fromPath(
        "file",
        slipFile!.path,
        contentType: mediaType,
      ));

      final streamed = await req.send();
      final body = await streamed.stream.bytesToString();

      Map<String, dynamic> jsonBody = {};
      try {
        jsonBody = json.decode(body) as Map<String, dynamic>;
      } catch (_) {}

      if (!mounted) return;

      if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ตรวจสลิปสำเร็จ ✅ เติมเงินเรียบร้อย")),
        );

        // ✅ สำเร็จแล้วเคลียร์ไฟล์ออกจากหน้าจอ
        clearSlip();
      } else {
        final msg = jsonBody["message"]?.toString() ?? "ตรวจสลิปไม่สำเร็จ";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$msg (${streamed.statusCode})")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("เกิดข้อผิดพลาด: $e")),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("วอลเล็ต", style: TextStyle(fontWeight: FontWeight.w600,color: Colors.white),),
        centerTitle: true,
        backgroundColor: Color(0xFF0593FF),
      ),
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE6E6E6)),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 16,
                      offset: Offset(0, 6),
                      color: Color(0x11000000),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        "assets/images/qrcode.jpg",
                        height: 350,
                        width: 350,
                        fit: BoxFit.fitWidth,
                        errorBuilder: (_, __, ___) {
                          return Container(
                            height: 180,
                            alignment: Alignment.center,
                            color: const Color(0xFFF2F4F7),
                            child: const Text("ใส่รูป QR "),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "แนบสลิปเติมเงิน",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: loading ? null : pickSlip,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                          color: const Color(0xFFF8FAFC),
                        ),
                        child: slipFile == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.photo_camera_outlined,
                                    size: 32,
                                    color: loading ? Colors.grey : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    loading ? "กำลังส่ง..." : "อัปโหลดรูปภาพ",
                                    style: const TextStyle(color: Color(0xFF64748B)),
                                  ),
                                ],
                              )
                            : Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      slipFile!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: 120,
                                    ),
                                  ),
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: InkWell(
                                      onTap: loading ? null : clearSlip,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.55),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: const Icon(Icons.close, color: Colors.white, size: 18),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "ระบบจะไม่อนุญาตให้แนบสลิปเดิมซ้ำ",
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: loading ? null : submitTopup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text("เติมเงิน"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
