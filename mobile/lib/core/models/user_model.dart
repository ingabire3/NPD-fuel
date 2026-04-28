class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String? phone;
  final String? department;
  final bool isActive;
  final String? approvalStatus;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.phone,
    this.department,
    required this.isActive,
    this.approvalStatus,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        fullName: json['full_name'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
        phone: json['phone'] as String?,
        department: json['department'] as String?,
        isActive: json['is_active'] as bool? ?? false,
        approvalStatus: json['approval_status'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'email': email,
        'role': role,
        'phone': phone,
        'department': department,
        'is_active': isActive,
        'approval_status': approvalStatus,
      };

  String get name => fullName;

  bool get isSuperAdmin => role == 'SUPER_ADMIN';
  bool get isManager => role == 'MANAGER';
  bool get isDriver => role == 'DRIVER';
  bool get isFinance => role == 'FINANCE';
  bool get isPending => approvalStatus == 'PENDING';
}
