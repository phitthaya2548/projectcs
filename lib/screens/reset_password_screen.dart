import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResetWithPhoneOtpScreen extends StatefulWidget {
  const ResetWithPhoneOtpScreen({super.key});

  @override
  State<ResetWithPhoneOtpScreen> createState() => _ResetWithPhoneOtpScreenState();
}

class _ResetWithPhoneOtpScreenState extends State<ResetWithPhoneOtpScreen> {
  final _formKey = GlobalKey<FormState>();

  final phoneCtl = TextEditingController();
  final otpCtl = TextEditingController();
  final newPassCtl = TextEditingController();

  bool loading = false;
  bool codeSent = false;

  String? _verificationId;

  // ✅ แปลงเบอร์ไทย -> E.164 (Firebase ต้องการ)
  String normalizeThaiPhoneToE164(String input) {
    var s = input.trim();
    s = s.replaceAll(RegExp(r'[\s\-\(\)]'), ''); // ลบช่องว่าง/ขีด/วงเล็บ

    // 0xxxxxxxxx -> +66xxxxxxxxx
    if (s.startsWith('0')) {
      s = '+66${s.substring(1)}';
    }
    // 66xxxxxxxxx -> +66xxxxxxxxx
    else if (s.startsWith('66')) {
      s = '+$s';
    }
    // +66xxxxxxxxx -> ใช้ได้เลย

    return s;
  }

  bool looksLikeE164(String s) {
    return RegExp(r'^\+\d{10,15}$').hasMatch(s);
  }

  String? _phoneValidator(String? v) {
    final raw = (v ?? '').trim();
    if (raw.isEmpty) return "กรอกเบอร์โทรก่อน";

    final e164 = normalizeThaiPhoneToE164(raw);

    if (!looksLikeE164(e164)) {
      return "กรอกเบอร์ให้ถูก เช่น 062xxxxxxx หรือ +66xxxxxxxxx";
    }
    return null;
  }

  String? _otpValidator(String? v) {
    final s = (v ?? '').trim();
    if (!codeSent) return null;
    if (s.isEmpty) return "กรอก OTP ก่อน";
    if (s.length < 6) return "OTP ไม่ครบ";
    return null;
  }

  String? _passValidator(String? v) {
    final s = (v ?? '');
    if (!codeSent) return null;
    if (s.isEmpty) return "กรอกรหัสผ่านใหม่ก่อน";
    if (s.length < 8) return "รหัสผ่านอย่างน้อย 8 ตัว";
    return null;
  }

  void _resetOtpState() {
    codeSent = false;
    _verificationId = null;
    otpCtl.clear();
    newPassCtl.clear();
  }

  Future<void> sendOtp() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final phoneE164 = normalizeThaiPhoneToE164(phoneCtl.text);

    setState(() {
      loading = true;
      // ขอ OTP ใหม่ -> เคลียร์ state เก่า
      _resetOtpState();
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneE164,
        timeout: const Duration(seconds: 60),

        verificationCompleted: (PhoneAuthCredential credential) async {
          // บางเครื่อง auto verify ได้ แต่กรณี reset ให้ผู้ใช้กรอกรหัสใหม่เอง
        },

        verificationFailed: (FirebaseAuthException e) {
          String msg = e.message ?? "ส่ง OTP ไม่สำเร็จ";
          if (e.code == "invalid-phone-number") msg = "เบอร์โทรไม่ถูกต้อง";
          if (e.code == "too-many-requests") msg = "ขอ OTP ถี่เกินไป ลองใหม่ภายหลัง";
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        },

        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            codeSent = true;
            _verificationId = verificationId;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("ส่ง OTP แล้ว กรุณาตรวจ SMS")),
          );
        },

        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> confirmAndReset() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final vid = _verificationId;
    if (vid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ยังไม่ได้ส่ง OTP หรือหมดอายุ กรุณาขอ OTP ใหม่")),
      );
      return;
    }

    final smsCode = otpCtl.text.trim();
    final newPass = newPassCtl.text;

    setState(() => loading = true);

    try {
      final cred = PhoneAuthProvider.credential(
        verificationId: vid,
        smsCode: smsCode,
      );

      // ✅ Sign-in ด้วยเบอร์ (ต้องเป็นบัญชีที่ผูกเบอร์กับ account เดิม)
      final userCred = await FirebaseAuth.instance.signInWithCredential(cred);
      final user = userCred.user;

      if (user == null) {
        throw FirebaseAuthException(code: "no-user", message: "ไม่สามารถยืนยันผู้ใช้ได้");
      }

      // ✅ ตั้งรหัสใหม่
      await user.updatePassword(newPass);

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("สำเร็จ"),
          content: const Text("รีเซ็ตรหัสผ่านเรียบร้อยแล้ว กรุณาเข้าสู่ระบบใหม่"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("ตกลง"),
            ),
          ],
        ),
      );

      if (!mounted) return;
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String msg = e.message ?? "ทำรายการไม่สำเร็จ";
      if (e.code == "invalid-verification-code") msg = "OTP ไม่ถูกต้อง";
      if (e.code == "session-expired") msg = "OTP หมดอายุ กรุณาขอใหม่";
      if (e.code == "weak-password") msg = "รหัสผ่านอ่อนเกินไป";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    phoneCtl.dispose();
    otpCtl.dispose();
    newPassCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("รีเซ็ตรหัสผ่านด้วย OTP")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("กรอกเบอร์โทรเพื่อรับ OTP (พิมพ์ 0xxxx หรือ +66 ก็ได้)"),
              const SizedBox(height: 12),

              TextFormField(
                controller: phoneCtl,
                keyboardType: TextInputType.phone,
                validator: _phoneValidator,
                onChanged: (_) {
                  // ถ้าเปลี่ยนเบอร์หลังส่งโค้ดแล้ว ให้รีเซ็ต state OTP
                  if (codeSent) setState(_resetOtpState);
                },
                decoration: const InputDecoration(
                  labelText: "Phone",
                  hintText: "062xxxxxxx หรือ +66xxxxxxxxx",
                  helperText: "ระบบจะแปลงเป็น +66 อัตโนมัติ",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading ? null : sendOtp,
                  child: Text(loading ? "กำลังส่ง..." : "ส่ง OTP"),
                ),
              ),

              const SizedBox(height: 16),
              if (codeSent) ...[
                TextFormField(
                  controller: otpCtl,
                  keyboardType: TextInputType.number,
                  validator: _otpValidator,
                  decoration: const InputDecoration(
                    labelText: "OTP",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: newPassCtl,
                  obscureText: true,
                  validator: _passValidator,
                  decoration: const InputDecoration(
                    labelText: "รหัสผ่านใหม่",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading ? null : confirmAndReset,
                    child: Text(loading ? "กำลังยืนยัน..." : "ยืนยัน OTP และเปลี่ยนรหัสผ่าน"),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
