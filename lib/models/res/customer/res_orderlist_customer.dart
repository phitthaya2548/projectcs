class OrderItem {
  final String orderId;
  final String serviceType;
  final String customerFullname;
  final String customerPhone;
  final String addressFull;
  final Map<String, dynamic>? orderDatetime;
  final String initialStatus;
  final bool isReviewed; // <-- เพิ่ม

  const OrderItem({
    required this.orderId,
    required this.serviceType,
    required this.customerFullname,
    required this.customerPhone,
    required this.addressFull,
    required this.orderDatetime,
    required this.initialStatus,
    required this.isReviewed,
  });

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
    orderId: j['order_id'] as String? ?? '',
    serviceType: j['service_type'] as String? ?? '',
    customerFullname: j['customer_fullname'] as String? ?? '-',
    customerPhone: j['customer_phone'] as String? ?? '-',
    addressFull: j['address_full'] as String? ?? '-',
    orderDatetime: j['order_datetime'] as Map<String, dynamic>?,

    initialStatus: j['status'] as String? ?? '',
    isReviewed: j['is_reviewed'] as bool? ?? false,
  );
}