class StoreData {
  final String storeId;
  final String username;
  final String storeName;
  final String email;
  final String phone;
  final String facebook;
  final String lineId;
  final String address;
  final String openingHours;
  final String closedHours;
  final double serviceRadius;
  final double latitude;
  final double longitude;
  final String status;
  final String profileImage;
  final double walletBalance;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  StoreData({
    required this.storeId,
    required this.username,
    required this.storeName,
    required this.email,
    required this.phone,
    required this.facebook,
    required this.lineId,
    required this.address,
    required this.openingHours,
    required this.closedHours,
    required this.serviceRadius,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.profileImage,
    required this.walletBalance,
    this.createdAt,
    this.updatedAt,
  });

  factory StoreData.fromJson(Map<String, dynamic> json) {
    return StoreData(
      storeId: json['store_id'] ?? '',
      username: json['username'] ?? '',
      storeName: json['store_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      facebook: json['facebook'] ?? '',
      lineId: json['line_id'] ?? '',
      address: json['address'] ?? '',
      openingHours: json['opening_hours'] ?? '',
      closedHours: json['closed_hours'] ?? '',
      serviceRadius: (json['service_radius'] ?? 0).toDouble(),
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      profileImage: json['profile_image'] ?? '',
      walletBalance: (json['wallet_balance'] ?? 0).toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }
}
