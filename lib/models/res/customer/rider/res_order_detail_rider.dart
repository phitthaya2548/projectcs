import 'dart:convert';

OrderDetailResponse orderDetailResponseFromJson(String str) =>
    OrderDetailResponse.fromJson(json.decode(str));

String orderDetailResponseToJson(OrderDetailResponse data) =>
    json.encode(data.toJson());

class OrderDetailResponse {
  bool? ok;
  OrderDetailData? data;
  String? message;

  OrderDetailResponse({
    this.ok,
    this.data,
    this.message,
  });

  factory OrderDetailResponse.fromJson(Map<String, dynamic> json) =>
      OrderDetailResponse(
        ok: json["ok"],
        data: json["data"] == null
            ? null
            : OrderDetailData.fromJson(json["data"]),
        message: json["message"],
      );

  Map<String, dynamic> toJson() => {
        "ok": ok,
        "data": data?.toJson(),
        "message": message,
      };
}

class OrderDetailData {
  String? orderId;
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
  CustomerModel? customer;
  AddressModel? address;
  StaffModel? staff;
  RiderModel? riderPickup;
  RiderModel? riderDelivery;

  OrderDetailData({
    this.orderId,
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
    this.staff,
    this.riderPickup,
    this.riderDelivery,
  });

  factory OrderDetailData.fromJson(Map<String, dynamic> json) =>
      OrderDetailData(
        orderId: json["order_id"],
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
        orderDatetime: parseFirestoreDateTime(json["order_datetime"]),
        customer: json["customer"] == null
            ? null
            : CustomerModel.fromJson(json["customer"]),
        address: json["address"] == null
            ? null
            : AddressModel.fromJson(json["address"]),
        staff: json["staff"] == null
            ? null
            : StaffModel.fromJson(json["staff"]),
        riderPickup: json["rider_pickup"] == null
            ? null
            : RiderModel.fromJson(json["rider_pickup"]),
        riderDelivery: json["rider_delivery"] == null
            ? null
            : RiderModel.fromJson(json["rider_delivery"]),
      );

  Map<String, dynamic> toJson() => {
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
        "order_datetime": orderDatetime == null
            ? null
            : {
                "_seconds": orderDatetime!.millisecondsSinceEpoch ~/ 1000,
              },
        "customer": customer?.toJson(),
        "address": address?.toJson(),
        "staff": staff?.toJson(),
        "rider_pickup": riderPickup?.toJson(),
        "rider_delivery": riderDelivery?.toJson(),
      };
}

class CustomerModel {
  String? customerId;
  String? username;
  String? fullname;
  String? profileImage;
  String? phone;

  CustomerModel({
    this.customerId,
    this.username,
    this.fullname,
    this.profileImage,
    this.phone,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) => CustomerModel(
        customerId: json["customer_id"],
        username: json["username"],
        fullname: json["fullname"],
        profileImage: json["profile_image"],
        phone: json["phone"],
      );

  Map<String, dynamic> toJson() => {
        "customer_id": customerId,
        "username": username,
        "fullname": fullname,
        "profile_image": profileImage,
        "phone": phone,
      };
}

class AddressModel {
  String? addressText;
  double? latitude;
  double? longitude;

  AddressModel({
    this.addressText,
    this.latitude,
    this.longitude,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) => AddressModel(
        addressText: json["address_text"],
        latitude: json["latitude"]?.toDouble(),
        longitude: json["longitude"]?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        "address_text": addressText,
        "latitude": latitude,
        "longitude": longitude,
      };
}

class StaffModel {
  String? fullname;
  String? phone;
  String? profileImage;

  StaffModel({
    this.fullname,
    this.phone,
    this.profileImage,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) => StaffModel(
        fullname: json["fullname"],
        phone: json["phone"],
        profileImage: json["profile_image"],
      );

  Map<String, dynamic> toJson() => {
        "fullname": fullname,
        "phone": phone,
        "profile_image": profileImage,
      };
}

class RiderModel {
  String? fullname;
  String? phone;
  String? vehicleType;
  String? licensePlate;
  String? profileImage;

  RiderModel({
    this.fullname,
    this.phone,
    this.vehicleType,
    this.licensePlate,
    this.profileImage,
  });

  factory RiderModel.fromJson(Map<String, dynamic> json) => RiderModel(
        fullname: json["fullname"],
        phone: json["phone"],
        vehicleType: json["vehicle_type"],
        licensePlate: json["license_plate"],
        profileImage: json["profile_image"],
      );

  Map<String, dynamic> toJson() => {
        "fullname": fullname,
        "phone": phone,
        "vehicle_type": vehicleType,
        "license_plate": licensePlate,
        "profile_image": profileImage,
      };
}

DateTime? parseFirestoreDateTime(dynamic json) {
  if (json == null) {
    return null;
  }

  if (json is Map<String, dynamic>) {
    final seconds = json["_seconds"];
    if (seconds != null) {
      return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    }
  }

  return null;
}