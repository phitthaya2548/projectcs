import 'dart:convert';

OrderDetailResponse orderDetailResponseFromJson(String str) =>
    OrderDetailResponse.fromJson(json.decode(str));

String orderDetailResponseToJson(OrderDetailResponse data) =>
    json.encode(data.toJson());

class OrderDetailResponse {
  bool ok;
  String? message;
  OrderDetailData? data;

  OrderDetailResponse({
    required this.ok,
    this.message,
    this.data,
  });

  factory OrderDetailResponse.fromJson(Map<String, dynamic> json) {
    return OrderDetailResponse(
      ok: json["ok"] ?? false,
      message: json["message"],
      data: json["data"] == null
          ? null
          : OrderDetailData.fromJson(json["data"]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "ok": ok,
      "message": message,
      "data": data?.toJson(),
    };
  }
}

class OrderDetailData {
  String orderId;
  String? customerId;
  String? addressId;
  String? storeId;
  String? riderPickupId;
  String? riderDeliveryId;
  String? machineWasherId;
  String? machineDryerId;
  String? staffId;
  String? serviceType;
  num? washDryWeight;
  num? servicePrice;
  num? deliveryPrice;
  String? detergentOption;
  String? beforeWashImage;
  String? afterWashImage;
  String? note;
  String? status;
  DateTime? orderDatetime;
  Customer? customer;
  Address? address;
  RiderPickup? riderPickup;

  OrderDetailData({
    required this.orderId,
    this.customerId,
    this.addressId,
    this.storeId,
    this.riderPickupId,
    this.riderDeliveryId,
    this.machineWasherId,
    this.machineDryerId,
    this.staffId,
    this.serviceType,
    this.washDryWeight,
    this.servicePrice,
    this.deliveryPrice,
    this.detergentOption,
    this.beforeWashImage,
    this.afterWashImage,
    this.note,
    this.status,
    this.orderDatetime,
    this.customer,
    this.address,
    this.riderPickup,
  });

  factory OrderDetailData.fromJson(Map<String, dynamic> json) {
    DateTime? parsedOrderDatetime;
    final rawOrderDatetime = json["order_datetime"];

    if (rawOrderDatetime is String) {
      parsedOrderDatetime = DateTime.tryParse(rawOrderDatetime);
    } else if (rawOrderDatetime is Map<String, dynamic>) {
      final seconds = rawOrderDatetime["_seconds"];
      final nanoseconds = rawOrderDatetime["_nanoseconds"] ?? 0;

      if (seconds is int && nanoseconds is int) {
        parsedOrderDatetime = DateTime.fromMillisecondsSinceEpoch(
          (seconds * 1000) + (nanoseconds ~/ 1000000),
        );
      }
    }

    return OrderDetailData(
      orderId: json["order_id"] ?? "",
      customerId: json["customer_id"],
      addressId: json["address_id"],
      storeId: json["store_id"],
      riderPickupId: json["rider_pickup_id"],
      riderDeliveryId: json["rider_delivery_id"],
      machineWasherId: json["machine_washer_id"],
      machineDryerId: json["machine_dryer_id"],
      staffId: json["staff_id"],
      serviceType: json["service_type"],
      washDryWeight: json["wash_dry_weight"],
      servicePrice: json["service_price"],
      deliveryPrice: json["delivery_price"],
      detergentOption: json["detergent_option"],
      beforeWashImage: json["before_wash_image"],
      afterWashImage: json["after_wash_image"],
      note: json["note"],
      status: json["status"],
      orderDatetime: parsedOrderDatetime,
      customer: json["customer"] == null
          ? null
          : Customer.fromJson(json["customer"]),
      address: json["address"] == null
          ? null
          : Address.fromJson(json["address"]),
      riderPickup: json["rider_pickup"] == null
          ? null
          : RiderPickup.fromJson(json["rider_pickup"]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "order_id": orderId,
      "customer_id": customerId,
      "address_id": addressId,
      "store_id": storeId,
      "rider_pickup_id": riderPickupId,
      "rider_delivery_id": riderDeliveryId,
      "machine_washer_id": machineWasherId,
      "machine_dryer_id": machineDryerId,
      "staff_id": staffId,
      "service_type": serviceType,
      "wash_dry_weight": washDryWeight,
      "service_price": servicePrice,
      "delivery_price": deliveryPrice,
      "detergent_option": detergentOption,
      "before_wash_image": beforeWashImage,
      "after_wash_image": afterWashImage,
      "note": note,
      "status": status,
      "order_datetime": orderDatetime?.toIso8601String(),
      "customer": customer?.toJson(),
      "address": address?.toJson(),
      "rider_pickup": riderPickup?.toJson(),
    };
  }
}

class Customer {
  String customerId;
  String? username;
  String? fullname;
  String? profileImage;
  String? phone;

  Customer({
    required this.customerId,
    this.username,
    this.fullname,
    this.profileImage,
    this.phone,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      customerId: json["customer_id"] ?? "",
      username: json["username"],
      fullname: json["fullname"],
      profileImage: json["profile_image"],
      phone: json["phone"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "customer_id": customerId,
      "username": username,
      "fullname": fullname,
      "profile_image": profileImage,
      "phone": phone,
    };
  }
}

class Address {
  String? addressText;

  Address({
    this.addressText,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      addressText: json["address_text"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "address_text": addressText,
    };
  }
}

class RiderPickup {
  String? fullname;
  String? phone;
  String? vehicleType;
  String? licensePlate;
  String? profileImage;

  RiderPickup({
    this.fullname,
    this.phone,
    this.vehicleType,
    this.licensePlate,
    this.profileImage,
  });

  factory RiderPickup.fromJson(Map<String, dynamic> json) {
    return RiderPickup(
      fullname: json["fullname"],
      phone: json["phone"],
      vehicleType: json["vehicle_type"],
      licensePlate: json["license_plate"],
      profileImage: json["profile_image"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "fullname": fullname,
      "phone": phone,
      "vehicle_type": vehicleType,
      "license_plate": licensePlate,
      "profile_image": profileImage,
    };
  }
}