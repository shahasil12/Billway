import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_data_source.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource remoteDataSource;

  DashboardRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, DashboardSummary>> getDashboardSummary() async {
    try {
      final summary = await remoteDataSource.getSummary();
      return Right(summary);
    } catch (e) {
      return const Left(ServerFailure('Failed to load dashboard summary'));
    }
  }
}
