import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failures.dart';
import '../../../data/repositories/complaint_repository.dart';
import 'complaint_event.dart';
import 'complaint_state.dart';

class ComplaintBloc extends Bloc<ComplaintEvent, ComplaintState> {
  final ComplaintRepository _repository;

  ComplaintBloc({required ComplaintRepository repository})
      : _repository = repository,
        super(ComplaintInitial()) {
    on<LoadMyComplaints>(_onLoadMyComplaints);
    on<LoadComplaintDetail>(_onLoadDetail);
    on<FilterComplaints>(_onFilter);
    on<RefreshComplaints>(_onRefresh);
    on<LoadAllComplaints>(_onLoadAll);
  }

  String? _lastFilter;

  Future<void> _onLoadMyComplaints(LoadMyComplaints event, Emitter<ComplaintState> emit) async {
    emit(ComplaintLoading());
    _lastFilter = event.statusFilter;
    try {
      final complaints = await _repository.getMyComplaints(status: event.statusFilter);
      emit(MyComplaintsLoaded(complaints: complaints, activeFilter: event.statusFilter));
    } on Failure catch (e) {
      emit(ComplaintError(message: e.message));
    }
  }

  Future<void> _onLoadDetail(LoadComplaintDetail event, Emitter<ComplaintState> emit) async {
    emit(ComplaintLoading());
    try {
      final complaint = await _repository.getComplaintById(event.complaintId);
      emit(ComplaintDetailLoaded(complaint: complaint));
    } on Failure catch (e) {
      emit(ComplaintError(message: e.message));
    }
  }

  Future<void> _onFilter(FilterComplaints event, Emitter<ComplaintState> emit) async {
    add(LoadMyComplaints(statusFilter: event.status));
  }

  Future<void> _onRefresh(RefreshComplaints event, Emitter<ComplaintState> emit) async {
    add(LoadMyComplaints(statusFilter: _lastFilter));
  }

  Future<void> _onLoadAll(LoadAllComplaints event, Emitter<ComplaintState> emit) async {
    emit(ComplaintLoading());
    try {
      final complaints = await _repository.getAllComplaints(
        status: event.status,
        departmentId: event.departmentId,
        categoryId: event.categoryId,
        severity: event.severity,
        search: event.search,
        page: event.page,
      );
      emit(AllComplaintsLoaded(
        complaints: complaints,
        currentPage: event.page,
        hasMore: complaints.length >= 10,
      ));
    } on Failure catch (e) {
      emit(ComplaintError(message: e.message));
    }
  }
}
