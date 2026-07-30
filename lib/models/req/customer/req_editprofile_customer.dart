import 'dart:convert';

Customer customerFromJson(String str) =>
    Customer.fromJson(json.decode(str));

String customerToJson(Customer data) =>
    json.encode(data.toJson());

class Customer {
  final String customerId;
  final String username;
  final String fullname;
  final String email;
  final String phone;
  final String gender;
  final String? birthday;
  final String profileImage;
  final double walletBalance;
  final String googleId;

  Customer({
    required this.customerId,
    required this.username,
    required this.fullname,
    required this.email,
    required this.phone,
    required this.gender,
    this.birthday,
    required this.profileImage,
    required this.walletBalance,
    required this.googleId,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      customerId: json['customer_id'] ?? '',
      username: json['username'] ?? '',
      fullname: json['fullname'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      gender: json['gender'] ?? '',
      birthday: json['birthday'],
      profileImage: json['profile_image'] ?? '',
      walletBalance: (json['wallet_balance'] ?? 0).toDouble(),
      googleId: json['google_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'username': username,
      'fullname': fullname,
      'email': email,
      'phone': phone,
      'gender': gender,
      'birthday': birthday,
      'profile_image': profileImage,
      'wallet_balance': walletBalance,
      'google_id': googleId,
    };
  }

  Customer copyWith({
    String? customerId,
    String? username,
    String? fullname,
    String? email,
    String? phone,
    String? gender,
    String? birthday,
    String? profileImage,
    double? walletBalance,
    String? googleId,
  }) {
    return Customer(
      customerId: customerId ?? this.customerId,
      username: username ?? this.username,
      fullname: fullname ?? this.fullname,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      birthday: birthday ?? this.birthday,
      profileImage: profileImage ?? this.profileImage,
      walletBalance: walletBalance ?? this.walletBalance,
      googleId: googleId ?? this.googleId,
    );
  }
}