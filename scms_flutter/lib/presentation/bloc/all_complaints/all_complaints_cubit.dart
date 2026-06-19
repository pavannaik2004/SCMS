import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failures.dart';
import '../../../data/models/complaint_model.dart';
import '../../../data/repositories/complaint_repository.dart';
import 'all_complaints_state.dart';

/// Drives the read-only, system-wide "All Complaints" explore feed shared by
/// every role. Kept separate from [ComplaintBloc] (which owns the per-role
/// "my/assigned" lists) so applying filters here never disturbs the dashboards.
///
/// Owns pagination + the current [AllComplaintsQuery]; the page only pushes a
/// new query or asks for the next page.
class AllComplaintsCubit extends Cubit<AllComplaintsState> {
  final ComplaintRepository _repository;

  /// Page size mirrors the datasource default (`size: 20`), used to decide
  /// whether another page might exist.
  static const int _pageSize = 20;

  AllComplaintsQuery _query = const AllComplaintsQuery();
  final List<ComplaintModel> _items = [];
  int _page = 0;
  bool _hasMore = true;

  AllComplaintsCubit({required ComplaintRepository repository})
      : _repository = repository,
        super(const AllComplaintsInitial());

  /// Replace the active filter set and reload from the first page.
  Future<void> setQuery(AllComplaintsQuery query) async {
    _query = query;
    await _reload();
  }

  /// Reload the current query (pull-to-refresh / retry).
  Future<void> refresh() => _reload();

  Future<void> _reload() async {
    _page = 0;
    _hasMore = true;
    _items.clear();
    emit(AllComplaintsLoading(_query));
    await _fetch();
  }

  /// Fetch the next page and append, if more results may exist.
  Future<void> loadMore() async {
    final current = state;
    if (current is! AllComplaintsLoaded) return;
    if (!_hasMore || current.loadingMore) return;

    emit(AllComplaintsLoaded(
      items: List.of(_items),
      query: _query,
      hasMore: _hasMore,
      loadingMore: true,
    ));
    _page += 1;
    await _fetch(append: true);
  }

  Future<void> _fetch({bool append = false}) async {
    try {
      final batch = await _repository.getAllComplaints(
        status: _query.status,
        departmentId: _query.departmentId,
        categoryId: _query.categoryId,
        severity: _query.severity,
        search: _query.search,
        page: _page,
      );
      _items.addAll(batch);
      _hasMore = batch.length >= _pageSize;
      emit(AllComplaintsLoaded(
        items: List.of(_items),
        query: _query,
        hasMore: _hasMore,
        loadingMore: false,
      ));
    } on Failure catch (e) {
      if (append) {
        // Keep what we already have; just stop the spinner.
        _page -= 1;
        emit(AllComplaintsLoaded(
          items: List.of(_items),
          query: _query,
          hasMore: _hasMore,
          loadingMore: false,
        ));
      } else {
        emit(AllComplaintsError(e.message, _query));
      }
    } catch (_) {
      if (!append) {
        emit(AllComplaintsError('Failed to load complaints.', _query));
      }
    }
  }
}
