class UpdateLaundryStaffRequest {
  final String email;
  final String fullname;
  final String phone;

  UpdateLaundryStaffRequest({
    required this.email,
    required this.fullname,
    required this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'fullname': fullname,
      'phone': phone,
    };
  }
}