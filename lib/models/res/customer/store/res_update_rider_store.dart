import 'dart:convert';
import 'package:wash_and_dry/models/res/customer/store/res_rider_detail_store.dart';


UpdateRiderResponse updateRiderResponseFromJson(String str) =>
    UpdateRiderResponse.fromJson(json.decode(str));

String updateRiderResponseToJson(UpdateRiderResponse data) =>
    json.encode(data.toJson());

class UpdateRiderResponse {
  final bool ok;
  final String? message;
  final RiderDetail? data;

  UpdateRiderResponse({
    required this.ok,
    this.message,
    this.data,
  });

  factory UpdateRiderResponse.fromJson(Map<String, dynamic> json) {
    return UpdateRiderResponse(
      ok: json['ok'] ?? false,
      message: json['message']?.toString(),
      data: json['data'] != null ? RiderDetail.fromJson(json['data']) : null,
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