class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? picture;
  final String role; // ROLE_USER | ROLE_STAFF | ROLE_SR | ROLE_DEPT_HEAD | ROLE_ADMIN
  final String? departmentId;
  final String? departmentName;
  final String? zoneId;
  final DateTime createdAt;
  final DateTime? lastLogin;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.picture,
    required this.role,
    this.departmentId,
    this.departmentName,
    this.zoneId,
    required this.createdAt,
    this.lastLogin,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      picture: json['picture'] as String?,
      role: json['role'] as String? ?? 'ROLE_USER',
      departmentId: json['departmentId'] as String?,
      departmentName: json['departmentName'] as String?,
      zoneId: json['zoneId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'picture': picture,
      'role': role,
      'departmentId': departmentId,
      'departmentName': departmentName,
      'zoneId': zoneId,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? picture,
    String? role,
    String? departmentId,
    String? departmentName,
    String? zoneId,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      picture: picture ?? this.picture,
      role: role ?? this.role,
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
      zoneId: zoneId ?? this.zoneId,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  /// Check if user has a specific role
  bool hasRole(String checkRole) => role == checkRole;
  bool get isAdmin => role == 'ROLE_ADMIN';
  bool get isStaff => role == 'ROLE_STAFF';
  bool get isSR => role == 'ROLE_SR';
  bool get isDeptHead => role == 'ROLE_DEPT_HEAD';
  bool get isUser => role == 'ROLE_USER';
}
