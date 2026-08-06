import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_remote_data_source.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsRemoteDataSource remoteDataSource;

  SettingsRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, Settings>> getSettings() async {
    try {
      final settings = await remoteDataSource.getSettings();
      return Right(settings);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Server error'));
    } catch (e) {
      return const Left(ServerFailure('Failed to fetch settings'));
    }
  }

  @override
  Future<Either<Failure, Settings>> updateSettings(Settings settings) async {
    try {
      final updatedSettings = await remoteDataSource.updateSettings(settings);
      return Right(updatedSettings);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Server error'));
    } catch (e) {
      return const Left(ServerFailure('Failed to update settings'));
    }
  }
}
