class Rider {
  final String riderId;
  final String email;
  final String username;
  final String fullName;
  final String phone;
  final String vehicleType;
  final String licensePlate;
  final String? profileImage;
  final String status;
  final double? latitude;
  final double? longitude;

  Rider({
    required this.riderId,
    required this.email,
    required this.username,
    required this.fullName,
    required this.phone,
    required this.vehicleType,
    required this.licensePlate,
    this.profileImage,
    required this.status,
    this.latitude,
    this.longitude,
  });

  factory Rider.fromJson(Map<String, dynamic> json) {
    return Rider(
      riderId: json['rider_id'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      fullName: json['fullname'] ?? '',
      phone: json['phone'] ?? '',
      vehicleType: json['vehicle_type'] ?? '',
      licensePlate: json['license_plate'] ?? '',
      profileImage: json['profile_image'],
      status: json['status'] ?? '',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rider_id': riderId,
      'email': email,
      'username': username,
      'fullname': fullName,
      'phone': phone,
      'vehicle_type': vehicleType,
      'license_plate': licensePlate,
      'profile_image': profileImage,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class RiderResponse {
  final bool ok;
  final int count;
  final List<Rider> data;
  final String? message;

  RiderResponse({
    required this.ok,
    required this.count,
    required this.data,
    this.message,
  });

  factory RiderResponse.fromJson(Map<String, dynamic> json) {
    return RiderResponse(
      ok: json['ok'] ?? false,
      count: json['count'] ?? 0,
      data: (json['data'] as List?)
              ?.map((item) => Rider.fromJson(item))
              .toList() ??
          [],
      message: json['message'],
    );
  }
}