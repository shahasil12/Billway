import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/dashboard_summary.dart';

abstract class DashboardRepository {
  Future<Either<Failure, DashboardSummary>> getDashboardSummary();
}
