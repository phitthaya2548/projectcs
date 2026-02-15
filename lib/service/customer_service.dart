import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:wash_and_dry/config/config.dart';
import 'package:wash_and_dry/service/session_service.dart';

class CustomerService {
  String? _baseUrl;

  Future<String> _getBaseUrl() async {
    if (_baseUrl != null && _baseUrl!.isNotEmpty) return _baseUrl!;
    final config = await Configuration.getConfig();
    final u = (config['apiEndpoint'] ?? '').toString().trim();
    if (u.isEmpty) throw Exception('ไม่พบ apiEndpoint ใน config');
    _baseUrl = u;
    return u;
  }

  Future<String> getCustomerId() async {
    final id = await Session().getCustomerId();
    if (id == null || id.isEmpty) {
      throw Exception("ไม่พบ customerId (ยังไม่ได้ล็อกอิน)");
    }
    return id;
  }

  Future<String?> linkGoogle({required String idToken}) async {
    final baseUrl = await _getBaseUrl();
    final customerId = await getCustomerId();

    final token = await Session().getToken();

    final uri = Uri.parse('$baseUrl/customer/$customerId/link-google');
    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'idToken': idToken}),
    );

    Map<String, dynamic> data;
    try {
      data = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Backend ตอบไม่ใช่ JSON: ${res.body}');
    }

    if (res.statusCode != 200 || data['ok'] != true) {
      throw Exception(data['message'] ?? 'เชื่อม Google ไม่สำเร็จ');
    }

    return "เชื่อม Google สำเร็จ";
  }
  Future<void> logout() async {
    await Session().clear();

    try {
      await GoogleSignIn().signOut();
    } catch (_) {}

   try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
  }
}
