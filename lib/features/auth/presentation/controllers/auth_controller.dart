import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user.dart';

class AuthController extends StateNotifier<AsyncValue<User?>> {
  final AuthRepository _repository;

  AuthController(this._repository) : super(const AsyncValue.data(null));

  Future<void> checkAutoLogin() async {
    state = const AsyncValue.loading();
    final success = await _repository.autoLogin();
    if (success) {
      final userOrFailure = await _repository.getCurrentUserCached();
      userOrFailure.fold(
        (failure) => state = const AsyncValue.data(null),
        (user) => state = AsyncValue.data(user),
      );
    } else {
      state = const AsyncValue.data(null);
    }
  }

  Future<bool> login(String username, String password) async {
    state = const AsyncValue.loading();
    final result = await _repository.login(username, password);
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (user) {
        state = AsyncValue.data(user);
        return true;
      },
    );
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    await _repository.logout();
    state = const AsyncValue.data(null);
  }

  Future<bool> register(String companyName, String username, String email, String password) async {
    state = const AsyncValue.loading();
    final result = await _repository.register(companyName, username, email, password);
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (user) {
        state = AsyncValue.data(user);
        return true;
      },
    );
  }
}
