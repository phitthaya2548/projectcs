import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/utils.dart';
import 'package:wash_and_dry/screens/customer/customer_address_screen.dart';
import 'package:wash_and_dry/screens/login_screen.dart';
import 'package:wash_and_dry/service/customer_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wash_and_dry/service/session_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _displayName = '';
  final int _walletBaht = 0;
  String? _profileImage; 
  bool linkingGoogle = false;
  String? _customerId;
@override
void initState() {
  super.initState();
  _loadSession();
}
  Future<void> _doLogout(BuildContext context) async {
    try {
      await CustomerService().logout();

      if (!context.mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ออกจากระบบไม่สำเร็จ: $e')),
      );
    }
  }
Future<void> _loadSession() async {
  final session = SessionStore();
  final name = await session.getFullname();
  final imageUrl = await session.getProfileImage();

  final customerId = await session.getCustomerId();
  _customerId = customerId;
  log('Customer ID: $_customerId');
  if (!mounted) return;

  setState(() {
    _displayName = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : 'ยังไม่ได้ตั้งชื่อ';
    
    _profileImage = (imageUrl != null && imageUrl.trim().isNotEmpty)
        ? imageUrl.trim()
        : null;
    
    log('Display Name: $_displayName');
    log('Profile Image: $_profileImage');
  });
}
Future<void> _linkGoogle(BuildContext context) async {
  if (linkingGoogle) return;
  setState(() => linkingGoogle = true);

  final g = GoogleSignIn();

  try {
    // ✅ บังคับให้เลือกบัญชีทุกครั้ง (สำคัญ)
    // ถ้าอยากให้เลือกเฉพาะตอน error ค่อยย้ายไปไว้ใน catch ก็ได้
    await g.signOut();

    final googleUser = await g.signIn();
    if (googleUser == null) return;

    final googleAuth = await googleUser.authentication;

    // ✅ Sign-in เข้า FirebaseAuth ด้วย Google credential
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: googleAuth.accessToken,
    );

    await FirebaseAuth.instance.signInWithCredential(credential);

    final firebaseIdToken = await FirebaseAuth.instance.currentUser?.getIdToken(true);
    if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
      throw Exception("ไม่พบ Firebase ID Token");
    }

   final result = await CustomerService().linkGoogle(idToken: firebaseIdToken);
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text(result.toString())),
);
  } catch (e) {
    // ✅ ถ้าล้มเหลว ให้ล้าง session เพื่อให้กดใหม่แล้วเลือกบัญชีใหม่ได้
    try {
      await FirebaseAuth.instance.signOut();
      await g.disconnect(); // แรงกว่า signOut (ตัดสิทธิ์เดิม)
    } catch (_) {}

    if (!mounted) return;

    // ✅ ทำปุ่ม “ลองใหม่ / เปลี่ยนบัญชี”
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('เชื่อม Google ไม่สำเร็จ (อีเมลนี้มีบัญชีอยู่แล้ว)'),
        action: SnackBarAction(
          label: 'เปลี่ยนบัญชี',
          onPressed: () => _linkGoogle(context), // กดแล้วเรียกใหม่
        ),
      ),
    );
  } finally {
    if (mounted) setState(() => linkingGoogle = false);
  }
}

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF0593FF);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      body: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 250,
                width: double.infinity,
                color: primary,
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: SizedBox(
                    height: 46,
                    child: Row(
                      children: [
                        _CircleIconButton(
                          icon: Icons.menu,
                          onTap: () {},
                        ),
                        const Expanded(
                          child: Center(
                            child: Text(
                              'โปรไฟล์',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        _CircleIconButton(
                          icon: Icons.notifications_none_rounded,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 150,
                top: 176,
                right: 16,
                child: Text(
                  _displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
             Positioned(
  left: 20,
  top: 160,
  child: Container(
    width: 112,
    height: 112,
    decoration: BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          blurRadius: 18,
          offset: const Offset(0, 10),
          color: Colors.black.withOpacity(0.12),
        ),
      ],
    ),
    child: ClipOval(
      child: _profileImage != null && _profileImage!.isNotEmpty
          ? Image.network(
              _profileImage!,
              width: 112,
              height: 112,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Image.asset(
                    'assets/icons/profile_null.png',
                    width: 65,
                    height: 65,
                    fit: BoxFit.contain,
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                // แสดง loading ตอนกำลังโหลดรูป
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    strokeWidth: 2,
                  ),
                );
              },
            )
          : Center(
              child: Image.asset(
                'assets/icons/profile_null.png',
                width: 65,
                height: 65,
                fit: BoxFit.contain,
              ),
            ),
    ),
  ),
),
            ],
          ),

          const SizedBox(height: 40),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  _MenuCard(
                    title: 'ข้อมูลส่วนตัว',
                    leading: Image.asset(
                      'assets/icons/profile1.png',
                      width: 28,
                      height: 28,
                      fit: BoxFit.contain,
                    ),
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  _MenuCard(
                    title: 'กระเป๋าเงิน',
                    leading: Image.asset(
                      'assets/icons/wallet1.png',
                      width: 28,
                      height: 28,
                      fit: BoxFit.contain,
                    ),
                    trailingText: '$_walletBaht บาท',
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  _MenuCard(
                    title: 'ที่อยู่',
                    leading: Image.asset(
                      'assets/icons/map.png',
                      width: 28,
                      height: 28,
                      fit: BoxFit.contain,
                    ),
                    onTap: () {
  if (_customerId == null) return;

  Get.to(() => CustomerAddressScreen(
        customerId: _customerId!,
      ));
},
                  ),
                  const SizedBox(height: 12),

                  _MenuCard(
  title: linkingGoogle
      ? 'กำลังเชื่อม Google...'
      : (_profileImage == null
          ? 'เชื่อมบัญชี Google'
          : 'บัญชี Google เชื่อมแล้ว'),
  leading: linkingGoogle
      ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : (_profileImage == null
          ? const Icon(Icons.g_mobiledata_rounded, color: primary, size: 28)
          : CircleAvatar(
  radius: 20,
  backgroundImage:
      _profileImage != null ? NetworkImage(_profileImage!) : null,
  child: _profileImage == null
      ? const Icon(Icons.person, color: Colors.white)
      : null,
)),
  onTap: linkingGoogle || _profileImage != null
      ? null
      : () => _linkGoogle(context),
  trailingText: _profileImage != null ? 'เชื่อมแล้ว' : null,
  trailingTextColor: Colors.green,
),


                  const SizedBox(height: 14),

                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _doLogout(context),
                    child: Container(
                      height: 64,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3B3B),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 16,
                            offset: const Offset(0, 10),
                            color: Colors.black.withOpacity(0.12),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          Image.asset(
                            'assets/icons/logout.png',
                            width: 28,
                            height: 28,
                            fit: BoxFit.contain,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'ออกจากระบบ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.title,
    this.onTap,
    this.trailingText,
    this.trailingTextColor,
    this.leading,
  });

  final String title;
  final VoidCallback? onTap;
  final String? trailingText;
  final Color? trailingTextColor;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF0593FF);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              blurRadius: 14,
              offset: const Offset(0, 8),
              color: Colors.black.withOpacity(0.08),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: leading is CircleAvatar
                  ? ClipOval(
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: leading,
                      ),
                    )
                  : Center(
                      child: leading ??
                          const Icon(Icons.circle_outlined, color: primary),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (trailingText != null) ...[
              Text(
                trailingText!,
                style: TextStyle(
                  color: trailingTextColor ?? Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 10),
            ],
            const Icon(Icons.chevron_right_rounded, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.20),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
