class StoreApplicantsResponse {
  final bool ok;
  final List<RiderApplicant> riders;
  final List<StaffApplicant> staff;
  final int total;

  StoreApplicantsResponse({
    required this.ok,
    required this.riders,
    required this.staff,
    required this.total,
  });

  factory StoreApplicantsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return StoreApplicantsResponse(
      ok: json['ok'] == true,
      riders: (data['riders'] as List? ?? [])
          .map((e) => RiderApplicant.fromJson(e as Map<String, dynamic>))
          .toList(),
      staff: (data['staff'] as List? ?? [])
          .map((e) => StaffApplicant.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: data['total'] as int? ?? 0,
    );
  }
}

class RiderApplicant {
  final String riderId;
  final String fullname;
  final String email;
  final String phone;
  final String profileImage;
  final String vehicleType;
  final String licensePlate;
  final DateTime? appliedAt;

  RiderApplicant({
    required this.riderId,
    required this.fullname,
    required this.email,
    required this.phone,
    required this.profileImage,
    required this.vehicleType,
    required this.licensePlate,
    this.appliedAt,
  });

  factory RiderApplicant.fromJson(Map<String, dynamic> json) {
    return RiderApplicant(
      riderId: json['rider_id']?.toString() ?? '',
      fullname: json['fullname']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      profileImage: json['profile_image']?.toString() ?? '',
      vehicleType: json['vehicle_type']?.toString() ?? '',
      licensePlate: json['license_plate']?.toString() ?? '',
      appliedAt: _parseTimestamp(json['applied_at']),
    );
  }
}

class StaffApplicant {
  final String staffId;
  final String fullname;
  final String email;
  final String phone;
  final String profileImage;
  final DateTime? appliedAt;

  StaffApplicant({
    required this.staffId,
    required this.fullname,
    required this.email,
    required this.phone,
    required this.profileImage,
    this.appliedAt,
  });

  factory StaffApplicant.fromJson(Map<String, dynamic> json) {
    return StaffApplicant(
      staffId: json['staff_id']?.toString() ?? '',
      fullname: json['fullname']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      profileImage: json['profile_image']?.toString() ?? '',
      appliedAt: _parseTimestamp(json['applied_at']),
    );
  }
}

DateTime? _parseTimestamp(dynamic value) {
  if (value == null) return null;
  if (value is Map && value['_seconds'] != null) {
    return DateTime.fromMillisecondsSinceEpoch((value['_seconds'] as int) * 1000);
  }
  return null;
}