import 'dart:convert';

UpdateRiderRequest updateRiderRequestFromJson(String str) =>
    UpdateRiderRequest.fromJson(json.decode(str));

String updateRiderRequestToJson(UpdateRiderRequest data) =>
    json.encode(data.toJson());

class UpdateRiderRequest {
  final String email;
  final String fullname;
  final String phone;
  final String vehicleType;
  final String licensePlate;

  UpdateRiderRequest({
    required this.email,
    required this.fullname,
    required this.phone,
    required this.vehicleType,
    required this.licensePlate,
  });

  factory UpdateRiderRequest.fromJson(Map<String, dynamic> json) {
    return UpdateRiderRequest(
      email: json['email']?.toString() ?? '',
      fullname: json['fullname']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      vehicleType: json['vehicle_type']?.toString() ?? '',
      licensePlate: json['license_plate']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email.trim(),
      'fullname': fullname.trim(),
      'phone': phone.trim(),
      'vehicle_type': vehicleType,
      'license_plate': licensePlate.trim(),
    };
  }
}