class SrReviewModel {
  final String complaintId;
  final String action; // APPROVE | REJECT
  final String? rejectionCause;

  const SrReviewModel({
    required this.complaintId,
    required this.action,
    this.rejectionCause,
  });

  factory SrReviewModel.fromJson(Map<String, dynamic> json) {
    return SrReviewModel(
      complaintId: json['complaintId'] as String,
      action: json['action'] as String,
      rejectionCause: json['rejectionCause'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'complaintId': complaintId,
    'action': action,
    'rejectionCause': rejectionCause,
  };
}
