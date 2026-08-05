import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class AuthLocalDataSource {
  Future<void> saveTokens(String access, String refresh);
  Future<void> clearTokens();
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
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
  }

  @override
  Future<String?> getAccessToken() async {
    return await storage.read(key: 'access_token');
  }

  @override
  Future<String?> getRefreshToken() async {
    return await storage.read(key: 'refresh_token');
  }
}
