import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/report.dart';
import '../../domain/repositories/report_repository.dart';
import '../datasources/report_remote_data_source.dart';

class ReportRepositoryImpl implements ReportRepository {
  final ReportRemoteDataSource remoteDataSource;

  ReportRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, Report>> getReport({String? startDate, String? endDate}) async {
    try {
      final report = await remoteDataSource.getReport(startDate: startDate, endDate: endDate);
      return Right(report);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Server error'));
    } catch (e) {
      return const Left(ServerFailure('Failed to fetch report'));
    }
  }
}
