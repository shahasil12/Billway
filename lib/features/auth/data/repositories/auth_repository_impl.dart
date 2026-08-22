import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, User>> login(String username, String password) async {
    try {
      final tokens = await remoteDataSource.login(username, password);
      await localDataSource.saveTokens(tokens['access'], tokens['refresh']);
      final user = await remoteDataSource.getCurrentUser();
      await localDataSource.cacheUser(user); // cache for offline autoLogin
      return Right(user);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?['detail'] ?? 'Login failed'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> register(String companyName, String username, String email, String password) async {
    try {
      await remoteDataSource.register(companyName, username, email, password);
      return login(username, password);
    } on DioException catch (e) {
      String errorMessage = 'Registration failed';
      if (e.response?.data != null && e.response?.data is Map) {
         final data = e.response?.data as Map<String, dynamic>;
         if (data.values.isNotEmpty && data.values.first is List && data.values.first.isNotEmpty) {
             errorMessage = data.values.first[0].toString();
         }
      }
      return Left(ServerFailure(errorMessage));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      final refresh = await localDataSource.getRefreshToken();
      if (refresh != null) {
        await remoteDataSource.logout(refresh);
      }
      await localDataSource.clearTokens();
      return const Right(null);
    } catch (e) {
      await localDataSource.clearTokens();
      return const Right(null);
    }
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      final user = await remoteDataSource.getCurrentUser();
      await localDataSource.cacheUser(user); // keep cache fresh
      return Right(user);
    } catch (e) {
      return const Left(ServerFailure('Failed to get current user'));
    }
  }

  @override
  Future<Either<Failure, User>> getCurrentUserCached() async {
    // Return cached user instantly — no network
    final cached = await localDataSource.getCachedUser();
    if (cached != null) return Right(cached);
    // Fallback to network if no cache exists
    return getCurrentUser();
  }

  @override
  Future<Either<Failure, void>> changePassword(String oldPassword, String newPassword) async {
    try {
      await remoteDataSource.changePassword(oldPassword, newPassword);
      return const Right(null);
    } on DioException catch (e) {
       return Left(ServerFailure(e.response?.data?['old_password']?[0] ?? 'Failed to change password'));
    } catch (e) {
      return const Left(ServerFailure('Failed to change password'));
    }
  }

  @override
  Future<bool> autoLogin() async {
    final rememberMe = await localDataSource.getRememberMe();
    if (!rememberMe) {
      await localDataSource.clearTokens();
      return false;
    }

    final token = await localDataSource.getAccessToken();
    if (token == null) return false;

    // Immediately read the cached user from secure storage if available,
    // so we don't block on a network call during startup.
    final cachedUser = await localDataSource.getCachedUser();
    if (cachedUser != null) {
      // We have a token + cached user — trust it, navigate immediately.
      // In the background, validate the token against the server.
      _refreshUserInBackground();
      return true;
    }

    // No cached user yet (first install after login) — must hit network.
    final result = await getCurrentUser();
    return result.fold(
      (_) => false,
      (user) async {
        await localDataSource.cacheUser(user);
        return true;
      },
    );
  }

  void _refreshUserInBackground() async {
    try {
      final result = await getCurrentUser();
      result.fold((_) {}, (user) => localDataSource.cacheUser(user));
    } catch (_) {}
  }
}
