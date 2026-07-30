import 'dart:convert';

String submitReviewToJson(SubmitReviewRequest data) =>
    json.encode(data.toJson());

class SubmitReviewRequest {
  final int rating;
  final String? comment;

  SubmitReviewRequest({
    required this.rating,
    this.comment,
  });

  Map<String, dynamic> toJson() => {
        'rating': rating,
        'comment': comment,
      };
}