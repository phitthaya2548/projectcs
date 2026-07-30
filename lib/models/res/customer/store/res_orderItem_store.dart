class StoreOrderItem {
  final String orderId;
  final String customerFullname;
  final String customerPhone;
  final String addressFull;
  final String serviceType;
  final String initialStatus;
  final Map<String, dynamic>? orderDatetime;

  const StoreOrderItem({
    required this.orderId,
    required this.customerFullname,
    required this.customerPhone,
    required this.addressFull,
    required this.serviceType,
    required this.initialStatus,
    this.orderDatetime,
  });

  factory StoreOrderItem.fromJson(Map<String, dynamic> json) {
    return StoreOrderItem(
      orderId: json['order_id'] as String? ?? '',
      customerFullname: json['customer_fullname'] as String? ?? '',
      customerPhone: json['customer_phone'] as String? ?? '',
      addressFull: json['address_full'] as String? ?? '',
      serviceType: json['service_type'] as String? ?? '',
      initialStatus: json['status'] as String? ?? '',
      orderDatetime: json['order_datetime'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'order_id': orderId,
        'customer_fullname': customerFullname,
        'customer_phone': customerPhone,
        'address_full': addressFull,
        'service_type': serviceType,
        'status': initialStatus,
        'order_datetime': orderDatetime,
      };
}