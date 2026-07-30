class WorkOfRider {
  final String id;
  final String? orderNumber;
  final String status;
  final String? serviceType;
  final double? distanceKm;
  final double? addressLat;   // ✅ เพิ่ม
  final double? addressLng;   // ✅ เพิ่ม
  final String? timeSlot;
  final String? note;
  final String? beforeWashImage;
  final String? afterWashImage;
  final String? riderPickupId;
  final String? riderDeliveryId;
  final DateTime? order_datetime;
  final String? address;
  final CustomerOfRider? customer;

  WorkOfRider({
    required this.id,
    this.orderNumber,
    required this.status,
    this.serviceType,
    this.distanceKm,
    this.addressLat,
    this.addressLng,
    this.timeSlot,
    this.note,
    this.beforeWashImage,
    this.afterWashImage,
    this.riderPickupId,
    this.riderDeliveryId,
    this.order_datetime,
    this.address,
    this.customer,
  });

  factory WorkOfRider.fromJson(Map<String, dynamic> json) {
    return WorkOfRider(
      id: json['id'] ?? '',
      orderNumber: json['order_number'],
      status: json['status'] ?? '',
      serviceType: json['service_type'],
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      addressLat: (json['address_lat'] as num?)?.toDouble(),   // ✅ เพิ่ม
      addressLng: (json['address_lng'] as num?)?.toDouble(),   // ✅ เพิ่ม
      timeSlot: json['time_slot'],
      note: json['note'],
      beforeWashImage: json['before_wash_image'],
      afterWashImage: json['after_wash_image'],
      riderPickupId: json['rider_pickup_id'],
      riderDeliveryId: json['rider_delivery_id'],
      order_datetime: json['order_datetime'] != null
          ? DateTime.tryParse(json['order_datetime'].toString())
          : null,
      address: json['address'],
      customer: json['customer'] != null
          ? CustomerOfRider.fromJson(json['customer'])
          : null,
    );
  }

  // ✅ เพิ่ม copyWith สำหรับ recompute distance client-side
  WorkOfRider copyWith({double? distanceKm}) {
    return WorkOfRider(
      id: id,
      orderNumber: orderNumber,
      status: status,
      serviceType: serviceType,
      distanceKm: distanceKm ?? this.distanceKm,
      addressLat: addressLat,
      addressLng: addressLng,
      timeSlot: timeSlot,
      note: note,
      beforeWashImage: beforeWashImage,
      afterWashImage: afterWashImage,
      riderPickupId: riderPickupId,
      riderDeliveryId: riderDeliveryId,
      order_datetime: order_datetime,
      address: address,
      customer: customer,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'status': status,
      'service_type': serviceType,
      'distance_km': distanceKm,
      'address_lat': addressLat,
      'address_lng': addressLng,
      'time_slot': timeSlot,
      'note': note,
      'before_wash_image': beforeWashImage,
      'after_wash_image': afterWashImage,
      'rider_pickup_id': riderPickupId,
      'rider_delivery_id': riderDeliveryId,
      'address': address,
      'customer': customer?.toJson(),
    };
  }
}

class CustomerOfRider {
  final String id;
  final String name;
  final String phone;
  final String? profileImage;

  CustomerOfRider({
    required this.id,
    required this.name,
    required this.phone,
    this.profileImage,
  });

  factory CustomerOfRider.fromJson(Map<String, dynamic> json) {
    return CustomerOfRider(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      profileImage: json['profile_image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'profile_image': profileImage,
    };
  }
}