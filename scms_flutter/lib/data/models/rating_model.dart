class RatingModel {
  final double rating;
  final String? comment;

  const RatingModel({required this.rating, this.comment});

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    return RatingModel(
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {'rating': rating, 'comment': comment};
}
