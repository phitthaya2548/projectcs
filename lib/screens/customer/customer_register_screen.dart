import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:wash_and_dry/config/config.dart';
import 'package:wash_and_dry/models/req/customer/req_register_customer.dart';
import 'package:wash_and_dry/screens/login_screen.dart';
import 'package:wash_and_dry/service/customer_service.dart';
import 'package:http/http.dart' as http;
class CustomerRegisterScreen extends StatefulWidget {
  const CustomerRegisterScreen({super.key});

  @override
  State<CustomerRegisterScreen> createState() => _CustomerRegisterScreenState();
}

class _CustomerRegisterScreenState extends State<CustomerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _loading = false;
  String? _error;

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool loading = false;
  bool _configLoaded = false;
  String? error;
  String? url;

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
     _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await Configuration.getConfig();
    url = config['apiEndpoint'];

  }
  
  Future<void> _register() async {
  FocusScope.of(context).unfocus();
  if (!_formKey.currentState!.validate()) return;

  setState(() {
    _loading = true;
    _error = null;
  });

  try {
    final req = CreateCustomer(
      username: _username.text.trim(),
      password: _password.text.trim(),
    );

    final resp = await http.post(
      Uri.parse('$url/register/customer/signup'),
      headers: {'Content-Type': 'application/json'},
      body: createCustomerToJson(req),
    );

    final data = jsonDecode(resp.body);
    
    if (resp.statusCode != 200 || data['ok'] != true) {
      throw Exception(data['message'] ?? 'สมัครไม่สำเร็จ');
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
                child: const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 50),
              ),
              const SizedBox(height: 20),
              const Text(
                'สำเร็จแล้ว!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0593FF)),
              ),
              const SizedBox(height: 10),
              const Text(
                'ยินดีต้อนรับ\nเข้าสู่ระบบได้เลย',
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
    required Widget prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.withOpacity(0.8)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.withOpacity(0.9), width: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const titleBlue = Color(0xFF0593FF);
    const btnBlue = Color(0xFF0B84F3);
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg.png',
              fit: BoxFit.cover,
            ),
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

                    // การ์ดสมัคร
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
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                color: titleBlue,
                              ),
                            ),
                            
 const SizedBox(height: 6),
                            Text(
                              'สมัครบัญชีลูกค้า',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.black.withOpacity(0.55),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _username,
                              decoration: _fieldDecoration(
                                hint: 'Username',
                                prefixIcon: Padding(
    padding: const EdgeInsets.all(12),
    child: Image.asset(
      'assets/icons/person.png',
      width: 22,
      height: 22,
      fit: BoxFit.contain,
    ),
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

                            TextFormField(
                              controller: _password,
                              obscureText: _obscurePass,
                              decoration: _fieldDecoration(
                                hint: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline, color: titleBlue),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                                  icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility),
                                  color: titleBlue,
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

                            TextFormField(
                              controller: _confirmPassword,
                              obscureText: _obscureConfirm,
                              decoration: _fieldDecoration(
                                hint: 'Confirm Password',
                                prefixIcon: const Icon(Icons.check_circle_outline, color: titleBlue),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                  icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                                  color: titleBlue,
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
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _register,
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
                                      color: titleBlue,
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
}
