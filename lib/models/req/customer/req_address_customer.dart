import 'dart:convert';

Address addressFromJson(String str) =>
    Address.fromJson(json.decode(str));

String addressToJson(Address data) =>
    json.encode(data.toJson());

class Address {
  final String? id;
  final String addressName;
  final String addressText;
  final double latitude;
  final double longitude;
  final bool status;

  Address({
    this.id,
    required this.addressName,
    required this.addressText,
    required this.latitude,
    required this.longitude,
    required this.status,
  });

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        id: json["address_id"]?.toString(),
        addressName: json["address_name"] ?? "",
        addressText: json["address_text"] ?? "",
        latitude: (json["latitude"] as num?)?.toDouble() ?? 0.0,
        longitude: (json["longitude"] as num?)?.toDouble() ?? 0.0,
        status: json["status"] ?? false,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) "address_id": id,
        "address_name": addressName,
        "address_text": addressText,
        "latitude": latitude,
        "longitude": longitude,
        "status": status,
      };

  Address copyWith({
    String? id,
    String? addressName,
    String? addressText,
    double? latitude,
    double? longitude,
    bool? status,
  }) {
    return Address(
      id: id ?? this.id,
      addressName: addressName ?? this.addressName,
      addressText: addressText ?? this.addressText,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
    );
  }
}