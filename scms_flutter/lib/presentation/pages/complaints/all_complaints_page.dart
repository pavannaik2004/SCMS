import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/department_model.dart';
import '../../../data/repositories/complaint_repository.dart';
import '../../bloc/all_complaints/all_complaints_cubit.dart';
import '../../bloc/all_complaints/all_complaints_state.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/gradient_app_bar.dart';
import '../../widgets/common/scms_chip.dart';
import '../../widgets/complaint/complaint_card.dart';

/// Read-only, system-wide complaint feed available to every role.
///
/// Self-contained: it provides its own [AllComplaintsCubit] so it works both as
/// a tab inside the role shell and as a pushed route (e.g. a drill-down from the
/// Stats screen with [initialStatus] / [initialCategoryName] preset).
class AllComplaintsPage extends StatelessWidget {
  final String? initialStatus;
  final String? initialCategoryName;

  const AllComplaintsPage({
    super.key,
    this.initialStatus,
    this.initialCategoryName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AllComplaintsCubit>(
      create: (ctx) =>
          AllComplaintsCubit(repository: ctx.read<ComplaintRepository>()),
      child: _AllComplaintsView(
        initialStatus: initialStatus,
        initialCategoryName: initialCategoryName,
      ),
    );
  }
}

class _AllComplaintsView extends StatefulWidget {
  final String? initialStatus;
  final String? initialCategoryName;

  const _AllComplaintsView({this.initialStatus, this.initialCategoryName});

  @override
  State<_AllComplaintsView> createState() => _AllComplaintsViewState();
}

class _AllComplaintsViewState extends State<_AllComplaintsView> {
  static const _statusFilters = [
    'All',
    'PENDING_SR_REVIEW',
    'OPEN',
    'ASSIGNED',
    'IN_PROGRESS',
    'RESOLVED',
    'CLOSED',
    'REJECTED',
  ];

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  String? _status;
  String? _categoryId;
  String? _departmentId;
  String? _severity;
  String _search = '';

  List<CategoryModel> _categories = const [];
  List<DepartmentModel> _departments = const [];

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
    _scrollController.addListener(_onScroll);
    _loadFacets();
    // Initial load (filters may still be resolving a category by name).
    WidgetsBinding.instance.addPostFrameCallback((_) => _apply());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadFacets() async {
    final repo = context.read<ComplaintRepository>();
    try {
      final results = await Future.wait([
        repo.getCategories(),
        repo.getDepartments(),
      ]);
      if (!mounted) return;
      setState(() {
        _categories = results[0] as List<CategoryModel>;
        _departments = results[1] as List<DepartmentModel>;
        // Resolve an initial category-by-name drill-down to its id.
        if (widget.initialCategoryName != null && _categoryId == null) {
          final match = _categories.where(
            (c) => c.name.toLowerCase() ==
                widget.initialCategoryName!.toLowerCase(),
          );
          if (match.isNotEmpty) {
            _categoryId = match.first.id;
            _apply();
          }
        }
      });
    } catch (_) {
      // Facets are best-effort; the feed still works with status/search only.
    }
  }

  void _onScroll() {
    final state = context.read<AllComplaintsCubit>().state;
    if (state is! AllComplaintsLoaded) return;
    if (!state.hasMore || state.loadingMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 400) {
      context.read<AllComplaintsCubit>().loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _search = value.trim();
      _apply();
    });
  }

  void _apply() {
    context.read<AllComplaintsCubit>().setQuery(AllComplaintsQuery(
          status: _status,
          categoryId: _categoryId,
          departmentId: _departmentId,
          severity: _severity,
          search: _search.isEmpty ? null : _search,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final role = authState is AuthAuthenticated ? authState.user.role : null;

    return AppScaffold(
      appBar: GradientAppBar(
        title: 'All Complaints',
        glass: true,
        roleBadge: _roleBadge(role),
        actions: [
          _FilterButton(
            activeCount: _facetCount(),
            onPressed: _openFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search by title, description or #number',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          _search = '';
                          _apply();
                        },
                      )
                    : null,
                isDense: true,
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _statusFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = _statusFilters[i];
                final selected =
                    (f == 'All' && _status == null) || f == _status;
                return ScmsChip(
                  label: f == 'All' ? 'All' : f.replaceAll('_', ' '),
                  isSelected: selected,
                  onTap: () {
                    setState(() => _status = f == 'All' ? null : f);
                    _apply();
                  },
                );
              },
            ),
          ),
          Expanded(
            child: BlocBuilder<AllComplaintsCubit, AllComplaintsState>(
              builder: (context, state) {
                if (state is AllComplaintsLoading ||
                    state is AllComplaintsInitial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is AllComplaintsError) {
                  return ScmsErrorWidget(
                    message: state.message,
                    onRetry: () =>
                        context.read<AllComplaintsCubit>().refresh(),
                  );
                }
                if (state is AllComplaintsLoaded) {
                  if (state.items.isEmpty) {
                    return const EmptyStateWidget(
                      title: 'No complaints found',
                      subtitle: 'Try adjusting your search or filters.',
                      icon: Icons.search_off_rounded,
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () =>
                        context.read<AllComplaintsCubit>().refresh(),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(top: 8, bottom: 96),
                      itemCount: state.items.length + 1,
                      itemBuilder: (context, i) {
                        if (i == state.items.length) {
                          return _Footer(
                            loadingMore: state.loadingMore,
                            hasMore: state.hasMore,
                            count: state.items.length,
                          );
                        }
                        final c = state.items[i];
                        return ComplaintCard(
                          complaint: c,
                          onTap: () => context.push('/complaint/${c.id}'),
                        );
                      },
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  int _facetCount() =>
      (_categoryId != null ? 1 : 0) +
      (_departmentId != null ? 1 : 0) +
      (_severity != null ? 1 : 0);

  void _openFilterSheet() {
    // Local working copy so "Cancel" discards changes.
    String? cat = _categoryId;
    String? dept = _departmentId;
    String? sev = _severity;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheet) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Filters', style: AppTextStyles.titleLarge),
                  const SizedBox(height: 16),
                  Text('Severity', style: AppTextStyles.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['HIGH', 'MEDIUM', 'LOW'].map((s) {
                      return ScmsChip(
                        label: s,
                        isSelected: sev == s,
                        selectedColor: AppColors.severityColor(s),
                        onTap: () => setSheet(() => sev = sev == s ? null : s),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  if (_categories.isNotEmpty) ...[
                    Text('Category', style: AppTextStyles.titleSmall),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      value: cat,
                      isExpanded: true,
                      decoration: const InputDecoration(isDense: true),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Any category'),
                        ),
                        ..._categories.map((c) => DropdownMenuItem<String?>(
                              value: c.id,
                              child: Text(c.name,
                                  overflow: TextOverflow.ellipsis),
                            )),
                      ],
                      onChanged: (v) => setSheet(() => cat = v),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_departments.isNotEmpty) ...[
                    Text('Department', style: AppTextStyles.titleSmall),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      value: dept,
                      isExpanded: true,
                      decoration: const InputDecoration(isDense: true),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Any department'),
                        ),
                        ..._departments.map((d) => DropdownMenuItem<String?>(
                              value: d.id,
                              child: Text(d.name,
                                  overflow: TextOverflow.ellipsis),
                            )),
                      ],
                      onChanged: (v) => setSheet(() => dept = v),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            setState(() {
                              _categoryId = null;
                              _departmentId = null;
                              _severity = null;
                            });
                            _apply();
                          },
                          child: const Text('Clear all'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            setState(() {
                              _categoryId = cat;
                              _departmentId = dept;
                              _severity = sev;
                            });
                            _apply();
                          },
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String? _roleBadge(String? role) {
    switch (role) {
      case 'ROLE_ADMIN':
        return 'ADMIN';
      case 'ROLE_DEPT_HEAD':
        return 'DEPT HEAD';
      case 'ROLE_STAFF':
        return 'STAFF';
      case 'ROLE_SR':
        return 'SR';
      case 'ROLE_USER':
        return 'STUDENT';
      default:
        return null;
    }
  }
}

class _FilterButton extends StatelessWidget {
  final int activeCount;
  final VoidCallback onPressed;

  const _FilterButton({required this.activeCount, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        IconButton(
          icon: const Icon(Icons.tune_rounded),
          tooltip: 'Filters',
          onPressed: onPressed,
        ),
        if (activeCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.severityHigh,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '$activeCount',
                textAlign: TextAlign.center,
                style: AppTextStyles.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  final bool loadingMore;
  final bool hasMore;
  final int count;

  const _Footer({
    required this.loadingMore,
    required this.hasMore,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    if (loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          hasMore ? 'Scroll for more' : '$count complaint(s) · end of list',
          style: AppTextStyles.caption,
        ),
      ),
    );
  }
}
