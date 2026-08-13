import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user.dart';
import '../../data/repositories/user_management_repository.dart';

class UserManagementController extends StateNotifier<AsyncValue<List<User>>> {
  final UserManagementRepository _repository;

  UserManagementController(this._repository) : super(const AsyncValue.loading()) {
    loadUsers();
  }

  Future<void> loadUsers() async {
    state = const AsyncValue.loading();
    try {
      final users = await _repository.getUsers();
      state = AsyncValue.data(users);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> createUser(Map<String, dynamic> userData) async {
    try {
      final newUser = await _repository.createUser(userData);
      if (state.hasValue) {
        state = AsyncValue.data([newUser, ...state.value!]);
      }
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  Future<void> deleteUser(int id) async {
    try {
      await _repository.deleteUser(id);
      if (state.hasValue) {
        state = AsyncValue.data(
          state.value!.where((user) => user.id != id).toList(),
        );
      }
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  Future<void> updateUserRole(int id, String role) async {
    try {
      final updatedUser = await _repository.updateUserRole(id, role);
      if (state.hasValue) {
        state = AsyncValue.data(
          state.value!.map((u) => u.id == id ? updatedUser : u).toList(),
        );
      }
    } catch (e) {
      throw Exception('Failed to update role: $e');
    }
  }
}
