
enum MachineStatus {
  available,
  busy,
  maintenance,
}

class Machine {
  final String machineId;
  final String name;
  final String type;
  final int capacity;
  final double price;
  final int workMinutes;
  final MachineStatus status;

  Machine({
    required this.machineId,
    required this.name,
    required this.type,
    required this.capacity,
    required this.price,
    required this.workMinutes,
    required this.status,
  });

  factory Machine.fromJson(Map<String, dynamic> json) {
    return Machine(
      machineId: json['machine_id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      capacity: json['capacity'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      workMinutes: json['work_minutes'] ?? 0,
      status: MachineStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MachineStatus.available,
      ),
    );
  }
}

class MachineListResponse {
  final bool ok;
  final int count;
  final List<Machine> data;

  MachineListResponse({
    required this.ok,
    required this.count,
    required this.data,
  });

  factory MachineListResponse.fromJson(Map<String, dynamic> json) {
    final machines = (json['data'] as List<dynamic>?)
            ?.map((item) => Machine.fromJson(item))
            .toList() ??
        [];

    return MachineListResponse(
      ok: json['ok'] ?? false,
      count: json['count'] ?? machines.length,
      data: machines,
    );
  }
}