import 'dart:convert';

StoreReviewsResponse storeReviewsFromJson(String str) =>
    StoreReviewsResponse.fromJson(json.decode(str)['data']);

class StoreReviewsResponse {
  final double avgRating;
  final int reviewCount;
  final List<ReviewItem> reviews;

  StoreReviewsResponse({
    required this.avgRating,
    required this.reviewCount,
    required this.reviews,
  });

  factory StoreReviewsResponse.fromJson(Map<String, dynamic> json) =>
      StoreReviewsResponse(
        avgRating: (json['avg_rating'] ?? 0).toDouble(),
        reviewCount: json['review_count'] ?? 0,
        reviews: (json['reviews'] as List<dynamic>? ?? [])
            .map((e) => ReviewItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class ReviewItem {
  final String reviewId;
  final int rating;
  final String? comment;
  final DateTime? reviewedAt;
  final String customerFullname;
  final String customerProfileImage;

  ReviewItem({
    required this.reviewId,
    required this.rating,
    this.comment,
    this.reviewedAt,
    required this.customerFullname,
    required this.customerProfileImage,
  });

 factory ReviewItem.fromJson(Map<String, dynamic> json) => ReviewItem(
      reviewId: json['review_id'] ?? '',
      rating: json['rating'] ?? 0,
      comment: json['comment'] as String?,
      reviewedAt: json['reviewed_at'] != null
          ? (json['reviewed_at'] is String
              ? DateTime.parse(json['reviewed_at'])
              : DateTime.fromMillisecondsSinceEpoch(
                  ((json['reviewed_at']['_seconds'] as num) * 1000).toInt()))
          : null,
      customerFullname: json['reviewer_name'] ?? 'ผู้ใช้ไม่ระบุชื่อ',
      customerProfileImage: json['reviewer_image'] ?? '',
    );
}