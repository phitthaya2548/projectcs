import 'dart:convert';

RiderDetailResponse riderDetailResponseFromJson(String str) =>
    RiderDetailResponse.fromJson(json.decode(str));

String riderDetailResponseToJson(RiderDetailResponse data) =>
    json.encode(data.toJson());

class RiderDetailResponse {
  final bool ok;
  final RiderDetail? data;
  final String? message;

  RiderDetailResponse({
    required this.ok,
    this.data,
    this.message,
  });

  factory RiderDetailResponse.fromJson(Map<String, dynamic> json) {
    return RiderDetailResponse(
      ok: json['ok'] ?? false,
      data: json['data'] != null ? RiderDetail.fromJson(json['data']) : null,
      message: json['message']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ok': ok,
      'data': data?.toJson(),
      'message': message,
    };
  }
}

class RiderDetail {
  final String riderId;
  final String? storeId;
  final String email;
  final String username;
  final String fullname;
  final String phone;
  final String vehicleType;
  final String licensePlate;
  final String? profileImage;
  final String? status;
  final double? latitude;
  final double? longitude;

  RiderDetail({
    required this.riderId,
    this.storeId,
    required this.email,
    required this.username,
    required this.fullname,
    required this.phone,
    required this.vehicleType,
    required this.licensePlate,
    this.profileImage,
    this.status,
    this.latitude,
    this.longitude,
  });

  factory RiderDetail.fromJson(Map<String, dynamic> json) {
    return RiderDetail(
      riderId: json['rider_id']?.toString() ?? '',
      storeId: json['store_id']?.toString(),
      email: json['email']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      fullname: json['fullname']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      vehicleType: json['vehicle_type']?.toString() ?? '',
      licensePlate: json['license_plate']?.toString() ?? '',
      profileImage: json['profile_image']?.toString(),
      status: json['status']?.toString(),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rider_id': riderId,
      'store_id': storeId,
      'email': email,
      'username': username,
      'fullname': fullname,
      'phone': phone,
      'vehicle_type': vehicleType,
      'license_plate': licensePlate,
      'profile_image': profileImage,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }
}