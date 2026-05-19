class DepartmentModel {
  final String id;
  final String name;
  final String code;
  final String? headName;
  final int activeComplaintsCount;

  const DepartmentModel({
    required this.id,
    required this.name,
    required this.code,
    this.headName,
    this.activeComplaintsCount = 0,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      headName: json['headName'] as String?,
      activeComplaintsCount: json['activeComplaintsCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'code': code,
    'headName': headName, 'activeComplaintsCount': activeComplaintsCount,
  };
}
