import '../../../../core/network/api_client.dart';
import '../models/payment_model.dart';
import '../../domain/entities/payment.dart';

abstract class PaymentRemoteDataSource {
  Future<PaginatedPaymentsModel> getPayments(int page);
  Future<PaymentModel> createPayment(Payment payment);
}

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  final ApiClient apiClient;

  PaymentRemoteDataSourceImpl(this.apiClient);

  @override
  Future<PaginatedPaymentsModel> getPayments(int page) async {
    final response = await apiClient.dio.get('payments/', queryParameters: {'page': page});
    return PaginatedPaymentsModel.fromJson(response.data);
  }

  @override
  Future<PaymentModel> createPayment(Payment payment) async {
    final model = PaymentModel(
      invoiceId: payment.invoiceId,
      amount: payment.amount,
      paymentMethod: payment.paymentMethod,
      referenceNumber: payment.referenceNumber,
      notes: payment.notes,
    );
    final response = await apiClient.dio.post('payments/', data: model.toJson());
    return PaymentModel.fromJson(response.data);
  }
}
