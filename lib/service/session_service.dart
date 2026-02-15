import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Session{
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const _kRole = 'role';
  static const _kCustomerId = 'customer_id';
  static const _kStoreId = 'store_id';
  static const _kToken = 'token';
  static const _kFullname = 'fullname';
  static const _kPhonecus = 'phone';
  static const _kProfileImage = 'profile_image';

  Future<void> saveLogin({
    required String role,
    String? customerId,
    String? storeId,
    String? token,
    String? fullname,
    String? profileImage,
    String? phone,
  }) async {
    
    await _storage.write(key: _kRole, value: role);
    await _storage.write(key: _kCustomerId, value: customerId ?? '');
    await _storage.write(key: _kStoreId, value: storeId ?? '');
    await _storage.write(key: _kPhonecus, value: phone ?? '');
    await _storage.write(key: _kToken, value: token ?? '');
    await _storage.write(key: _kFullname, value: fullname ?? '');
    await _storage.write(key: _kProfileImage, value: profileImage ?? '');
  }

  Future<String?> getRole() => _storage.read(key: _kRole);
  Future<String?> getCustomerId() => _storage.read(key: _kCustomerId);
  Future<String?> getStoreId() => _storage.read(key: _kStoreId);
  Future<String?> getToken() => _storage.read(key: _kToken);
  Future<String?> getFullname() => _storage.read(key: _kFullname);
  Future<String?> getPhoneCustomer() => _storage.read(key: _kPhonecus);
  Future<String?> getProfileImage() => _storage.read(key: _kProfileImage);

  Future<void> clear() async {
    await _storage.deleteAll();
  }
}