class CategoryModel {
  final String id;
  final String name;
  final String? iconName;
  final String defaultDepartmentId;

  const CategoryModel({
    required this.id,
    required this.name,
    this.iconName,
    required this.defaultDepartmentId,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      iconName: json['iconName'] as String?,
      defaultDepartmentId: json['defaultDepartmentId'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'iconName': iconName,
    'defaultDepartmentId': defaultDepartmentId,
  };
}
