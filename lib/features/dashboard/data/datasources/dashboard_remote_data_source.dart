import '../../../../core/network/api_client.dart';
import '../models/dashboard_summary_model.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardSummaryModel> getSummary();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final ApiClient apiClient;

  DashboardRemoteDataSourceImpl(this.apiClient);

  @override
  Future<DashboardSummaryModel> getSummary() async {
    final response = await apiClient.dio.get('dashboard/summary/');
    return DashboardSummaryModel.fromJson(response.data);
  }
}
