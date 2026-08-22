import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/user.dart';

abstract class AuthLocalDataSource {
  Future<void> saveTokens(String access, String refresh);
  Future<void> clearTokens();
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> cacheUser(User user);
  Future<User?> getCachedUser();
  Future<void> setRememberMe(bool value);
  Future<bool> getRememberMe();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final FlutterSecureStorage storage;

  AuthLocalDataSourceImpl(this.storage);

  @override
  Future<void> saveTokens(String access, String refresh) async {
    await storage.write(key: 'access_token', value: access);
    await storage.write(key: 'refresh_token', value: refresh);
  }

  @override
  Future<void> clearTokens() async {
    await storage.delete(key: 'access_token');
    await storage.delete(key: 'refresh_token');
    await storage.delete(key: 'cached_user');
  }

  @override
  Future<String?> getAccessToken() async {
    return await storage.read(key: 'access_token');
  }

  @override
  Future<String?> getRefreshToken() async {
    return await storage.read(key: 'refresh_token');
  }

  @override
  Future<void> cacheUser(User user) async {
    final json = jsonEncode({
      'id': user.id,
      'username': user.username,
      'email': user.email,
      'first_name': user.firstName,
      'last_name': user.lastName,
      'role': user.role.name,
    });
    await storage.write(key: 'cached_user', value: json);
  }

  @override
  Future<User?> getCachedUser() async {
    final raw = await storage.read(key: 'cached_user');
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final roleStr = map['role'] as String? ?? 'unknown';
      final role = UserRole.values.firstWhere(
        (r) => r.name == roleStr,
        orElse: () => UserRole.unknown,
      );
      return User(
        id: map['id'] as int,
        username: map['username'] as String,
        email: map['email'] as String,
        firstName: map['first_name'] as String? ?? '',
        lastName: map['last_name'] as String? ?? '',
        role: role,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> setRememberMe(bool value) async {
    await storage.write(key: 'remember_me', value: value.toString());
  }

  @override
  Future<bool> getRememberMe() async {
    final value = await storage.read(key: 'remember_me');
    return value == 'true';
  }
}
