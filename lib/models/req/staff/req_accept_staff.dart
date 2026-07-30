// models/req_start_wash_staff.dart
import 'dart:convert';

StartWashRequest startWashRequestFromJson(String str) =>
    StartWashRequest.fromJson(json.decode(str));

String startWashRequestToJson(StartWashRequest data) =>
    json.encode(data.toJson());

StartWashResponse startWashResponseFromJson(String str) =>
    StartWashResponse.fromJson(json.decode(str));

String startWashResponseToJson(StartWashResponse data) =>
    json.encode(data.toJson());

class StartWashRequest {
  final String staffId;

  const StartWashRequest({required this.staffId});

  factory StartWashRequest.fromJson(Map<String, dynamic> json) =>
      StartWashRequest(staffId: json['staff_id'] as String);

  Map<String, dynamic> toJson() => {'staff_id': staffId};
}

class StartWashResponse {
  final bool ok;
  final String message;

  const StartWashResponse({required this.ok, required this.message});

  factory StartWashResponse.fromJson(Map<String, dynamic> json) =>
      StartWashResponse(
        ok:      json['ok']      as bool,
        message: json['message'] as String,
      );

  Map<String, dynamic> toJson() => {'ok': ok, 'message': message};
}