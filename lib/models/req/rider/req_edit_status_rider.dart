

import 'dart:convert';

class RiderStatusRequest {
  final String status;

  RiderStatusRequest({required this.status});

  Map<String, dynamic> toJson() => {'status': status};
}

String riderStatusRequestToJson(RiderStatusRequest request) =>
    json.encode(request.toJson());

class RiderStatusData {
  final String riderId;
  final String status;

  RiderStatusData({required this.riderId, required this.status});

  factory RiderStatusData.fromJson(Map<String, dynamic> json) =>
      RiderStatusData(
        riderId: json['rider_id']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
      );
}

class RiderStatusResponse {
  final bool ok;
  final String? message;
  final RiderStatusData? data;

  RiderStatusResponse({required this.ok, this.message, this.data});

  factory RiderStatusResponse.fromJson(Map<String, dynamic> json) =>
      RiderStatusResponse(
        ok: json['ok'] == true,
        message: json['message']?.toString(),
        data: json['data'] != null
            ? RiderStatusData.fromJson(json['data'] as Map<String, dynamic>)
            : null,
      );
}

RiderStatusResponse riderStatusResponseFromJson(String str) =>
    RiderStatusResponse.fromJson(json.decode(str) as Map<String, dynamic>);