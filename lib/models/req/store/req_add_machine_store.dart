import 'dart:convert';

MachineRequest machineRequestFromJson(String str) => MachineRequest.fromJson(json.decode(str));
String machineRequestToJson(MachineRequest data) => json.encode(data.toJson());

class MachineRequest {
  final String storeId;
  final String name;
  final String type;
  final int capacity;
  final double price;
  final int workMinutes;
  final String status;

  MachineRequest({
    required this.storeId,
    required this.name,
    required this.type,
    required this.capacity,
    required this.price,
    required this.workMinutes,
    this.status = 'available',
  });

  factory MachineRequest.fromJson(Map<String, dynamic> json) {
    return MachineRequest(
      storeId: json['store_id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      capacity: json['capacity'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      workMinutes: json['work_minutes'] ?? 0,
      status: json['status'] ?? 'available',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'store_id': storeId,
      'name': name,
      'type': type,
      'capacity': capacity,
      'price': price,
      'work_minutes': workMinutes,
      'status': status,
    };
  }
}