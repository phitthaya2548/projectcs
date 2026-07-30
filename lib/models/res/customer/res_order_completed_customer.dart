import 'dart:convert';

CompletedOrder completedOrderFromJson(String str) =>
    CompletedOrder.fromJson(json.decode(str)['data']);

String completedOrderToJson(CompletedOrder data) =>
    json.encode(data.toJson());

class CompletedOrder {
  final String orderId;
  final String status;
  final String serviceType;
  final String? detergentOption;
  final double servicePrice;
  final double totalAmount;
  final double detergentPrice;
  final double deliveryPrice;
  final double washDryWeight;
  final String? note;
  final String? beforeWashImage;
  final String? afterWashImage;
  final DateTime? orderDatetime;
  final String? storeId;
  final String? storeName;
  final String? addressId;
  final String? addressText;
  final String? machineWasherId;
  final String? machineDryerId;
  final RiderInfo? riderPickup;
  final RiderInfo? riderDelivery;
  final StaffInfo? staff;
  final ReviewInfo? review;

  CompletedOrder({
    required this.orderId,
    required this.status,
    required this.serviceType,
    this.detergentOption,
    required this.detergentPrice,
    required this.servicePrice,
    required this.totalAmount,
    required this.deliveryPrice,
    required this.washDryWeight,
    this.note,
    this.beforeWashImage,
    this.afterWashImage,
    this.orderDatetime,
    this.storeId,
    this.storeName,
    this.addressId,
    this.addressText,
    this.machineWasherId,
    this.machineDryerId,
    this.riderPickup,
    this.riderDelivery,
    this.staff,
    this.review,
  });

  factory CompletedOrder.fromJson(Map<String, dynamic> json) => CompletedOrder(
        orderId:          json['order_id'] ?? '',
        status:           json['status'] ?? '',
        serviceType:      json['service_type'] ?? '',
        detergentOption:  json['detergent_option'] as String?,
        servicePrice:     (json['service_price'] ?? 0).toDouble(), 
        detergentPrice:  (json['detergent_price'] ?? 0).toDouble(),
        totalAmount:      (json['total_amount'] ?? 0).toDouble(),
        deliveryPrice:    (json['delivery_price'] ?? 0).toDouble(),
        washDryWeight:    (json['wash_dry_weight'] ?? 0).toDouble(),
        note:             json['note'] as String?,
        beforeWashImage:  json['before_wash_image'] as String?,
        afterWashImage:   json['after_wash_image'] as String?,
        orderDatetime: json['order_datetime'] != null
            ? (json['order_datetime'] is String
                ? DateTime.parse(json['order_datetime'])
                : DateTime.fromMillisecondsSinceEpoch(
                    ((json['order_datetime']['_seconds'] as num) * 1000).toInt()))
            : null,
        storeId:          json['store_id'] as String?,
        storeName:        json['store_name'] as String?,
        addressId:        json['address_id'] as String?,
        addressText:      json['address_text'] as String?, 
        machineWasherId:  json['machine_washer_id'] as String?,
        machineDryerId:   json['machine_dryer_id'] as String?,
        riderPickup: json['rider_pickup'] != null
            ? RiderInfo.fromJson(json['rider_pickup'])
            : null,
        riderDelivery: json['rider_delivery'] != null
            ? RiderInfo.fromJson(json['rider_delivery'])
            : null,
        staff: json['staff'] != null
            ? StaffInfo.fromJson(json['staff'])
            : null,
        review: json['review'] != null
            ? ReviewInfo.fromJson(json['review'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'order_id':          orderId,
        'status':            status,
        'service_type':      serviceType,
        'detergent_option':  detergentOption,
        'service_price':     servicePrice,
        'total_amount':      totalAmount,
        'delivery_price':    deliveryPrice,
        'detergent_price':   detergentPrice,
        'wash_dry_weight':   washDryWeight,
        'note':              note,
        'before_wash_image': beforeWashImage,
        'after_wash_image':  afterWashImage,
        'order_datetime':    orderDatetime?.toIso8601String(),
        'store_id':          storeId,
        'store_name':        storeName,
        'address_id':        addressId,
        'address_text':      addressText,
        'machine_washer_id': machineWasherId,
        'machine_dryer_id':  machineDryerId,
        'rider_pickup':      riderPickup?.toJson(),
        'rider_delivery':    riderDelivery?.toJson(),
        'staff':             staff?.toJson(),
        'review':            review?.toJson(),
      };
}

class RiderInfo {
  final String riderId;
  final String fullname;
  final String phone;
  final String? profileImage;
  final String? vehicleType;
  final String? licensePlate;

  RiderInfo({
    required this.riderId,
    required this.fullname,
    required this.phone,
    this.profileImage,
    this.vehicleType,
    this.licensePlate,
  });

  factory RiderInfo.fromJson(Map<String, dynamic> json) => RiderInfo(
        riderId:      json['rider_id'] ?? '',
        fullname:     json['fullname'] ?? '',
        phone:        json['phone'] ?? '',
        profileImage: json['profile_image'] as String?,
        vehicleType:  json['vehicle_type'] as String?,
        licensePlate: json['license_plate'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'rider_id':      riderId,
        'fullname':      fullname,
        'phone':         phone,
        'profile_image': profileImage,
        'vehicle_type':  vehicleType,
        'license_plate': licensePlate,
      };
}

class StaffInfo {
  final String staffId;
  final String fullname;
  final String phone;
  final String? profileImage;
  final String? username;

  StaffInfo({
    required this.staffId,
    required this.fullname,
    required this.phone,
    this.profileImage,
    this.username,
  });

  factory StaffInfo.fromJson(Map<String, dynamic> json) => StaffInfo(
        staffId:      json['staff_id'] ?? '',
        fullname:     json['fullname'] ?? '',
        phone:        json['phone'] ?? '',
        profileImage: json['profile_image'] as String?,
        username:     json['username'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'staff_id':      staffId,
        'fullname':      fullname,
        'phone':         phone,
        'profile_image': profileImage,
        'username':      username,
      };
}


class ReviewInfo {
  final int rating;
  final String? comment;
  final DateTime? reviewedAt;

  ReviewInfo({
    required this.rating,
    this.comment,
    this.reviewedAt,
  });

  factory ReviewInfo.fromJson(Map<String, dynamic> json) => ReviewInfo(
        rating:  (json['rating'] ?? 0) is int
            ? json['rating'] as int
            : (json['rating'] as num).toInt(),
        comment: json['comment'] as String?,
        reviewedAt: json['reviewed_at'] != null
            ? (json['reviewed_at'] is String
                ? DateTime.parse(json['reviewed_at'])
                : DateTime.fromMillisecondsSinceEpoch(
                    ((json['reviewed_at']['_seconds'] as num) * 1000).toInt()))
            : null,
      );

  Map<String, dynamic> toJson() => {
        'rating':      rating,
        'comment':     comment,
        'reviewed_at': reviewedAt?.toIso8601String(),
      };
}