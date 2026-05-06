class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String status;
  final String? phone;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    this.phone,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
        status: json['status'] as String,
        phone: json['phone'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'status': status,
        'phone': phone,
      };

  bool get isActive    => status == 'ACTIVE';
  bool get isPending   => status == 'PENDING';
  bool get isDriver    => role == 'driver';
  bool get isFinance   => role == 'finance';
  bool get isSuperAdmin => role == 'super_admin';
}
