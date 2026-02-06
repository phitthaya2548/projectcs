import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wash_and_dry/config/config.dart';
import 'package:wash_and_dry/models/req/store/req_register_store.dart';
import 'package:http/http.dart' as http;

import '../login_screen.dart';

class StoreRegisterScreen extends StatefulWidget {
  const StoreRegisterScreen({super.key});

  @override
  State<StoreRegisterScreen> createState() => _StoreRegisterScreenState();
}

class _StoreRegisterScreenState extends State<StoreRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _loading = false;
  String? _error;

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String url ='';
  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }
@override
  void initState() {
    super.initState();
    Configuration.getConfig().then(
      (config) {
        url = config['apiEndpoint'];
      },
    );
  }
 Future<void> _registerStore() async {
  FocusScope.of(context).unfocus();
  if (!_formKey.currentState!.validate()) return;

  setState(() {
    _loading = true;
    _error = null;
  });

  try {
    final req = RegisterStore(
      username: _username.text.trim(),
      password: _password.text.trim(),
    );

    final resp = await http.post(
      Uri.parse('$url/register/store/signup'),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: registerStoreToJson(req),
    );

    final data = jsonDecode(resp.body);

    if (resp.statusCode != 200 || data['ok'] != true) {
      throw Exception(data['message'] ?? 'สมัครร้านค้าไม่สำเร็จ');
    }

    if (!mounted) return;

    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.store, color: Color(0xFF4CAF50), size: 50),
              ),
              const SizedBox(height: 20),
              const Text(
                'ลงทะเบียนสำเร็จ!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0593FF)),
              ),
              const SizedBox(height: 10),
              const Text(
                'ร้านค้าของคุณพร้อมใช้งาน\nเข้าสู่ระบบเพื่อเริ่มต้น',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Get.back();
                    Get.off(() => const LoginScreen());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0593FF),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('เข้าสู่ระบบ', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );

  } catch (e) {
    Get.snackbar(
      'ผิดพลาด',
      e.toString().replaceFirst('Exception: ', ''),
      backgroundColor: const Color(0xFFFFEBEE),
      colorText: const Color(0xFFC62828),
      icon: const Icon(Icons.error_outline, color: Color(0xFFC62828)),
      margin: const EdgeInsets.all(10),
      borderRadius: 8,
    );
    setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}

  InputDecoration _fieldDecoration({
    required String hint,
    required Widget prefix,
    Widget? suffixIcon,
  }) {
    const primaryBlue = Color(0xFF0593FF);

    return InputDecoration(
      hintText: hint,
      prefixIcon: prefix,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withOpacity(0.90),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),

      // ขอบใสๆ
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.06)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF0593FF);
    const btnBlue = Color(0xFF0B84F3);
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
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
                    Transform.translate(
                      offset: Offset(0, -h * 0.03),
                      child: ClipOval(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          child: Image.asset(
                            'assets/images/logo.png',

                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    Container(
                      width: 340,
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                            color: Colors.black.withOpacity(0.12),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            const Text(
                              'Register',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: primaryBlue,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'สมัครบัญชีร้านค้า',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.black.withOpacity(0.55),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Username
                            TextFormField(
                              controller: _username,
                              decoration: _fieldDecoration(
                                hint: 'Username',
                                prefix: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Icon(Icons.store_outlined, color: primaryBlue),
                                ),
                              ),
                              validator: (v) {
                                final s = (v ?? '').trim();
                                if (s.isEmpty) return 'กรอก username';
                                if (s.length < 4) return 'username อย่างน้อย 4 ตัวอักษร';
                                if (s.contains(' ')) return 'username ห้ามมีช่องว่าง';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // Password
                            TextFormField(
                              controller: _password,
                              obscureText: _obscurePass,
                              decoration: _fieldDecoration(
                                hint: 'Password',
                                prefix: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Icon(Icons.lock_outline, color: primaryBlue),
                                ),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                                  icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility),
                                  color: primaryBlue,
                                ),
                              ),
                              validator: (v) {
                                final s = (v ?? '').trim();
                                if (s.isEmpty) return 'กรอก password';
                                if (s.length < 6) return 'password อย่างน้อย 6 ตัวอักษร';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // Confirm Password
                            TextFormField(
                              controller: _confirmPassword,
                              obscureText: _obscureConfirm,
                              decoration: _fieldDecoration(
                                hint: 'Confirm Password',
                                prefix: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Icon(Icons.check_circle_outline, color: primaryBlue),
                                ),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                  icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                                  color: primaryBlue,
                                ),
                              ),
                              validator: (v) {
                                final s = (v ?? '').trim();
                                if (s.isEmpty) return 'กรอกยืนยันรหัสผ่าน';
                                if (s != _password.text.trim()) return 'รหัสผ่านไม่ตรงกัน';
                                return null;
                              },
                            ),

                            const SizedBox(height: 10),

                            if (_error != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  _error!,
                                  style: const TextStyle(color: Colors.red, fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                            const SizedBox(height: 6),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _registerStore,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: btnBlue,
                                  foregroundColor: Colors.white,
                                  elevation: 8,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  _loading ? 'กำลังสมัคร...' : 'Register',
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                                ),
                              ),
                            ),

                           const SizedBox(height: 10),
                            Text(
                              'or',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black.withOpacity(0.45),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),

                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Already have an account? ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black.withOpacity(0.45),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 5,),
                                InkWell(
                                  onTap: () => Navigator.pop(context),
                                  child: const Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: 22,
                                      color: Color(0xFF0593FF),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            InkWell(
  onTap: () => Navigator.pop(context),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      
      const SizedBox(width: 4),
      Text(
        'back',
        style: TextStyle(
          fontSize: 16,
          color: Colors.black.withOpacity(0.45),
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  ),
),

                    const SizedBox(height: 18),
                          ]
                        ),
                      ),
                    ),
                
                  ],
                ),
              ),
            ),
          ),
              
        ],
      ),
    );
  }
}
