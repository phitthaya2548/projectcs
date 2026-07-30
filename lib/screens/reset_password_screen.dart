import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_navigation/src/snackbar/snackbar.dart';
import 'package:http/http.dart' as http;
import 'package:wash_and_dry/config/config.dart';

class ResetPasswordWithEmailOtpScreen extends StatefulWidget {
  const ResetPasswordWithEmailOtpScreen({super.key});

  @override
  State<ResetPasswordWithEmailOtpScreen> createState() =>
      _ResetPasswordWithEmailOtpScreenState();
}

class _ResetPasswordWithEmailOtpScreenState
    extends State<ResetPasswordWithEmailOtpScreen> {
  final _formKey = GlobalKey<FormState>();

  final emailCtl = TextEditingController();
  final otpCtl = TextEditingController();
  final newPassCtl = TextEditingController();

  bool loading = false;
  bool otpSent = false;
  bool obscurePassword = true;

  String url = '';

  static const themeColor = Color(0xFF0593FF);

  @override
  void initState() {
    super.initState();
    loadConfig();
  }

  Future<void> loadConfig() async {
    try {
      final config = await Configuration.getConfig();
      setState(() => url = config['apiEndpoint']?.toString() ?? '');
    } catch (_) {
      setState(() => url = '');
    }
  }



String? emailValidator(String? value) {
  final email = (value ?? '').trim();

  if (email.isEmpty) {
    return 'กรอกอีเมลก่อน';
  }

  final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  if (!emailRegex.hasMatch(email)) {
    return 'รูปแบบอีเมลไม่ถูกต้อง';
  }

  return null;
}
  String? otpValidator(String? value) {
    if (!otpSent) return null;

    final otp = (value ?? '').trim();

    if (otp.isEmpty) {
      return 'กรอก OTP ก่อน';
    }

    if (otp.length < 6) {
      return 'OTP ไม่ครบ';
    }

    return null;
  }

  String? passwordValidator(String? value) {
    if (!otpSent) return null;

    final password = value ?? '';

    if (password.isEmpty) {
      return 'กรอกรหัสผ่านใหม่ก่อน';
    }

    if (password.length < 6) {
      return 'รหัสผ่านต้องอย่างน้อย 6 ตัว';
    }

    return null;
  }

  void resetOtpState() {
    otpSent = false;
    otpCtl.clear();
    newPassCtl.clear();
  }

  Future<void> sendOtp() async {
    FocusScope.of(context).unfocus();

    if (emailValidator(emailCtl.text) != null) {
      _formKey.currentState!.validate();
      return;
    }

    if (url.isEmpty) {
      showMessage('ไม่พบ apiEndpoint');
      return;
    }

    final email = emailCtl.text;

    setState(() {
      loading = true;
      resetOtpState();
    });

    try {
      final response = await http.post(
        Uri.parse('$url/password/forgot_password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        setState(() {
          otpSent = true;
        });

        showMessage(data['message'] ?? 'ส่ง OTP แล้ว กรุณาตรวจอีเมล');
      } else {
        showMessage(data['message'] ?? 'ส่ง OTP ไม่สำเร็จ');
      }
    } catch (e) {
      showMessage('เชื่อมต่อเซิร์ฟเวอร์ไม่สำเร็จ');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> resetPassword() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (url.isEmpty) {
      showMessage('ไม่พบ apiEndpoint');
      return;
    }

    final email = emailCtl.text;
    final otp = otpCtl.text.trim();
    final newPassword = newPassCtl.text;

    setState(() => loading = true);

    try {
      final response = await http.post(
        Uri.parse('$url/password/reset_password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (!mounted) return;

        await Get.dialog(
  Dialog(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 40,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'สำเร็จ',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            data['message'] ?? 'รีเซ็ตรหัสผ่านสำเร็จ',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'ตกลง',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);

        if (!mounted) return;
        Navigator.pop(context);
      } else {
        showMessage(data['message'] ?? 'รีเซ็ตรหัสผ่านไม่สำเร็จ');
      }
    } catch (e) {
      showMessage('เชื่อมต่อเซิร์ฟเวอร์ไม่สำเร็จ');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

void showMessage(String message) {
  Get.closeAllSnackbars();

  Get.snackbar(
    'แจ้งเตือน',
    message,
    snackPosition: SnackPosition.TOP,
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    borderRadius: 16,
    backgroundColor: Colors.white.withOpacity(0.90),
    colorText: Colors.black87,
    duration: const Duration(seconds: 2),
    icon: Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.06),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.info_outline_rounded,
        color: Colors.black87,
        size: 18,
      ),
    ),
    shouldIconPulse: false,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    boxShadows: [
      BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

  InputDecoration inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: themeColor),
      prefixIconColor: themeColor,
      
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: themeColor, width: 1.4),
      ),
    );
  }

  Widget sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget stepRow({
    required int step,
    required String text,
    required bool active,
  }) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: active ? themeColor : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(99),
          ),
          alignment: Alignment.center,
          child: Text(
            '$step',
            style: TextStyle(
              color: active ? Colors.white : Colors.grey.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: active ? Colors.black87 : Colors.grey.shade600,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    emailCtl.dispose();
    otpCtl.dispose();
    newPassCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSendOtp = !loading;
    final canResetPassword = otpSent && !loading;

    return Scaffold(
       backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF7FAFC),
        foregroundColor: Colors.white,
        title: const Text(
          'รีเซ็ตรหัสผ่าน',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white
          ),
        ),
         flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0593FF), Color(0xFF0476D9)],
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        iconTheme: IconThemeData(color:Colors.white),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              sectionTitle(
                'ลืมรหัสผ่านใช่ไหม',
                'กรอกอีเมลของคุณเพื่อรับรหัส OTP และตั้งรหัสผ่านใหม่',
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    stepRow(
                      step: 1,
                      text: 'กรอกอีเมลเพื่อรับ OTP',
                      active: true,
                    ),
                    const SizedBox(height: 12),
                    stepRow(
                      step: 2,
                      text: 'กรอกรหัส OTP ที่ส่งไปยังอีเมล',
                      active: otpSent,
                    ),
                    const SizedBox(height: 12),
                    stepRow(
                      step: 3,
                      text: 'ตั้งรหัสผ่านใหม่',
                      active: otpSent,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: emailCtl,
                      keyboardType: TextInputType.emailAddress,
                      validator: emailValidator,
                      onChanged: (_) {
                        if (otpSent) {
                          setState(() {
                            resetOtpState();
                          });
                        }
                      },
                      decoration: inputDecoration(
                        label: 'อีเมล',
                        hint: 'example@gmail.com',
                        icon: Icons.mail_outline_rounded,
                      ),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: canSendOtp ? sendOtp : null,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: themeColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: themeColor.withOpacity(0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          loading ? 'กำลังส่ง OTP...' : 'ส่ง OTP',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    if (otpSent) ...[
                      const SizedBox(height: 20),
                      Divider(color: Colors.grey.shade200),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: otpCtl,
                        keyboardType: TextInputType.number,
                        validator: otpValidator,
                        decoration: inputDecoration(
                          label: 'OTP',
                          hint: 'กรอกรหัส 6 หลัก',
                          icon: Icons.verified_outlined,
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: newPassCtl,
                        obscureText: obscurePassword,
                        validator: passwordValidator,
                        decoration: inputDecoration(
                          label: 'รหัสผ่านใหม่',
                          hint: 'อย่างน้อย 6 ตัวอักษร',
                          icon: Icons.lock_outline_rounded,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: canResetPassword ? resetPassword : null,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Colors.black87,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.black38,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            loading
                                ? 'กำลังเปลี่ยนรหัสผ่าน...'
                                : 'เปลี่ยนรหัสผ่าน',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}