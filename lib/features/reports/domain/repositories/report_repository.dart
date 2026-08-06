import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/report.dart';

abstract class ReportRepository {
  Future<Either<Failure, Report>> getReport({String? startDate, String? endDate});
}
