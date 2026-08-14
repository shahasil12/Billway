import '../../../../core/network/api_client.dart';
import '../models/pos_session_model.dart';
import '../../../../features/invoices/data/models/invoice_model.dart';
import '../../domain/entities/pos_cash_movement.dart';

abstract class POSRemoteDataSource {
  Future<POSSessionModel?> getCurrentSession();
  Future<POSSessionModel> openSession(double openingCash);
  Future<POSSessionModel> closeSession(String sessionId, double closingCash);
  Future<InvoiceModel> checkout(Map<String, dynamic> checkoutData);
  Future<POSCashMovement> recordCashMovement(double amount, String type, String reason);
}

class POSRemoteDataSourceImpl implements POSRemoteDataSource {
  final ApiClient apiClient;

  POSRemoteDataSourceImpl(this.apiClient);

  @override
  Future<POSSessionModel?> getCurrentSession() async {
    try {
      final response = await apiClient.dio.get('pos/sessions/current/');
      return POSSessionModel.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<POSSessionModel> openSession(double openingCash) async {
    final response = await apiClient.dio.post(
      'pos/sessions/open/',
      data: {'opening_cash': openingCash},
    );
    return POSSessionModel.fromJson(response.data);
  }

  @override
  Future<POSSessionModel> closeSession(String sessionId, double closingCash) async {
    final response = await apiClient.dio.post(
      'pos/sessions/$sessionId/close/',
      data: {'closing_cash': closingCash},
    );
    return POSSessionModel.fromJson(response.data);
  }

  @override
  Future<InvoiceModel> checkout(Map<String, dynamic> checkoutData) async {
    final response = await apiClient.dio.post(
      'pos/checkout/',
      data: checkoutData,
    );
    return InvoiceModel.fromJson(response.data);
  }

  @override
  Future<POSCashMovement> recordCashMovement(double amount, String type, String reason) async {
    final response = await apiClient.dio.post(
      'pos/sessions/current/cash_movement/',
      data: {
        'amount': amount,
        'movement_type': type,
        'reason': reason,
      },
    );
    return POSCashMovement.fromJson(response.data);
  }
}
