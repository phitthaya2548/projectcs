import 'dart:convert';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';

import 'package:wash_and_dry/config/config.dart';
import 'package:wash_and_dry/models/req/customer/req_login_google.dart';
import 'package:wash_and_dry/models/req/req_login.dart';
import 'package:wash_and_dry/screens/customer/customer_onboarding_screen.dart';
import 'package:wash_and_dry/screens/reset_password_screen.dart';
import 'package:wash_and_dry/screens/role_select_screen.dart';
import 'package:wash_and_dry/screens/store/store_onboarding_screen.dart';
import 'package:wash_and_dry/service/session_service.dart';
import 'package:wash_and_dry/widgets/main_shell_customer.dart';
import 'package:wash_and_dry/widgets/main_shell_store.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;
  bool _obscure = true;
  String? _error;
  String url = '';

  @override
  void initState() {
    super.initState();
    loadConfig();
  }
  void loadConfig() async {
  try {
    final config = await Configuration.getConfig();
    setState(() => url = config['apiEndpoint']?.toString() ?? '');
  } catch (_) {
    setState(() => url = '');
  }
}

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final resp = await http.post(
        Uri.parse('$url/login'),
        headers: {'Content-Type': 'application/json'},
        body: loginToJson(
          Login(
            username: _username.text.trim(),
            password: _password.text.trim(),
          ),
        ),
      );

      final data = jsonDecode(resp.body);

      if (resp.statusCode != 200 || data['ok'] != true) {
        throw Exception(data['message'] ?? 'เข้าสู่ระบบไม่สำเร็จ');
      }

      final role = data['role'] ?? '';
      final customerId = data['customer_id']?.toString();
      final storeId = data['store_id']?.toString();
      final fullname = data['fullname']?.toString();
      final storeName = data['store_name']?.toString();
      final email = data['email']?.toString();
      final phone = data['phone']?.toString();
      final profileImage = data['profile_image']?.toString();
      final profileComplete = data['profile_complete'] == true;
      final addressComplete = data['address_complete'] == true;
      final missingFields =
          (data['missing_fields'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      await Session().clear();
      await Session().saveLogin(
        role: role,
        storeId: role == 'store' ? storeId : null,
        customerId: role == 'customer' ? customerId : null,
        fullname: fullname,
        profileImage: profileImage,
        phone: phone,
      );

      if (!mounted) return;

      final displayName = role == 'store' ? storeName : fullname;
      _showSuccess('ยินดีต้อนรับ $displayName');

      if (role == 'customer') {
        _handleCustomerLogin(
          customerId: customerId,
          profileComplete: profileComplete,
          addressComplete: addressComplete,
          missingFields: missingFields,
          fullname: fullname,
          email: email,
          phone: phone,
          profileImage: profileImage,
        );
      } else if (role == 'store') {
        _handleStoreLogin(storeId: storeId, profileComplete: profileComplete);
      } else {
        throw Exception('ผู้ใช้ไม่ถูกต้อง');
      }
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw Exception('ยกเลิกการเข้าสู่ระบบ');
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final user = userCred.user;
      if (user == null) throw Exception('เข้าสู่ระบบไม่สำเร็จ');

      final displayName = googleUser.displayName ?? '';
      final email = googleUser.email;
      final photoUrl = googleUser.photoUrl ?? '';

      final idToken = await user.getIdToken(true);

      final resp = await http.post(
        Uri.parse('$url/google'),
        headers: {'Content-Type': 'application/json'},
        body: loginGoogleToJson(LoginGoogle(googleId: idToken.toString())),
      );

      final data = jsonDecode(resp.body);

      if (resp.statusCode != 200 || data['ok'] != true) {
        throw Exception(data['message'] ?? 'Google login ไม่สำเร็จ');
      }

      if (data['emailAlreadyExistsButNotGoogle'] == true) {
        if (!mounted) return;
        Get.snackbar(
          'ไม่สามารถใช้งานได้',
          'อีเมลนี้มีบัญชีอยู่แล้ว แต่ไม่ได้สมัครด้วย Google',
          backgroundColor: const Color(0xFFFFEBEE),
          colorText: const Color(0xFFC62828),
          icon: const Icon(Icons.warning, color: Color(0xFFC62828)),
          margin: const EdgeInsets.all(10),
          borderRadius: 8,
        );
        return;
      }

      final role = data['role'] ?? 'customer';
      final customerId = data['customer_id']?.toString();
      final profileComplete = data['profile_complete'] == true;
      final addressComplete = data['address_complete'] == true;
      final missingFields =
          (data['missing_fields'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      final fullname = data['fullname']?.toString() ?? displayName;

      await Session().clear();
      await Session().saveLogin(
        role: role,
        customerId: role == 'customer' ? customerId : null,
        fullname: fullname,
        profileImage: photoUrl,
        phone: '',
      );

      if (!mounted) return;

      _showSuccess('ยินดีต้อนรับ $fullname');

      if (role == 'customer') {
        if (customerId == null || customerId.isEmpty) {
          throw Exception('ไม่พบข้อมูลลูกค้า');
        }

        if (!profileComplete || !addressComplete) {
          Get.offAll(
            () => CustomerOnboardingScreen(
              customerId: customerId,
              missingFields: missingFields,
              needProfile: !profileComplete,
              needAddress: !addressComplete,
              initialFullname: displayName,
              initialEmail: email,
              initialPhotoUrl: photoUrl,
            ),
          );
          return;
        }

        Get.offAll(() => MainShellCustomer());
      } else if (role == 'store') {
        return;
      } else {
        throw Exception('ประเภทผู้ใช้ไม่ถูกต้อง');
      }
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _handleCustomerLogin({
    required String? customerId,
    required bool profileComplete,
    required bool addressComplete,
    required List<String> missingFields,
    String? fullname,
    String? email,
    String? phone,
    String? profileImage,
  }) {
    if (customerId == null || customerId.isEmpty) {
      throw Exception('ไม่พบข้อมูลลูกค้า');
    }

    if (!profileComplete) {
      Get.off(
        () => CustomerOnboardingScreen(
          customerId: customerId,
          missingFields: missingFields,
          needProfile: !profileComplete,
          needAddress: !addressComplete,
          initialFullname: fullname,
          initialEmail: email,
          initialPhotoUrl: profileImage,
          initialPhone: phone,
        ),
      );
      return;
    }

    Get.off(() => MainShellCustomer());
  }

  void _handleStoreLogin({
    required String? storeId,
    required bool profileComplete,
  }) {
    if (storeId == null || storeId.isEmpty) {
      throw Exception('ไม่พบข้อมูลร้านค้า');
    }

    if (!profileComplete) {
      Get.to(() => StoreOnboardingScreen(storeId: storeId));
      return;
    }

    Get.off(() => MainShellStore());
  }

  void _showSuccess(String message) {
    Get.snackbar(
      'สำเร็จ',
      message,
      backgroundColor: const Color(0xFFE8F5E9),
      colorText: const Color(0xFF2E7D32),
      icon: const Icon(Icons.check_circle, color: Color(0xFF4CAF50)),
      margin: const EdgeInsets.all(10),
      borderRadius: 8,
      duration: const Duration(seconds: 2),
    );
  }

  void _showError(String message) {
    Get.snackbar(
      'เข้าสู่ระบบไม่สำเร็จ',
      message,
      backgroundColor: const Color(0xFFFFEBEE),
      colorText: const Color(0xFFC62828),
      icon: const Icon(Icons.error_outline, color: Color(0xFFC62828)),
      margin: const EdgeInsets.all(10),
      borderRadius: 8,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 18,
                ),
                child: Column(
                  children: [
                    ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildLoginForm(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Container(
      width: 340,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
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
              'Login\nWash and Dry\nDelivery',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0593FF),
                height: 1.15,
              ),
            ),
            const SizedBox(height: 15),
            _buildUsernameField(),
            const SizedBox(height: 10),
            _buildPasswordField(),
            const SizedBox(height: 10),
            if (_error != null) _buildErrorText(),
            _buildLoginButton(),
            const SizedBox(height: 10),
            _buildForgotPasswordButton(),
            const SizedBox(height: 6),
            _buildGoogleSignInButton(),
            const SizedBox(height: 8),
            _buildSignUpButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      controller: _username,
      decoration: InputDecoration(
        hintText: 'Username',
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: Image.asset(
            'assets/icons/person.png',
            width: 22,
            height: 22,
            fit: BoxFit.contain,
          ),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.85),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.black.withOpacity(0.12),
            width: 1.2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.2),
        ),
      ),
      validator: (v) {
        final s = (v ?? '').trim();
        if (s.isEmpty) return 'กรอก username';
        if (s.length < 4) return 'username อย่างน้อย 4 ตัวอักษร';
        if (s.contains(' ')) return 'username ห้ามมีช่องว่าง';
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _password,
      obscureText: _obscure,
      decoration: InputDecoration(
        hintText: 'Password',
        prefixIcon: const Icon(Icons.lock_outlined),
        prefixIconColor: const Color(0xFF0593FF),
        suffixIcon: IconButton(
          onPressed: () => setState(() => _obscure = !_obscure),
          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
        ),
        suffixIconColor: const Color(0xFF0593FF),
        filled: true,
        fillColor: Colors.white.withOpacity(0.85),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.black.withOpacity(0.12),
            width: 1.2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.2),
        ),
      ),
      validator: (v) {
        final s = (v ?? '').trim();
        if (s.isEmpty) return 'กรอก password';
        if (s.length < 6) return 'password อย่างน้อย 6 ตัวอักษร';
        return null;
      },
    );
  }

  Widget _buildErrorText() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        _error!,
        style: const TextStyle(color: Colors.red, fontSize: 13),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _loading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0B84F3),
          foregroundColor: Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          _loading ? 'กำลังเข้าสู่ระบบ...' : 'Login',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildForgotPasswordButton() {
    return TextButton(
      onPressed: () => Get.to(() => const ResetWithPhoneOtpScreen()),
      child: const Text(
        'Forgot password?',
        style: TextStyle(color: Color(0xFF1279E6)),
      ),
    );
  }

  Widget _buildGoogleSignInButton() {
    return InkWell(
      onTap: _loading ? null : _loginGoogle,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 66,
        height: 66,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE5E7EB)),
          color: Colors.white,
        ),
        child: Center(
          child: Image.asset(
            'assets/icons/google.png',
            width: 56,
            height: 56,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpButton() {
    return TextButton(
      onPressed: () => Get.to(() => const RoleSelectScreen()),
      child: const Text(
        'Sign Up',
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1279E6),
        ),
      ),
    );
  }
}
