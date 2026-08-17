import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../../../../core/network/api_client.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> login(String username, String password);
  Future<void> logout(String refreshToken);
  Future<UserModel> getCurrentUser();
  Future<void> changePassword(String oldPassword, String newPassword);
  Future<Map<String, dynamic>> register(String companyName, String username, String email, String password);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl(this.apiClient);

  @override
  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await apiClient.dio.post('auth/login/', data: {
      'username': username,
      'password': password,
    });
    return response.data;
  }

  @override
  Future<void> logout(String refreshToken) async {
    await apiClient.dio.post('auth/logout/', data: {
      'refresh': refreshToken,
    });
  }

  @override
  Future<UserModel> getCurrentUser() async {
    final response = await apiClient.dio.get('auth/me/');
    return UserModel.fromJson(response.data);
  }

  @override
  Future<void> changePassword(String oldPassword, String newPassword) async {
    await apiClient.dio.post('auth/change-password/', data: {
      'old_password': oldPassword,
      'new_password': newPassword,
    });
  }

  @override
  Future<Map<String, dynamic>> register(String companyName, String username, String email, String password) async {
    final response = await apiClient.dio.post('auth/register/', data: {
      'company_name': companyName,
      'username': username,
      'email': email,
      'password': password,
    });
    return response.data;
  }
}
