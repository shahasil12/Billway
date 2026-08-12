import '../../domain/entities/user.dart';

class UserModel extends User {
  UserModel({
    required super.id,
    required super.username,
    required super.email,
    required super.firstName,
    required super.lastName,
    required super.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    UserRole parsedRole = UserRole.unknown;
    if (json['role'] != null) {
      final roleStr = json['role'].toString().toUpperCase();
      if (roleStr == 'ADMIN') parsedRole = UserRole.admin;
      else if (roleStr == 'MANAGER') parsedRole = UserRole.manager;
      else if (roleStr == 'CASHIER') parsedRole = UserRole.cashier;
    }

    return UserModel(
      id: json['id'],
      username: json['username'],
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      role: parsedRole,
    );
  }

  Map<String, dynamic> toJson() {
    String roleStr = 'CASHIER';
    if (role == UserRole.admin) roleStr = 'ADMIN';
    else if (role == UserRole.manager) roleStr = 'MANAGER';

    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'role': roleStr,
    };
  }
}
