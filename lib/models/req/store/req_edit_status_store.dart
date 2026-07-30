import 'dart:convert';


StoreStatusRequest storeStatusRequestFromJson(String str) =>
    StoreStatusRequest.fromJson(json.decode(str));

String storeStatusRequestToJson(StoreStatusRequest data) =>
    json.encode(data.toJson());

class StoreStatusRequest {
  final String status;

  const StoreStatusRequest({
    required this.status,
  });

  factory StoreStatusRequest.fromJson(Map<String, dynamic> json) {
    return StoreStatusRequest(
      status: json["status"] ?? "",
    );
  }

  Map<String, dynamic> toJson() => {
        "status": status,
      };
}


StoreStatusResponse storeStatusResponseFromJson(String str) =>
    StoreStatusResponse.fromJson(json.decode(str));

String storeStatusResponseToJson(StoreStatusResponse data) =>
    json.encode(data.toJson());

class StoreStatusResponse {
  final bool ok;
  final String message;
  final StoreStatusData? data;

  const StoreStatusResponse({
    required this.ok,
    required this.message,
    this.data,
  });

  factory StoreStatusResponse.fromJson(Map<String, dynamic> json) {
    return StoreStatusResponse(
      ok: json["ok"] ?? false,
      message: json["message"] ?? "",
      data: json["data"] != null
          ? StoreStatusData.fromJson(json["data"])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        "ok": ok,
        "message": message,
        "data": data?.toJson(),
      };
}

class StoreStatusData {
  final String storeId;
  final String status;

  const StoreStatusData({
    required this.storeId,
    required this.status,
  });

  factory StoreStatusData.fromJson(Map<String, dynamic> json) {
    return StoreStatusData(
      storeId: json["store_id"] ?? "",
      status: json["status"] ?? "",
    );
  }

  Map<String, dynamic> toJson() => {
        "store_id": storeId,
        "status": status,
      };
}