import 'dart:convert';

ReqCreateOrder reqCreateOrderFromJson(String str) =>
    ReqCreateOrder.fromJson(json.decode(str));

String reqCreateOrderToJson(ReqCreateOrder data) =>
    json.encode(data.toJson());

class ReqCreateOrder {
  final String customerId;
  final String storeId;
  final String serviceType;
  final double washDryWeigh;
  final double totalAmount;
  final String? addressId;
  final String? riderId;
  final String? staffId;
  final String? detergentOption;
  final String? beforeWashImage;
  final String? note;

  ReqCreateOrder({
    required this.customerId,
    required this.storeId,
    required this.serviceType,
    required this.washDryWeigh,
    required this.totalAmount,
    this.addressId,
    this.riderId,
    this.staffId,
    this.detergentOption,
    this.beforeWashImage,
    this.note,
  });

  factory ReqCreateOrder.fromJson(Map<String, dynamic> json) => ReqCreateOrder(
        customerId: json["customer_id"],
        storeId: json["store_id"],
        serviceType: json["service_type"],
        washDryWeigh: (json["wash_dry_weigh"] as num).toDouble(),
        totalAmount: (json["total_amount"] as num).toDouble(),
        addressId: json["address_id"],
        riderId: json["rider_id"],
        staffId: json["staff_id"],
        detergentOption: json["detergent_option"],
        beforeWashImage: json["before_wash_image"],
        note: json["note"],
      );

  Map<String, dynamic> toJson() => {
        "customer_id": customerId,
        "store_id": storeId,
        "service_type": serviceType,
        "wash_dry_weigh": washDryWeigh,
        "total_amount": totalAmount,
        "address_id": addressId,
        "rider_id": riderId,
        "staff_id": staffId,
        "detergent_option": detergentOption,
        "before_wash_image": beforeWashImage,
        "note": note,
      };
}

// ── Response ─────────────────────────────────────────────────

ResCreateOrder resCreateOrderFromJson(String str) =>
    ResCreateOrder.fromJson(json.decode(str));

String resCreateOrderToJson(ResCreateOrder data) =>
    json.encode(data.toJson());

class ResCreateOrder {
  final bool ok;
  final String message;
  final String? orderId;

  ResCreateOrder({
    required this.ok,
    required this.message,
    this.orderId,
  });

  factory ResCreateOrder.fromJson(Map<String, dynamic> json) => ResCreateOrder(
        ok: json["ok"] as bool,
        message: json["message"] as String,
        orderId: json["order_id"] as String?,
      );

  Map<String, dynamic> toJson() => {
        "ok": ok,
        "message": message,
        "order_id": orderId,
      };
}