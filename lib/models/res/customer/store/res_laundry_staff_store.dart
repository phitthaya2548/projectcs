class LaundryStaff {
  final String staffId;
  final String email;
  final String username;
  final String fullName;
  final String phone;
  final String? profileImage;
  final String status;

  LaundryStaff({
    required this.staffId,
    required this.email,
    required this.username,
    required this.fullName,
    required this.phone,
    this.profileImage,
    required this.status,
  });

  factory LaundryStaff.fromJson(Map<String, dynamic> json) {
    return LaundryStaff(
      staffId: json['staff_id'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      fullName: json['fullname'] ?? '',
      phone: json['phone'] ?? '',
      profileImage: json['profile_image'],
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'staff_id': staffId,
      'email': email,
      'username': username,
      'fullname': fullName,
      'phone': phone,
      'profile_image': profileImage,
      'status': status,
    };
  }
}

class LaundryStaffResponse {
  final bool ok;
  final int total;
  final List<LaundryStaff> data;
  final String? message;

  LaundryStaffResponse({
    required this.ok,
    required this.total,
    required this.data,
    this.message,
  });

  factory LaundryStaffResponse.fromJson(Map<String, dynamic> json) {
    return LaundryStaffResponse(
      ok: json['ok'] ?? false,
      total: json['total'] ?? 0,
      data: (json['data'] as List?)
              ?.map((item) => LaundryStaff.fromJson(item))
              .toList() ??
          [],
      message: json['message'],
    );
  }
}