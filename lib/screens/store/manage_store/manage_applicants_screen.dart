// screens/store/manage_applicants_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:wash_and_dry/config/config.dart';
import 'package:wash_and_dry/models/res/customer/store/res_store_applicants.dart';

import 'package:wash_and_dry/service/session_service.dart';

class _Palette {
  static const primary = Color(0xFF0593FF);
  static const primaryTint = Color(0xFFEAF4FF);
  static const mint = Color(0xFF17B990);
  static const danger = Color(0xFFE5484D);
  static const dangerTint = Color(0xFFFDEBEC);
  static const ink = Color(0xFF16202A);
  static const muted = Color(0xFF6B7785);
  static const mutedLight = Color(0xFFC7CDD4);
  static const surface = Colors.white;
  static const bg = Color(0xFFF5F7FA);
}

class ManageApplicantsScreen extends StatefulWidget {
  const ManageApplicantsScreen({Key? key}) : super(key: key);

  @override
  State<ManageApplicantsScreen> createState() => _ManageApplicantsScreenState();
}

class _ManageApplicantsScreenState extends State<ManageApplicantsScreen> {
  String _url = '';
  String? _storeId;
  bool _isLoading = true;
  bool _hasChanged = false;

  List<RiderApplicant> _riders = [];
  List<StaffApplicant> _staff = [];

  // เก็บ id ที่กำลังกดปุ่มอยู่ กันกดซ้ำเฉพาะการ์ดนั้น
  final Set<String> _processingIds = {};

  // ---- Hiring toggle state ----
  bool _isHiring = true;
  bool _isHiringLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  int get _total => _riders.length + _staff.length;

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final config = await Configuration.getConfig();
      final session = Session();
      final storeId = await session.getStoreId();

      if (storeId == null || storeId.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      _storeId = storeId;
      _url = config['apiEndpoint']?.toString() ?? '';

      // โหลดสถานะรับสมัครคู่กันไปเลย
      await _loadHiringStatus();

      final response =
          await http.get(Uri.parse('$_url/employee_regis_store/store/$storeId/applicants'));
      if (response.statusCode == 200) {
        final data = StoreApplicantsResponse.fromJson(json.decode(response.body));
        if (data.ok) {
          setState(() {
            _riders = data.riders;
            _staff = data.staff;
          });
        }
      }
    } catch (e) {
      debugPrint('Load applicants error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadHiringStatus() async {
    if (_storeId == null || _url.isEmpty) return;
    try {
      final response = await http.get(
        Uri.parse('$_url/employee_regis_store/store/$_storeId/hiring-status'),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['ok'] == true) {
        setState(() {
          _isHiring = data['data']?['is_hiring'] ?? true;
        });
      }
    } catch (e) {
      debugPrint('Load hiring status error: $e');
    }
  }

  Future<void> _toggleHiring(bool value) async {
    if (_storeId == null || _url.isEmpty || _isHiringLoading) return;

    setState(() => _isHiringLoading = true);
    final previous = _isHiring;
    setState(() => _isHiring = value);

    try {
      final response = await http.put(
        Uri.parse('$_url/employee_regis_store/store/$_storeId/hiring'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'isHiring': value}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['ok'] == true) {
        _hasChanged = true;
        _showSnack(
          title: 'สำเร็จ',
          message: data['message'] ?? '',
          success: true,
        );
      } else {
        setState(() => _isHiring = previous); // rollback
        _showSnack(
          title: 'ข้อผิดพลาด',
          message: data['message'] ?? 'ดำเนินการไม่สำเร็จ',
          success: false,
        );
      }
    } catch (e) {
      setState(() => _isHiring = previous); // rollback
      _showSnack(
        title: 'ข้อผิดพลาด',
        message: 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้',
        success: false,
      );
    } finally {
      if (mounted) setState(() => _isHiringLoading = false);
    }
  }

  Future<void> _updateStatus({
    required String userId,
    required String role, // 'rider' หรือ 'laundry_staff'
    required String action, // 'approve' หรือ 'reject'
    required String name,
  }) async {
    if (_storeId == null || _url.isEmpty) return;

    setState(() => _processingIds.add(userId));

    try {
      final response = await http.put(
        Uri.parse('$_url/employee_regis_store/store/$_storeId/applicant/$userId/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'role': role, 'action': action}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['ok'] == true) {
        _hasChanged = true;
        _showSnack(
          title: 'สำเร็จ',
          message: data['message'] ?? (action == 'approve' ? 'ยืนยัน "$name" สำเร็จ' : 'ปฏิเสธ "$name" สำเร็จ'),
          success: true,
        );
        // ลบออกจาก list ทันทีโดยไม่ต้องรอโหลดใหม่ทั้งหมด
        setState(() {
          _riders.removeWhere((r) => r.riderId == userId);
          _staff.removeWhere((s) => s.staffId == userId);
        });
      } else {
        _showSnack(
          title: 'ข้อผิดพลาด',
          message: data['message'] ?? 'ดำเนินการไม่สำเร็จ',
          success: false,
        );
      }
    } catch (e) {
      _showSnack(
        title: 'ข้อผิดพลาด',
        message: 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้',
        success: false,
      );
    } finally {
      if (mounted) setState(() => _processingIds.remove(userId));
    }
  }

  void _showSnack({required String title, required String message, required bool success}) {
    Get.snackbar(
      title,
      message,
      backgroundColor: success ? _Palette.mint : _Palette.danger,
      colorText: Colors.white,
      icon: Icon(success ? Icons.check_circle_rounded : Icons.error_rounded, color: Colors.white),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
      duration: const Duration(seconds: 3),
    );
  }

  void _confirmReject({required String userId, required String role, required String name}) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: _Palette.dangerTint, shape: BoxShape.circle),
                child: const Icon(Icons.person_remove_rounded, color: _Palette.danger, size: 28),
              ),
              const SizedBox(height: 18),
              const Text(
                'ปฏิเสธผู้สมัคร',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _Palette.ink),
              ),
              const SizedBox(height: 8),
              Text(
                'คุณต้องการปฏิเสธ "$name" ใช่หรือไม่',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13.5, color: _Palette.muted, height: 1.4),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        backgroundColor: _Palette.bg,
                        foregroundColor: _Palette.muted,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('ยกเลิก', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        _updateStatus(userId: userId, role: role, action: 'reject', name: name);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _Palette.danger,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('ปฏิเสธ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _hasChanged);
      },
      child: Scaffold(
        backgroundColor: _Palette.bg,
        appBar: _buildAppBar(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _Palette.primary, strokeWidth: 2.6))
            : RefreshIndicator(
                color: _Palette.primary,
                onRefresh: () async {
                  await _loadHiringStatus();
                  await _loadData();
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                  children: [
                    _hiringToggleCard(),
                    if (_total == 0)
                      _buildEmptyView()
                    else ...[
                      if (_riders.isNotEmpty) ...[
                        _sectionLabel('ไรเดอร์', _riders.length, Icons.delivery_dining_rounded, _Palette.primary),
                        const SizedBox(height: 10),
                        ..._riders.map(
                          (r) => _applicantCard(
                            id: r.riderId,
                            role: 'rider',
                            name: r.fullname,
                            phone: r.phone,
                            profileImage: r.profileImage,
                            roleIcon: Icons.pedal_bike_rounded,
                            roleColor: _Palette.primary,
                            appliedAt: r.appliedAt,
                            extraTag: r.licensePlate.isNotEmpty
                                ? _metaTag(Icons.badge_outlined, r.licensePlate.toUpperCase())
                                : null,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (_staff.isNotEmpty) ...[
                        _sectionLabel(
                            'พนักงานซักอบ', _staff.length, Icons.local_laundry_service_rounded, _Palette.mint),
                        const SizedBox(height: 10),
                        ..._staff.map(
                          (s) => _applicantCard(
                            id: s.staffId,
                            role: 'laundry_staff',
                            name: s.fullname,
                            phone: s.phone,
                            profileImage: s.profileImage,
                            roleIcon: Icons.local_laundry_service_rounded,
                            roleColor: _Palette.mint,
                            appliedAt: s.appliedAt,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0593FF), Color(0xFF0476D9)],
          ),
        ),
      ),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
        onPressed: () => Navigator.pop(context, _hasChanged),
      ),
      centerTitle: true,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'ผู้สมัครรอยืนยัน',
            style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.2),
          ),
          if (!_isLoading && _total > 0)
            Text(
              '$_total รายการ',
              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11.5, fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }

  Widget _hiringToggleCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: _Palette.ink.withOpacity(0.045), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (_isHiring ? _Palette.mint : _Palette.muted).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.badge_outlined,
              size: 18,
              color: _isHiring ? _Palette.mint : _Palette.muted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'เปิดรับสมัครพนักงาน',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _Palette.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  _isHiring ? 'กำลังเปิดรับสมัคร' : 'ปิดรับสมัครอยู่',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: _isHiring ? _Palette.mint : _Palette.muted,
                  ),
                ),
              ],
            ),
          ),
          _isHiringLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2, color: _Palette.primary),
                )
              : Switch(
                  value: _isHiring,
                  activeColor: _Palette.mint,
                  onChanged: _toggleHiring,
                ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String title, int count, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: _Palette.ink),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
          child: Text(
            '$count',
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: color),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyView() {
    return Column(
      children: [
        const SizedBox(height: 80),
        Icon(Icons.inbox_rounded, size: 48, color: _Palette.mutedLight),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            'ยังไม่มีผู้สมัครรอยืนยัน',
            style: TextStyle(fontSize: 13, color: _Palette.muted, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _applicantCard({
    required String id,
    required String role,
    required String name,
    required String phone,
    required String profileImage,
    required IconData roleIcon,
    required Color roleColor,
    DateTime? appliedAt,
    Widget? extraTag,
  }) {
    final isProcessing = _processingIds.contains(id);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: _Palette.ink.withOpacity(0.045), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: roleColor.withOpacity(0.35))),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: _Palette.primaryTint,
                  backgroundImage: profileImage.isNotEmpty ? NetworkImage(profileImage) : null,
                  child: profileImage.isEmpty
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(fontWeight: FontWeight.w800, color: _Palette.primary, fontSize: 15),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(roleIcon, size: 13, color: roleColor),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            name.isNotEmpty ? name : '-',
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: _Palette.ink),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (phone.isNotEmpty) _metaTag(Icons.phone_rounded, phone),
                        if (extraTag != null) extraTag,
                        if (appliedAt != null) _metaTag(Icons.schedule_rounded, _formatDate(appliedAt)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  label: 'ปฏิเสธ',
                  icon: Icons.close_rounded,
                  color: _Palette.danger,
                  isLoading: isProcessing,
                  onPressed: isProcessing ? null : () => _confirmReject(userId: id, role: role, name: name),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionButton(
                  label: 'รับเข้าร้าน',
                  icon: Icons.check_rounded,
                  color: _Palette.mint,
                  isLoading: isProcessing,
                  onPressed:
                      isProcessing ? null : () => _updateStatus(userId: id, role: role, action: 'approve', name: name),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isLoading,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        disabledBackgroundColor: color.withOpacity(0.5),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: isLoading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
    );
  }

  Widget _metaTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: _Palette.bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: _Palette.muted),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: _Palette.muted)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'วันนี้';
    if (diff.inDays == 1) return 'เมื่อวาน';
    if (diff.inDays < 7) return '${diff.inDays} วันก่อน';
    return '${date.day}/${date.month}/${date.year + 543}';
  }
}