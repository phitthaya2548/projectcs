// models/req_accept_rider.dart
import 'dart:convert';

AcceptOrderRequest acceptOrderRequestFromJson(String str) =>
    AcceptOrderRequest.fromJson(json.decode(str));

String acceptOrderRequestToJson(AcceptOrderRequest data) =>
    json.encode(data.toJson());

AcceptOrderResponse acceptOrderResponseFromJson(String str) =>
    AcceptOrderResponse.fromJson(json.decode(str));

String acceptOrderResponseToJson(AcceptOrderResponse data) =>
    json.encode(data.toJson());

class AcceptOrderRequest {
  final String riderId;

  const AcceptOrderRequest({required this.riderId});

  factory AcceptOrderRequest.fromJson(Map<String, dynamic> json) =>
      AcceptOrderRequest(riderId: json['rider_id'] as String);

  Map<String, dynamic> toJson() => {'rider_id': riderId};
}

class AcceptOrderResponse {
  final bool ok;
  final String message;

  const AcceptOrderResponse({required this.ok, required this.message});

  factory AcceptOrderResponse.fromJson(Map<String, dynamic> json) =>
      AcceptOrderResponse(
        ok:      json['ok']      as bool,
        message: json['message'] as String,
      );

  Map<String, dynamic> toJson() => {'ok': ok, 'message': message};
}