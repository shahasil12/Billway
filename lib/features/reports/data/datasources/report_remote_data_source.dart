import '../../../../core/network/api_client.dart';
import '../models/report_model.dart';

abstract class ReportRemoteDataSource {
  Future<ReportModel> getReport({String? startDate, String? endDate});
}

class ReportRemoteDataSourceImpl implements ReportRemoteDataSource {
  final ApiClient apiClient;

  ReportRemoteDataSourceImpl(this.apiClient);

  @override
  Future<ReportModel> getReport({String? startDate, String? endDate}) async {
    final query = <String, dynamic>{};
    if (startDate != null) query['start_date'] = startDate;
    if (endDate != null) query['end_date'] = endDate;

    final response = await apiClient.dio.get('reports/', queryParameters: query);
    return ReportModel.fromJson(response.data);
  }
}
