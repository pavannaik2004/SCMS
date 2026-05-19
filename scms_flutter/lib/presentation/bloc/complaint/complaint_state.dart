import '../../../data/models/complaint_model.dart';

abstract class ComplaintState {}

class ComplaintInitial extends ComplaintState {}

class ComplaintLoading extends ComplaintState {}

class MyComplaintsLoaded extends ComplaintState {
  final List<ComplaintModel> complaints;
  final String? activeFilter;

  MyComplaintsLoaded({required this.complaints, this.activeFilter});
}

class ComplaintDetailLoaded extends ComplaintState {
  final ComplaintModel complaint;
  ComplaintDetailLoaded({required this.complaint});
}

class AllComplaintsLoaded extends ComplaintState {
  final List<ComplaintModel> complaints;
  final int currentPage;
  final bool hasMore;

  AllComplaintsLoaded({
    required this.complaints,
    this.currentPage = 0,
    this.hasMore = true,
  });
}

class ComplaintError extends ComplaintState {
  final String message;
  ComplaintError({required this.message});
}
