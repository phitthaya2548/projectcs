import 'dart:convert';

StoreImage storeImageFromJson(String str) =>
    StoreImage.fromJson(json.decode(str));

String storeImageToJson(StoreImage data) =>
    json.encode(data.toJson());


List<StoreImage> storeImageListFromJson(String str) =>
    List<StoreImage>.from(json.decode(str).map((x) => StoreImage.fromJson(x)));

String storeImageListToJson(List<StoreImage> data) =>
    json.encode(data.map((x) => x.toJson()).toList());

class StoreImage {
  final String imageId;
  final String imagePath;

  const StoreImage({
    required this.imageId,
    required this.imagePath,
  });

  factory StoreImage.fromJson(Map<String, dynamic> json) => StoreImage(
        imageId: json['image_id'] ?? '',
        imagePath: json['image_path'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'image_id': imageId,
        'image_path': imagePath,
      };
}