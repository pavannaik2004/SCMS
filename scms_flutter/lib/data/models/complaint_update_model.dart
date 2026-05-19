class ComplaintUpdateModel {
  final String id;
  final String complaintId;
  final String updatedById;
  final String updatedByName;
  final String updatedByRole;
  final String previousStatus;
  final String newStatus;
  final String? notes;
  final DateTime timestamp;

  const ComplaintUpdateModel({
    required this.id,
    required this.complaintId,
    required this.updatedById,
    required this.updatedByName,
    required this.updatedByRole,
    required this.previousStatus,
    required this.newStatus,
    this.notes,
    required this.timestamp,
  });

  factory ComplaintUpdateModel.fromJson(Map<String, dynamic> json) {
    return ComplaintUpdateModel(
      id: json['id'] as String,
      complaintId: json['complaintId'] as String,
      updatedById: json['updatedById'] as String,
      updatedByName: json['updatedByName'] as String,
      updatedByRole: json['updatedByRole'] as String,
      previousStatus: json['previousStatus'] as String,
      newStatus: json['newStatus'] as String,
      notes: json['notes'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'complaintId': complaintId,
      'updatedById': updatedById,
      'updatedByName': updatedByName,
      'updatedByRole': updatedByRole,
      'previousStatus': previousStatus,
      'newStatus': newStatus,
      'notes': notes,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Icon for timeline display based on role
  String get timelineIcon {
    switch (updatedByRole.toUpperCase()) {
      case 'ROLE_ADMIN':
        return '👔';
      case 'ROLE_STAFF':
        return '🔧';
      case 'ROLE_SR':
        return '📋';
      case 'SYSTEM':
        return '🤖';
      default:
        return '👤';
    }
  }
}
