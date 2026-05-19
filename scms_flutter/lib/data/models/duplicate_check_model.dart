class DuplicateCheckModel {
  final bool isDuplicate;
  final int similarCount;
  final DuplicateMatch? topMatch;
  final List<DuplicateMatch> allMatches;
  final String? groupId;

  const DuplicateCheckModel({
    required this.isDuplicate,
    this.similarCount = 0,
    this.topMatch,
    this.allMatches = const [],
    this.groupId,
  });

  factory DuplicateCheckModel.fromJson(Map<String, dynamic> json) {
    return DuplicateCheckModel(
      isDuplicate: json['isDuplicate'] as bool? ?? false,
      similarCount: json['similarCount'] as int? ?? 0,
      topMatch: json['topMatch'] != null
          ? DuplicateMatch.fromJson(json['topMatch'] as Map<String, dynamic>)
          : null,
      allMatches: (json['allMatches'] as List<dynamic>?)
              ?.map((m) => DuplicateMatch.fromJson(m as Map<String, dynamic>))
              .toList() ?? [],
      groupId: json['groupId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'isDuplicate': isDuplicate,
    'similarCount': similarCount,
    'topMatch': topMatch?.toJson(),
    'allMatches': allMatches.map((m) => m.toJson()).toList(),
    'groupId': groupId,
  };

  /// Safe default when AI service is unavailable
  factory DuplicateCheckModel.noDuplicates() {
    return const DuplicateCheckModel(isDuplicate: false, similarCount: 0);
  }
}

class DuplicateMatch {
  final String id;
  final String complaintNumber;
  final String title;
  final String status;
  final double score;

  const DuplicateMatch({
    required this.id,
    required this.complaintNumber,
    required this.title,
    required this.status,
    required this.score,
  });

  factory DuplicateMatch.fromJson(Map<String, dynamic> json) {
    return DuplicateMatch(
      id: json['id'] as String,
      complaintNumber: json['complaintNumber'] as String,
      title: json['title'] as String,
      status: json['status'] as String,
      score: (json['score'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'complaintNumber': complaintNumber,
    'title': title, 'status': status, 'score': score,
  };

  /// Similarity percentage for display
  String get similarityPercent => '${(score * 100).toStringAsFixed(0)}%';
}
