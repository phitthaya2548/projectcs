import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:wash_and_dry/config/config.dart';
import 'package:wash_and_dry/models/res/customer/res_profile_customer.dart';
import 'package:wash_and_dry/service/session_service.dart';

class DrawerCustomerContent extends StatefulWidget {
  const DrawerCustomerContent({super.key});

  @override
  State<DrawerCustomerContent> createState() => DrawerCustomerContentState();
}

class DrawerCustomerContentState extends State<DrawerCustomerContent> {
  final Session _session = Session();

  String? _fullname;
  String? _phone;
  String? _profileImage;
  String? _email;
  String? _gender;
  double? _walletBalance;
  bool _isLoading = true;
  String url = '';
  String? _customerId;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  // เรียกจากภายนอกได้ ทุกครั้งที่ต้องการโหลดข้อมูลใหม่
  Future<void> refresh() async {
    setState(() => _isLoading = true);
    await fetchCustomerProfile();
  }

  Future<void> _loadConfig() async {
    final config = await Configuration.getConfig();
    final customerId = await Session().getCustomerId();

    setState(() {
      url = config['apiEndpoint']?.toString() ?? '';
      _customerId = customerId;
    });

    await fetchCustomerProfile();
  }

  Future<void> fetchCustomerProfile() async {

    try {
      final response = await http.get(
        Uri.parse('$url/customer/profile/$_customerId'),
        headers: {'Content-Type': 'application/json'},
      );

      log('GET Profile - Status: ${response.statusCode}');
      log('GET Profile - Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['ok'] == true) {
          final profile = CustomerProfile.fromJson(jsonData['data']);

          if (!mounted) return;
          setState(() {
            _fullname = profile.fullname;
            _email = profile.email;
            _phone = profile.phone;
            _gender = profile.gender;
            _profileImage = profile.profileImage;
            _walletBalance = profile.walletBalance;
            _isLoading = false;
          });
        } else {
          log('API returned ok=false: ${jsonData['message']}');
          if (mounted) setState(() => _isLoading = false);
        }
      } else {
        log('HTTP error: ${response.statusCode}');
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      log('fetchCustomerProfile error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }
 String genderThai(String? gender) {
  if (gender == 'female') {
    return "หญิง";
  } else if (gender == 'male') {
    return "ชาย";
  } else {
    return "อื่นๆ";
  }
}
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        UserAccountsDrawerHeader(
          decoration: const BoxDecoration(color: Colors.blue),
          currentAccountPicture: CircleAvatar(
            backgroundColor: Colors.white,
            backgroundImage: (_profileImage != null && _profileImage!.isNotEmpty)
                ? NetworkImage(_profileImage!)
                : null,
            child: (_profileImage == null || _profileImage!.isEmpty)
                ? const Icon(Icons.person, size: 40, color: Colors.blue)
                : null,
          ),
          accountName: Text(
            _isLoading ? 'กำลังโหลด...' : (_fullname ?? 'ไม่ระบุชื่อ'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          accountEmail: Text(_isLoading ? '' : (_phone ?? 'ไม่ระบุเบอร์โทร')),
        ),

        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('อีเมล'),
            subtitle: Text(_email?.isNotEmpty == true ? _email! : 'ไม่ระบุ'),
          ),
          ListTile(
            leading: const Icon(Icons.wc_outlined),
            title: const Text('เพศ'),
            subtitle: Text(genderThai(_gender)),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('ยอดเงินคงเหลือ'),
            subtitle: Text('${(_walletBalance ?? 0).toStringAsFixed(2)} บาท'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('หน้าแรก'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('ตั้งค่า'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('ออกจากระบบ'),
            onTap: () async {
              await _session.clear();
              if (!mounted) return;
              Navigator.pop(context);
            },
          ),
        ],
      ],
    );
  }
}