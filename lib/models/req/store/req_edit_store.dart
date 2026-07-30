class StoreProfileModel {
  final String storeName;
  final String phone;
  final String email;
  final String address;
  final double serviceRadius;
  final String openingHours;
  final String closingHours;
  final double deliveryMin;
  final double deliveryMax;
  final double detergentPrice;
  final String? facebook;
  final String? lineId;
  final double? latitude;
  final double? longitude;

  const StoreProfileModel({
    required this.storeName,
    required this.phone,
    required this.email,
    required this.address,
    required this.serviceRadius,
    required this.openingHours,
    required this.closingHours,
    required this.deliveryMin,
    required this.deliveryMax,
    required this.detergentPrice,
    this.facebook,
    this.lineId,
    this.latitude,
    this.longitude,
  });

  StoreProfileModel copyWithCoordinates({
    required double latitude,
    required double longitude,
  }) {
    return StoreProfileModel(
      storeName: storeName,
      phone: phone,
      email: email,
      address: address,
      serviceRadius: serviceRadius,
      openingHours: openingHours,
      closingHours: closingHours,
      deliveryMin: deliveryMin,
      deliveryMax: deliveryMax,
      detergentPrice: detergentPrice,
      facebook: facebook,
      lineId: lineId,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'store_name': storeName,
      'phone': phone,
      'email': email,
      'address': address,
      'service_radius': serviceRadius,
      'opening_hours': openingHours,
      'closed_hours': closingHours,
      'delivery_min': deliveryMin,
      'delivery_max': deliveryMax,
      'detergent_price': detergentPrice,
    };

    if (facebook != null && facebook!.trim().isNotEmpty) {
      map['facebook'] = facebook!.trim();
    }
    if (lineId != null && lineId!.trim().isNotEmpty) {
      map['line_id'] = lineId!.trim();
    }
    if (latitude != null) map['latitude'] = latitude;
    if (longitude != null) map['longitude'] = longitude;

    return map;
  }

  Map<String, String> toFormFields() =>
      toJson().map((key, value) => MapEntry(key, value.toString()));
}


class ApiResponseModel {
  final bool ok;
  final String? message;

  const ApiResponseModel({required this.ok, this.message});

  factory ApiResponseModel.fromJson(Map<String, dynamic> json) {
    return ApiResponseModel(
      ok: json['ok'] == true,
      message: json['message'] as String?,
    );
  }

  void throwIfNotOk(String fallbackMessage) {
    if (!ok) {
      throw Exception(message ?? fallbackMessage);
    }
  }
}