abstract class ComplaintEvent {}

class LoadMyComplaints extends ComplaintEvent {
  final String? statusFilter;
  LoadMyComplaints({this.statusFilter});
}

class LoadComplaintDetail extends ComplaintEvent {
  final String complaintId;
  LoadComplaintDetail({required this.complaintId});
}

class FilterComplaints extends ComplaintEvent {
  final String? status;
  FilterComplaints({this.status});
}

class RefreshComplaints extends ComplaintEvent {}

class LoadAllComplaints extends ComplaintEvent {
  final String? status;
  final String? departmentId;
  final String? categoryId;
  final String? severity;
  final String? search;
  final int page;

  LoadAllComplaints({
    this.status, this.departmentId, this.categoryId,
    this.severity, this.search, this.page = 0,
  });
}
