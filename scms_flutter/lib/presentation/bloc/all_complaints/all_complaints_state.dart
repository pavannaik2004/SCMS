import '../../../data/models/complaint_model.dart';

/// Immutable snapshot of the filters applied to the global complaint feed.
/// A `null` field means "no filter on this dimension".
class AllComplaintsQuery {
  final String? status;
  final String? departmentId;
  final String? categoryId;
  final String? severity;
  final String? search;

  const AllComplaintsQuery({
    this.status,
    this.departmentId,
    this.categoryId,
    this.severity,
    this.search,
  });

  /// True when any filter other than free-text search is active.
  bool get hasActiveFacets =>
      status != null ||
      departmentId != null ||
      categoryId != null ||
      severity != null;

  /// Number of active facet filters (drives the "Filters (n)" badge).
  int get activeFacetCount =>
      (status != null ? 1 : 0) +
      (departmentId != null ? 1 : 0) +
      (categoryId != null ? 1 : 0) +
      (severity != null ? 1 : 0);
}

abstract class AllComplaintsState {
  final AllComplaintsQuery query;
  const AllComplaintsState(this.query);
}

class AllComplaintsInitial extends AllComplaintsState {
  const AllComplaintsInitial() : super(const AllComplaintsQuery());
}

class AllComplaintsLoading extends AllComplaintsState {
  const AllComplaintsLoading(super.query);
}

class AllComplaintsLoaded extends AllComplaintsState {
  final List<ComplaintModel> items;
  final bool hasMore;
  final bool loadingMore;

  const AllComplaintsLoaded({
    required this.items,
    required AllComplaintsQuery query,
    this.hasMore = false,
    this.loadingMore = false,
  }) : super(query);
}

class AllComplaintsError extends AllComplaintsState {
  final String message;
  const AllComplaintsError(this.message, AllComplaintsQuery query)
      : super(query);
}
