import 'package:dio/dio.dart';
import '../../domain/entities/user.dart';
import '../models/user_model.dart';

class UserManagementRepository {
  final Dio _dio;

  UserManagementRepository(this._dio);

  Future<List<User>> getUsers() async {
    try {
      final response = await _dio.get('auth/manage/');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> && data.containsKey('results')) {
          final results = data['results'] as List;
          return results.map((json) => UserModel.fromJson(json)).toList();
        } else if (data is List) {
          return data.map((json) => UserModel.fromJson(json)).toList();
        }
        throw Exception('Unexpected response format');
      }
      throw Exception('Failed to load users');
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e.response?.data) ?? 'Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error loading users: $e');
    }
  }

  Future<User> createUser(Map<String, dynamic> userData) async {
    try {
      final response = await _dio.post(
        'auth/manage/',
        data: userData,
      );
      if (response.statusCode == 201) {
        return UserModel.fromJson(response.data);
      }
      throw Exception('Failed to create user: ${response.data}');
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e.response?.data) ?? 'Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error creating user: $e');
    }
  }

  Future<void> deleteUser(int id) async {
    try {
      final response = await _dio.delete('auth/manage/$id/');
      if (response.statusCode != 204) {
        throw Exception('Failed to delete user');
      }
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e.response?.data) ?? 'Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error deleting user: $e');
    }
  }

  Future<User> updateUserRole(int id, String role) async {
    try {
      final response = await _dio.patch('auth/manage/$id/', data: {'role': role});
      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      }
      throw Exception('Failed to update role: ${response.data}');
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e.response?.data) ?? 'Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error updating role: $e');
    }
  }

  String? _extractErrorMessage(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) {
      if (data.containsKey('detail')) return data['detail'].toString();
      // Handle Django REST framework field errors
      final errors = <String>[];
      data.forEach((key, value) {
        if (value is List) {
          errors.add('$key: ${value.join(", ")}');
        } else {
          errors.add('$key: $value');
        }
      });
      if (errors.isNotEmpty) return errors.join('\n');
    }
    return data.toString();
  }
}
