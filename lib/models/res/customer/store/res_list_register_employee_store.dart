class StoreListResponse {
  final bool ok;
  final int total;
  final List<StoreListItem> data;
  final String? message;

  StoreListResponse({
    required this.ok,
    required this.total,
    required this.data,
    this.message,
  });

  factory StoreListResponse.fromJson(Map<String, dynamic> json) {
    return StoreListResponse(
      ok: json['ok'] as bool? ?? false,
      total: json['total'] as int? ?? 0,
      data: (json['data'] as List<dynamic>? ?? [])
          .map((e) => StoreListItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      message: json['message'] as String?,
    );
  }
}

class StoreImageItem {
  final String imageId;
  final String imagePath;

  const StoreImageItem({
    required this.imageId,
    required this.imagePath,
  });

  factory StoreImageItem.fromJson(Map<String, dynamic> json) {
    return StoreImageItem(
      imageId: json['image_id']?.toString() ?? '',
      imagePath: json['image_path']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'image_id': imageId,
      'image_path': imagePath,
    };
  }
}

class StoreReviewItem {
  final String reviewId;
  final String comment;
  final double rating;
  final DateTime? reviewedAt;
  final String reviewerName;
  final String reviewerImage;

  const StoreReviewItem({
    required this.reviewId,
    required this.comment,
    required this.rating,
    this.reviewedAt,
    this.reviewerName = '',
    this.reviewerImage = '',
  });

  factory StoreReviewItem.fromJson(Map<String, dynamic> json) {
    return StoreReviewItem(
      reviewId: json['review_id']?.toString() ?? '',
      comment: json['comment']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.tryParse(json['reviewed_at'].toString())
          : null,
      reviewerName: json['reviewer_name']?.toString() ?? '',
      reviewerImage: json['reviewer_image']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'review_id': reviewId,
      'comment': comment,
      'rating': rating,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'reviewer_name': reviewerName,
      'reviewer_image': reviewerImage,
    };
  }
}

class StoreListItem {
  final String storeId;
  final String storeName;
  final String phone;
  final String email;
  final String facebook;
  final String lineId;
  final String address;
  final double latitude;
  final double longitude;
  final double serviceRadius;
  final String openingHours;
  final String closedHours;
  final double deliveryMin;
  final double deliveryMax;
  final String profileImage;
  final String status;
  final bool isHiring;
  final DateTime? updatedAt;
  final int totalImages;
  final List<StoreImageItem> images;
  final int totalReviews;
  final double avgRating;
  final List<StoreReviewItem> reviews;

  const StoreListItem({
    required this.storeId,
    required this.storeName,
    required this.phone,
    required this.email,
    required this.facebook,
    required this.lineId,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.serviceRadius,
    required this.openingHours,
    required this.closedHours,
    required this.deliveryMin,
    required this.deliveryMax,
    required this.profileImage,
    required this.status,
    this.isHiring = false,
    this.updatedAt,
    this.totalImages = 0,
    this.images = const [],
    this.totalReviews = 0,
    this.avgRating = 0,
    this.reviews = const [],
  });

  factory StoreListItem.fromJson(Map<String, dynamic> json) {
    return StoreListItem(
      storeId: json['store_id']?.toString() ?? '',
      storeName: json['store_name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      facebook: json['facebook']?.toString() ?? '',
      lineId: json['line_id']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      serviceRadius: (json['service_radius'] as num?)?.toDouble() ?? 0,
      openingHours: json['opening_hours']?.toString() ?? '',
      closedHours: json['closed_hours']?.toString() ?? '',
      deliveryMin: (json['delivery_min'] as num?)?.toDouble() ?? 0,
      deliveryMax: (json['delivery_max'] as num?)?.toDouble() ?? 0,
      profileImage: json['profile_image']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      isHiring: json['is_hiring'] as bool? ?? false,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      totalImages: json['total_images'] as int? ?? 0,
      images: (json['images'] as List<dynamic>? ?? [])
          .map((e) => StoreImageItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalReviews: json['total_reviews'] as int? ?? 0,
      avgRating: (json['avg_rating'] as num?)?.toDouble() ?? 0,
      reviews: (json['reviews'] as List<dynamic>? ?? [])
          .map((e) => StoreReviewItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'store_id': storeId,
      'store_name': storeName,
      'phone': phone,
      'email': email,
      'facebook': facebook,
      'line_id': lineId,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'service_radius': serviceRadius,
      'opening_hours': openingHours,
      'closed_hours': closedHours,
      'delivery_min': deliveryMin,
      'delivery_max': deliveryMax,
      'profile_image': profileImage,
      'status': status,
      'is_hiring': isHiring,
      'updated_at': updatedAt?.toIso8601String(),
      'total_images': totalImages,
      'images': images.map((e) => e.toJson()).toList(),
      'total_reviews': totalReviews,
      'avg_rating': avgRating,
      'reviews': reviews.map((e) => e.toJson()).toList(),
    };
  }
}