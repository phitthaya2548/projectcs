
import 'dart:convert';

UpdateStatusRequest updateStatusRequestFromJson(String str) =>
    UpdateStatusRequest.fromJson(json.decode(str));

String updateStatusRequestToJson(UpdateStatusRequest data) =>
    json.encode(data.toJson());

UpdateStatusResponse updateStatusResponseFromJson(String str) =>
    UpdateStatusResponse.fromJson(json.decode(str));

String updateStatusResponseToJson(UpdateStatusResponse data) =>
    json.encode(data.toJson());

class UpdateStatusRequest {
  final String staffId;
  final String status;

  const UpdateStatusRequest({
    required this.staffId,
    required this.status,
  });

  factory UpdateStatusRequest.fromJson(Map<String, dynamic> json) =>
      UpdateStatusRequest(
        staffId: json['staff_id'] ?? '',
        status: json['status'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'staff_id': staffId,
        'status': status,
      };
}

class UpdateStatusResponse {
  final bool ok;
  final String message;
  final Map<String, dynamic>? data;

  const UpdateStatusResponse({
    required this.ok,
    required this.message,
    this.data,
  });

  factory UpdateStatusResponse.fromJson(Map<String, dynamic> json) =>
      UpdateStatusResponse(
        ok: json['ok'] ?? false,
        message: json['message'] ?? '',
        data: json['data'] as Map<String, dynamic>?,
      );

  Map<String, dynamic> toJson() => {
        'ok': ok,
        'message': message,
        'data': data,
      };
}