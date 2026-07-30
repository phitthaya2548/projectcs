import 'dart:convert';
import 'package:wash_and_dry/models/res/customer/store/res_laundry_staff_detail_store.dart';

UpdateLaundryStaffResponse updateLaundryStaffResponseFromJson(String str) =>
    UpdateLaundryStaffResponse.fromJson(json.decode(str));

String updateLaundryStaffResponseToJson(UpdateLaundryStaffResponse data) =>
    json.encode(data.toJson());

class UpdateLaundryStaffResponse {
  final bool ok;
  final String? message;
  final LaundryStaffDetail? data;

  UpdateLaundryStaffResponse({
    required this.ok,
    this.message,
    this.data,
  });

  factory UpdateLaundryStaffResponse.fromJson(Map<String, dynamic> json) {
    return UpdateLaundryStaffResponse(
      ok: json['ok'] ?? false,
      message: json['message']?.toString(),
      data: json['data'] != null
          ? LaundryStaffDetail.fromJson(json['data'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ok': ok,
      'message': message,
      'data': data?.toJson(),
    };
  }
}