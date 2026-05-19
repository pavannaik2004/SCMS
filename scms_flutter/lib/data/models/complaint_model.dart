import 'complaint_update_model.dart';

class ComplaintModel {
  final String id;
  final String complaintNumber;
  final String subject;
  final String description;
  final String location;
  final double? gpsLatitude;
  final double? gpsLongitude;
  final String? gpsPlaceName;
  final String categoryId;
  final String categoryName;
  final String departmentId;
  final String departmentName;
  final String severity; // HIGH | MEDIUM | LOW
  final String status; // PENDING_SR_REVIEW | OPEN | ASSIGNED | IN_PROGRESS | RESOLVED | CLOSED | REJECTED
  final List<String> tags;
  final String submittedById;
  final String submittedByName;
  final String? assignedToId;
  final String? assignedToName;
  final String? reviewedBySrId;
  final String? srRejectionCause;
  final List<String> photoUrls;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? slaDeadline;
  final bool isSlaBreached;
  final bool isGrammarCorrected;
  final bool isAiCategorized;
  final double? aiConfidenceScore;
  final String? duplicateGroupId;
  final double? rating;
  final String? ratingComment;
  final List<ComplaintUpdateModel> updates;

  const ComplaintModel({
    required this.id,
    required this.complaintNumber,
    required this.subject,
    required this.description,
    required this.location,
    this.gpsLatitude,
    this.gpsLongitude,
    this.gpsPlaceName,
    required this.categoryId,
    required this.categoryName,
    required this.departmentId,
    required this.departmentName,
    required this.severity,
    required this.status,
    this.tags = const [],
    required this.submittedById,
    required this.submittedByName,
    this.assignedToId,
    this.assignedToName,
    this.reviewedBySrId,
    this.srRejectionCause,
    this.photoUrls = const [],
    required this.createdAt,
    required this.updatedAt,
    this.slaDeadline,
    this.isSlaBreached = false,
    this.isGrammarCorrected = false,
    this.isAiCategorized = false,
    this.aiConfidenceScore,
    this.duplicateGroupId,
    this.rating,
    this.ratingComment,
    this.updates = const [],
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      id: json['id'] as String,
      complaintNumber: json['complaintNumber'] as String? ?? '',
      subject: json['subject'] as String? ?? json['title'] as String? ?? '',
      description: json['description'] as String,
      location: json['location'] as String,
      gpsLatitude: (json['gpsLatitude'] as num?)?.toDouble(),
      gpsLongitude: (json['gpsLongitude'] as num?)?.toDouble(),
      gpsPlaceName: json['gpsPlaceName'] as String?,
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String? ?? '',
      departmentId: json['departmentId'] as String,
      departmentName: json['departmentName'] as String? ?? '',
      severity: json['severity'] as String,
      status: json['status'] as String,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      submittedById: json['submittedById'] as String,
      submittedByName: json['submittedByName'] as String? ?? '',
      assignedToId: json['assignedToId'] as String?,
      assignedToName: json['assignedToName'] as String?,
      reviewedBySrId: json['reviewedBySrId'] as String?,
      srRejectionCause: json['srRejectionCause'] as String?,
      photoUrls: (json['photoUrls'] as List<dynamic>?)?.cast<String>() ??
          (json['mediaItems'] as List<dynamic>?)
              ?.map((m) => m['url'] as String)
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      slaDeadline: json['slaDeadline'] != null
          ? DateTime.parse(json['slaDeadline'] as String)
          : null,
      isSlaBreached: json['isSlaBreached'] as bool? ?? false,
      isGrammarCorrected: json['isGrammarCorrected'] as bool? ?? false,
      isAiCategorized: json['isAiCategorized'] as bool? ?? false,
      aiConfidenceScore: (json['aiConfidenceScore'] as num?)?.toDouble(),
      duplicateGroupId: json['duplicateGroupId'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      ratingComment: json['ratingComment'] as String?,
      updates: (json['updates'] as List<dynamic>?)
              ?.map((u) => ComplaintUpdateModel.fromJson(u as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'complaintNumber': complaintNumber,
      'subject': subject,
      'description': description,
      'location': location,
      'gpsLatitude': gpsLatitude,
      'gpsLongitude': gpsLongitude,
      'gpsPlaceName': gpsPlaceName,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'departmentId': departmentId,
      'departmentName': departmentName,
      'severity': severity,
      'status': status,
      'tags': tags,
      'submittedById': submittedById,
      'submittedByName': submittedByName,
      'assignedToId': assignedToId,
      'assignedToName': assignedToName,
      'reviewedBySrId': reviewedBySrId,
      'srRejectionCause': srRejectionCause,
      'photoUrls': photoUrls,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'slaDeadline': slaDeadline?.toIso8601String(),
      'isSlaBreached': isSlaBreached,
      'isGrammarCorrected': isGrammarCorrected,
      'isAiCategorized': isAiCategorized,
      'aiConfidenceScore': aiConfidenceScore,
      'duplicateGroupId': duplicateGroupId,
      'rating': rating,
      'ratingComment': ratingComment,
      'updates': updates.map((u) => u.toJson()).toList(),
    };
  }

  ComplaintModel copyWith({
    String? status,
    String? assignedToId,
    String? assignedToName,
    double? rating,
    String? ratingComment,
    List<ComplaintUpdateModel>? updates,
    bool? isSlaBreached,
  }) {
    return ComplaintModel(
      id: id,
      complaintNumber: complaintNumber,
      subject: subject,
      description: description,
      location: location,
      gpsLatitude: gpsLatitude,
      gpsLongitude: gpsLongitude,
      gpsPlaceName: gpsPlaceName,
      categoryId: categoryId,
      categoryName: categoryName,
      departmentId: departmentId,
      departmentName: departmentName,
      severity: severity,
      status: status ?? this.status,
      tags: tags,
      submittedById: submittedById,
      submittedByName: submittedByName,
      assignedToId: assignedToId ?? this.assignedToId,
      assignedToName: assignedToName ?? this.assignedToName,
      reviewedBySrId: reviewedBySrId,
      srRejectionCause: srRejectionCause,
      photoUrls: photoUrls,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      slaDeadline: slaDeadline,
      isSlaBreached: isSlaBreached ?? this.isSlaBreached,
      isGrammarCorrected: isGrammarCorrected,
      isAiCategorized: isAiCategorized,
      aiConfidenceScore: aiConfidenceScore,
      duplicateGroupId: duplicateGroupId,
      rating: rating ?? this.rating,
      ratingComment: ratingComment ?? this.ratingComment,
      updates: updates ?? this.updates,
    );
  }

  /// Whether the complaint can be rated
  bool get canRate => status == 'RESOLVED' && rating == null;

  /// Whether SLA is active (not breached yet, complaint is open)
  bool get isSlaActive =>
      slaDeadline != null &&
      !isSlaBreached &&
      !['RESOLVED', 'CLOSED', 'REJECTED'].contains(status);
}
