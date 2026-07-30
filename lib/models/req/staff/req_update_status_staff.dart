import 'dart:convert';

StaffStatusRequest staffStatusRequestFromJson(String str) =>
    StaffStatusRequest.fromJson(json.decode(str));

String staffStatusRequestToJson(StaffStatusRequest data) =>
    json.encode(data.toJson());

StaffStatusResponse staffStatusResponseFromJson(String str) =>
    StaffStatusResponse.fromJson(json.decode(str));

String staffStatusResponseToJson(StaffStatusResponse data) =>
    json.encode(data.toJson());

class StaffStatusRequest {
  final String status;

  const StaffStatusRequest({
    required this.status,
  });

  factory StaffStatusRequest.fromJson(Map<String, dynamic> json) =>
      StaffStatusRequest(
        status: json['status'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'status': status,
      };
}

class StaffStatusData {
  final String staffId;
  final String status;

  const StaffStatusData({
    required this.staffId,
    required this.status,
  });

  factory StaffStatusData.fromJson(Map<String, dynamic> json) =>
      StaffStatusData(
        staffId: json['staff_id']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'staff_id': staffId,
        'status': status,
      };
}

class StaffStatusResponse {
  final bool ok;
  final String? message;
  final StaffStatusData? data;

  const StaffStatusResponse({
    required this.ok,
    this.message,
    this.data,
  });

  factory StaffStatusResponse.fromJson(Map<String, dynamic> json) =>
      StaffStatusResponse(
        ok: json['ok'] == true,
        message: json['message']?.toString(),
        data: json['data'] != null
            ? StaffStatusData.fromJson(json['data'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'ok': ok,
        'message': message,
        'data': data?.toJson(),
      };
}