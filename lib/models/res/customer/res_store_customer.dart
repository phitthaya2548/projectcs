class Store {
  final String id;
  final String name;
  final String image;
  final double rating;
  final double distance;
  final String opening;
  final String status;

  Store({
    required this.id,
    required this.name,
    required this.image,
    required this.rating,
    required this.distance,
    required this.opening,
    required this.status,
  });

  bool get isOpen => status == 'เปิดร้าน';

 factory Store.fromJson(Map<String, dynamic> j) {
    return Store(
      id: j["store_id"],
      name: j["store_name"] ?? "",
      image: j["profile_image"] ?? "",
      rating: (j["rating"] ?? 0).toDouble(),
      distance: (j["distance_km"] ?? 0).toDouble(),
      opening: j["opening"] ?? "",
      status: j["status"] ?? "TEMP_CLOSSED",
    );
  }
}