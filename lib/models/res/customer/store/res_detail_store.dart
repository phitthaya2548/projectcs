import 'dart:convert';

StoreDetail storeDetailFromJson(String str) =>
    StoreDetail.fromJson(json.decode(str));

String storeDetailToJson(StoreDetail data) =>
    json.encode(data.toJson());

class StoreDetail {
  final String storeId;
  final String storeName;
  final String status;
  final String openingHours;
  final String closedHours;
  final double serviceRadius;
  final double rating;
  final String address;
  final String phone;
  final String email;
  final String facebook;
  final String lineId;
  final double latitude;
  final double longitude;
  final String profileImage;

  // 🔥 เพิ่มตรงนี้
  final int machineWashCount;
  final int machineDryCount;

  int get totalMachineCount => machineWashCount + machineDryCount;

  const StoreDetail({
    required this.storeId,
    required this.storeName,
    this.status = 'OPEN',
    required this.openingHours,
    required this.closedHours,
    required this.serviceRadius,
    required this.rating,
    required this.address,
    required this.phone,
    required this.email,
    required this.facebook,
    required this.lineId,
    required this.latitude,
    required this.longitude,
    this.profileImage = '',
    required this.machineWashCount,
    required this.machineDryCount,
  });

  factory StoreDetail.fromJson(Map<String, dynamic> json) {
    // 🔥 รองรับกรณี response มี data ครอบมา
    final data = json["data"] ?? json;

    return StoreDetail(
      storeId: data['store_id'] ?? '',
      storeName: data['store_name'] ?? '',
      status: data['status'] ?? 'OPEN',
      openingHours: data['opening_hours'] ?? '',
      closedHours: data['closed_hours'] ?? '',
      serviceRadius: (data['service_radius'] ?? 0).toDouble(),
      rating: (data['rating'] ?? 0).toDouble(),
      address: data['address'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      facebook: data['facebook'] ?? '',
      lineId: data['line_id'] ?? '',
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      profileImage: data['profile_image'] ?? '',
      machineWashCount: data['machine_wash_count'] ?? 0,
      machineDryCount: data['machine_dry_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'store_id': storeId,
        'store_name': storeName,
        'status': status,
        'opening_hours': openingHours,
        'closed_hours': closedHours,
        'service_radius': serviceRadius,
        'rating': rating,
        'address': address,
        'phone': phone,
        'email': email,
        'facebook': facebook,
        'line_id': lineId,
        'latitude': latitude,
        'longitude': longitude,
        'profile_image': profileImage,
        'machine_wash_count': machineWashCount,
        'machine_dry_count': machineDryCount,
      };
}