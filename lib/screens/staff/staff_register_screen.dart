import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:wash_and_dry/config/config.dart';
import 'package:wash_and_dry/models/req/store/req_register_laundry_staff_store.dart';
import 'package:wash_and_dry/screens/login_screen.dart';
import 'package:wash_and_dry/service/session_service.dart';

class StaffRegisterScreen extends StatefulWidget {
  const StaffRegisterScreen({Key? key}) : super(key: key);

  @override
  State<StaffRegisterScreen> createState() => _StaffRegisterScreenState();
}

class _StaffRegisterScreenState extends State<StaffRegisterScreen> {
  static const primaryBlue = Color(0xFF0593FF);
  static const lightBlue = Color(0xFFEFF7FF);
  static const darkText = Color(0xFF1A2332);

  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _controllers = {
    'email': TextEditingController(),
    'username': TextEditingController(),
    'password': TextEditingController(),
    'confirmPassword': TextEditingController(),
    'fullName': TextEditingController(),
    'phone': TextEditingController(),
  };

  File? _profileImage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String url = '';

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _controllers.forEach((_, c) => c.dispose());
    super.dispose();
  }

  Future<void> _loadConfig() async {
    try {
      final config = await Configuration.getConfig();
      setState(() => url = config['apiEndpoint']?.toString() ?? '');
    } catch (_) {}
  }

  Future<void> _pickImage() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'เลือกรูปภาพโปรไฟล์',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 16),
              _sheetOption(
                icon: Icons.camera_alt_outlined,
                label: 'ถ่ายรูปใหม่',
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    final img = await _picker.pickImage(
                      source: ImageSource.camera,
                      maxWidth: 1024,
                      maxHeight: 1024,
                      imageQuality: 85,
                    );
                    if (img != null) setState(() => _profileImage = File(img.path));
                  } catch (_) {
                    _snack('ไม่สามารถถ่ายรูปได้', false);
                  }
                },
              ),
              const SizedBox(height: 10),
              _sheetOption(
                icon: Icons.photo_library_outlined,
                label: 'เลือกจากแกลเลอรี่',
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    final img = await _picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 1024,
                      maxHeight: 1024,
                      imageQuality: 85,
                    );
                    if (img != null) setState(() => _profileImage = File(img.path));
                  } catch (_) {
                    _snack('ไม่สามารถเลือกรูปภาพได้', false);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: lightBlue,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: primaryBlue, size: 20),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: darkText,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (_controllers['password']!.text != _controllers['confirmPassword']!.text) {
      _snack('รหัสผ่านไม่ตรงกัน', false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final session = Session();

      

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$url/laundry_staff/register'),
      );

      request.fields.addAll({
        'email': _controllers['email']!.text.trim(),
        'username': _controllers['username']!.text.trim(),
        'password': _controllers['password']!.text,
        'fullname': _controllers['fullName']!.text.trim(),
        'phone': _controllers['phone']!.text.trim(),
      });

      if (_profileImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('profile_image', _profileImage!.path),
        );
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final staffResponse = LaundryStaffResponse.fromJson(json.decode(response.body));

      if (response.statusCode == 200 && staffResponse.ok) {
        if (!mounted) return;
        _showSuccessDialog();
      } else {
        _snack(staffResponse.message ?? 'เกิดข้อผิดพลาด', false);
      }
    } catch (_) {
      _snack('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้', false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String message, bool ok) {
    Get.snackbar(
      ok ? 'สำเร็จ' : 'ผิดพลาด',
      message,
      backgroundColor: ok ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
      colorText: ok ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
      icon: Icon(
        ok ? Icons.check_circle_outline : Icons.error_outline,
        color: ok ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
      ),
      margin: const EdgeInsets.all(10),
      borderRadius: 10,
    );
  }

  void _showSuccessDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_laundry_service,
                  color: Color(0xFF4CAF50),
                  size: 36,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'เพิ่มพนักงานสำเร็จ!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: primaryBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'บัญชีพนักงานซักอบพร้อมใช้งานแล้ว',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: Colors.black.withOpacity(0.55),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Get.back();
                    Get.off(() => const LoginScreen());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'เสร็จสิ้น',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // ── Background ──
          Positioned.fill(
            child: Image.asset('assets/images/bg.png', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.05)),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                child: Column(
                  children: [
                    // ── Logo ──
                    Transform.translate(
                      offset: Offset(0, -h * 0.02),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',

                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    // ── Main Card ──
                    Container(
                      width: 360,
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                            color: Colors.black.withOpacity(0.11),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Header ──
                            Center(
                              child: Column(
                                children: [
                                  const Text(
                                    'Register',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: primaryBlue,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'กรอกข้อมูลเพื่อสร้างบัญชีพนักงาน',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      color: Colors.black.withOpacity(0.45),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),
                            _sectionLabel('ข้อมูลบัญชี'),
                            const SizedBox(height: 10),

                            _field(
                              controller: _controllers['username']!,
                              hint: 'Username',
                              icon: Icons.person_outline,
                              validator: (v) {
                                final s = (v ?? '').trim();
                                if (s.isEmpty) return 'กรุณากรอก username';
                                if (s.length < 3) return 'อย่างน้อย 3 ตัวอักษร';
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),
                            _field(
                              controller: _controllers['password']!,
                              hint: 'Password',
                              icon: Icons.lock_outline,
                              obscure: _obscurePassword,
                              onToggleObscure: () =>
                                  setState(() => _obscurePassword = !_obscurePassword),
                              validator: (v) {
                                final s = (v ?? '').trim();
                                if (s.isEmpty) return 'กรุณากรอกรหัสผ่าน';
                                if (s.length < 6) return 'อย่างน้อย 6 ตัวอักษร';
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),
                            _field(
                              controller: _controllers['confirmPassword']!,
                              hint: 'Confirm Password',
                              icon: Icons.check_circle_outline,
                              obscure: _obscureConfirmPassword,
                              onToggleObscure: () => setState(
                                () => _obscureConfirmPassword = !_obscureConfirmPassword,
                              ),
                              validator: (v) =>
                                  v != _controllers['password']!.text
                                      ? 'รหัสผ่านไม่ตรงกัน'
                                      : null,
                            ),

                            const SizedBox(height: 18),
                            _divider(),
                            const SizedBox(height: 14),
                            _sectionLabel('ข้อมูลส่วนตัว'),
                            const SizedBox(height: 10),

                            _field(
                              controller: _controllers['fullName']!,
                              hint: 'ชื่อ-นามสกุล',
                              icon: Icons.badge_outlined,
                              validator: (v) =>
                                  (v ?? '').trim().isEmpty ? 'กรุณากรอกชื่อ-นามสกุล' : null,
                            ),
                            const SizedBox(height: 10),
                            _field(
                              controller: _controllers['email']!,
                              hint: 'Email',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                final s = (v ?? '').trim();
                                if (s.isEmpty) return 'กรุณากรอกอีเมล';
                                if (!GetUtils.isEmail(s)) return 'รูปแบบอีเมลไม่ถูกต้อง';
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),
                            _field(
                              controller: _controllers['phone']!,
                              hint: 'เบอร์โทรศัพท์',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              validator: (v) {
                                final s = (v ?? '').trim();
                                if (s.isEmpty) return 'กรุณากรอกเบอร์โทร';
                                if (s.length < 9) return 'เบอร์โทรศัพท์ไม่ถูกต้อง';
                                return null;
                              },
                            ),

                            const SizedBox(height: 18),
                            _divider(),
                            const SizedBox(height: 14),
                            _sectionLabel('รูปถ่ายพนักงาน'),
                            const SizedBox(height: 10),

                            _imagePicker(),

                            const SizedBox(height: 22),
                            _submitButton(),
                            const SizedBox(height: 14),

                            // ── Back ──
                            Center(
                              child: InkWell(
                                onTap: () => Navigator.pop(context),
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.arrow_back_ios_new,
                                        size: 13,
                                        color: Colors.black.withOpacity(0.40),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'ย้อนกลับ',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: Colors.black.withOpacity(0.40),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──

  Widget _sectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: primaryBlue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: darkText,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: Colors.black.withOpacity(0.06),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDeco({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: primaryBlue, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white.withOpacity(0.90),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.06)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0593FF), width: 1.2),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool? obscure,
    VoidCallback? onToggleObscure,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure ?? false,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
        color: darkText,
      ),
      decoration: _inputDeco(
        hint: hint,
        icon: icon,
        suffix: onToggleObscure != null
            ? IconButton(
                onPressed: onToggleObscure,
                icon: Icon(
                  (obscure ?? false) ? Icons.visibility_off : Icons.visibility,
                  color: primaryBlue.withOpacity(0.6),
                  size: 20,
                ),
              )
            : null,
      ),
    );
  }

  Widget _imagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 120,
          
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14.5),
            child: _profileImage != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(_profileImage!, fit: BoxFit.cover),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.50),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.edit, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: primaryBlue.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.add_a_photo_outlined,
                          color: primaryBlue,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'เพิ่มรูปถ่ายพนักงาน',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.black.withOpacity(0.55),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'แตะเพื่อเลือกรูปภาพ',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.black.withOpacity(0.35),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primaryBlue.withOpacity(0.55),
          elevation: 6,
          shadowColor: primaryBlue.withOpacity(0.40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : const Text(
                'สร้างบัญชีพนักงาน',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }
}