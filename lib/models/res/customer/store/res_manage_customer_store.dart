
class Customer {
  final String customerId;
  final String fullname;
  final String email;
  final String phone;
  final String profileImage;

  Customer({
    required this.customerId,
    required this.fullname,
    required this.email,
    required this.phone,
    required this.profileImage,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      customerId: json['customer_id'] ?? '',
      fullname: json['fullname'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      profileImage: json['profile_image'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'fullname': fullname,
      'email': email,
      'phone': phone,
      'profile_image': profileImage,
    };
  }
}

class StoreCustomersResponse {
  final bool ok;
  final int count;
  final List<Customer> data;
  final String? message;

  StoreCustomersResponse({
    required this.ok,
    this.count = 0,
    this.data = const [],
    this.message,
  });

  factory StoreCustomersResponse.fromJson(Map<String, dynamic> json) {
    return StoreCustomersResponse(
      ok: json['ok'] ?? false,
      count: json['count'] ?? 0,
      data: json['data'] != null
          ? List<Customer>.from(
              (json['data'] as List).map((x) => Customer.fromJson(x)))
          : [],
      message: json['message'],
    );
  }
}