import 'complaint_model.dart';

class AnalyticsModel {
  final int totalActiveComplaints;
  final int slaBreachesLast7Days;
  final double avgResolutionTimeHours;
  final double resolutionRatePercent;
  final List<DepartmentStat> byDepartment;
  final List<CategoryStat> byCategory;
  final List<ComplaintModel> recentSlaBreaches;

  const AnalyticsModel({
    required this.totalActiveComplaints,
    required this.slaBreachesLast7Days,
    required this.avgResolutionTimeHours,
    required this.resolutionRatePercent,
    required this.byDepartment,
    required this.byCategory,
    this.recentSlaBreaches = const [],
  });

  factory AnalyticsModel.fromJson(Map<String, dynamic> json) {
    // The backend `/analytics/summary` returns:
    //   { totalComplaints, activeComplaints, resolvedComplaints, slaBreachedCount,
    //     averageResolutionTimeHours, departmentStats:[{departmentName,count}],
    //     categoryStats:[{categoryName,count}] }
    // Fall back to legacy keys where present for resilience.
    final total = json['totalComplaints'] as int? ?? 0;
    final resolved = json['resolvedComplaints'] as int? ?? 0;
    final providedRate = (json['resolutionRatePercent'] as num?)?.toDouble();

    final deptList = (json['departmentStats'] ?? json['byDepartment']) as List<dynamic>?;
    final catList = (json['categoryStats'] ?? json['byCategory']) as List<dynamic>?;

    return AnalyticsModel(
      totalActiveComplaints:
          json['activeComplaints'] as int? ?? json['totalActiveComplaints'] as int? ?? 0,
      slaBreachesLast7Days:
          json['slaBreachedCount'] as int? ?? json['slaBreachesLast7Days'] as int? ?? 0,
      avgResolutionTimeHours:
          (json['averageResolutionTimeHours'] ?? json['avgResolutionTimeHours'] as num?)
                  ?.toDouble() ??
              0,
      resolutionRatePercent:
          providedRate ?? (total > 0 ? (resolved / total) * 100 : 0),
      byDepartment: deptList
              ?.map((d) => DepartmentStat.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
      byCategory: catList
              ?.map((c) => CategoryStat.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      recentSlaBreaches: (json['recentSlaBreaches'] as List<dynamic>?)
              ?.map((c) => ComplaintModel.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'totalActiveComplaints': totalActiveComplaints,
    'slaBreachesLast7Days': slaBreachesLast7Days,
    'avgResolutionTimeHours': avgResolutionTimeHours,
    'resolutionRatePercent': resolutionRatePercent,
    'byDepartment': byDepartment.map((d) => d.toJson()).toList(),
    'byCategory': byCategory.map((c) => c.toJson()).toList(),
  };
}

class DepartmentStat {
  final String departmentName;
  final int openCount;
  final int inProgressCount;
  final int resolvedCount;

  /// Aggregate count when the backend returns a flat total per department
  /// (rather than a per-status breakdown).
  final int? _aggregateCount;

  const DepartmentStat({
    required this.departmentName,
    this.openCount = 0,
    this.inProgressCount = 0,
    this.resolvedCount = 0,
    int? aggregateCount,
  }) : _aggregateCount = aggregateCount;

  int get totalCount =>
      _aggregateCount ?? (openCount + inProgressCount + resolvedCount);

  factory DepartmentStat.fromJson(Map<String, dynamic> json) {
    return DepartmentStat(
      departmentName: json['departmentName'] as String? ?? 'Unknown',
      openCount: json['openCount'] as int? ?? 0,
      inProgressCount: json['inProgressCount'] as int? ?? 0,
      resolvedCount: json['resolvedCount'] as int? ?? 0,
      aggregateCount: json['count'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'departmentName': departmentName, 'count': totalCount,
  };
}

class CategoryStat {
  final String categoryName;
  final int count;

  const CategoryStat({required this.categoryName, required this.count});

  factory CategoryStat.fromJson(Map<String, dynamic> json) {
    return CategoryStat(
      categoryName: json['categoryName'] as String,
      count: json['count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'categoryName': categoryName, 'count': count};
}
