import 'dart:convert';

LaundryStaffDetailResponse laundryStaffDetailResponseFromJson(String str) =>
    LaundryStaffDetailResponse.fromJson(json.decode(str));

String laundryStaffDetailResponseToJson(LaundryStaffDetailResponse data) =>
    json.encode(data.toJson());

class LaundryStaffDetailResponse {
  final bool ok;
  final String? message;
  final LaundryStaffDetail? data;

  LaundryStaffDetailResponse({
    required this.ok,
    this.message,
    this.data,
  });

  factory LaundryStaffDetailResponse.fromJson(Map<String, dynamic> json) {
    return LaundryStaffDetailResponse(
      ok: json['ok'] ?? false,
      message: json['message']?.toString(),
      data: json['data'] != null
          ? LaundryStaffDetail.fromJson(json['data'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ok': ok,
      'message': message,
      'data': data?.toJson(),
    };
  }
}

class LaundryStaffDetail {
  final String staffId;
  final String? storeId;
  final String email;
  final String username;
  final String fullname;
  final String phone;
  final String? profileImage;
  final String status;

  LaundryStaffDetail({
    required this.staffId,
    this.storeId,
    required this.email,
    required this.username,
    required this.fullname,
    required this.phone,
    required this.profileImage,
    required this.status,
  });

  factory LaundryStaffDetail.fromJson(Map<String, dynamic> json) {
    return LaundryStaffDetail(
      staffId: json['staff_id']?.toString() ??
          json['laundry_staff_id']?.toString() ??
          '',
      storeId: json['store_id']?.toString(),
      email: json['email']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      fullname: json['fullname']?.toString() ??
          json['full_name']?.toString() ??
          '',
      phone: json['phone']?.toString() ?? '',
      profileImage: json['profile_image']?.toString(),
      status: json['status']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'staff_id': staffId,
      'store_id': storeId,
      'email': email,
      'username': username,
      'fullname': fullname,
      'phone': phone,
      'profile_image': profileImage,
      'status': status,
    };
  }
}