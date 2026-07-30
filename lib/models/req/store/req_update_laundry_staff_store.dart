import 'dart:convert';

UpdateLaundryStaffRequest updateLaundryStaffRequestFromJson(String str) =>
    UpdateLaundryStaffRequest.fromJson(json.decode(str));

String updateLaundryStaffRequestToJson(UpdateLaundryStaffRequest data) =>
    json.encode(data.toJson());

class UpdateLaundryStaffRequest {
  final String email;
  final String fullname;
  final String phone;

  UpdateLaundryStaffRequest({
    required this.email,
    required this.fullname,
    required this.phone,
  });

  factory UpdateLaundryStaffRequest.fromJson(Map<String, dynamic> json) {
    return UpdateLaundryStaffRequest(
      email: json['email']?.toString() ?? '',
      fullname: json['fullname']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email.trim(),
      'fullname': fullname.trim(),
      'phone': phone.trim(),
    };
  }
}