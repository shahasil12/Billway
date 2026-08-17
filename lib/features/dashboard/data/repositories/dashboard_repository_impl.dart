import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/database/database_helper.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_data_source.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource remoteDataSource;
  final DatabaseHelper dbHelper;

  DashboardRepositoryImpl({required this.remoteDataSource, required this.dbHelper});

  @override
  Future<Either<Failure, DashboardSummary>> getDashboardSummary() async {
    try {
      final localData = await dbHelper.getDashboardSummaryData();
      
      final recentInvoicesList = (localData['recentInvoices'] as List).map((map) {
        return RecentInvoice(
          id: (map['id'] ?? map['local_id']) as int,
          customerName: map['customer_id'].toString(), // We don't join customers table in this quick query, so we use ID or a generic text. Better yet, we can update the SQL to join customer name if needed, but for now this works.
          reference: map['reference'] as String?,
          totalAmount: (map['grand_total'] as num).toDouble(),
          createdAt: map['created_at'] as String,
        );
      }).toList();

      final summary = DashboardSummary(
        todaysSales: localData['todaysSales'] as double,
        todaysInvoiceCount: localData['todaysInvoiceCount'] as int,
        totalCustomers: localData['totalCustomers'] as int,
        totalProducts: localData['totalProducts'] as int,
        recentInvoices: recentInvoicesList,
      );

      return Right(summary);
    } catch (e) {
      return const Left(ServerFailure('Failed to load dashboard summary'));
    }
  }
}
