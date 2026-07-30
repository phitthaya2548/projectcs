class CustomerProfileResponse {
  final bool ok;
  final String customerId;
  final CustomerProfile data;

  CustomerProfileResponse({
    required this.ok,
    required this.customerId,
    required this.data,
  });

  factory CustomerProfileResponse.fromJson(Map<String, dynamic> json) {
    return CustomerProfileResponse(
      ok: json['ok'] ?? false,
      customerId: json['customer_id']?.toString() ?? '',
      data: CustomerProfile.fromJson(json['data'] ?? {}),
    );
  }
}

class CustomerProfile {
  final String customerId;
  final String username;
  final String fullname;
  final String email;
  final String phone;
  final String gender;
  final DateTime? birthday;
  final String profileImage;
  final double walletBalance;
  final String googleId;

  CustomerProfile({
    required this.customerId,
    required this.username,
    required this.fullname,
    required this.email,
    required this.phone,
    required this.gender,
    required this.birthday,
    required this.profileImage,
    required this.walletBalance,
    required this.googleId,
  });

  factory CustomerProfile.fromJson(Map<String, dynamic> json) {
    return CustomerProfile(
      customerId: json['customer_id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      fullname: json['fullname']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      birthday: _parseBirthday(json['birthday']),
      profileImage: json['profile_image']?.toString() ?? '',
      walletBalance: (json['wallet_balance'] is num)
          ? (json['wallet_balance'] as num).toDouble()
          : double.tryParse(json['wallet_balance']?.toString() ?? '') ?? 0.0,
      googleId: json['google_id']?.toString() ?? '',
    );
  }

  static DateTime? _parseBirthday(dynamic value) {
    if (value == null) return null;

    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }

    if (value is Map<String, dynamic>) {
      final seconds = value['_seconds'] ?? value['seconds'];
      if (seconds != null) {
        return DateTime.fromMillisecondsSinceEpoch(
          (seconds as num).toInt() * 1000,
        );
      }
    }

    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'username': username,
      'fullname': fullname,
      'email': email,
      'phone': phone,
      'gender': gender,
      'birthday': birthday?.toIso8601String(),
      'profile_image': profileImage,
      'wallet_balance': walletBalance,
      'google_id': googleId,
    };
  }
}