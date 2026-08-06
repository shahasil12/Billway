import '../../../../core/network/api_client.dart';
import '../models/invoice_model.dart';
import '../../domain/entities/invoice.dart';

abstract class InvoiceRemoteDataSource {
  Future<PaginatedInvoicesModel> getInvoices(int page, String? search);
  Future<InvoiceModel> getInvoice(int id);
  Future<InvoiceModel> createInvoice(Invoice invoice);
  Future<void> deleteInvoice(int id);
}

class InvoiceRemoteDataSourceImpl implements InvoiceRemoteDataSource {
  final ApiClient apiClient;

  InvoiceRemoteDataSourceImpl(this.apiClient);

  @override
  Future<PaginatedInvoicesModel> getInvoices(int page, String? search) async {
    final Map<String, dynamic> queryParameters = {'page': page};
    if (search != null && search.isNotEmpty) queryParameters['search'] = search;
    
    final response = await apiClient.dio.get('invoices/', queryParameters: queryParameters);
    return PaginatedInvoicesModel.fromJson(response.data);
  }

  @override
  Future<InvoiceModel> getInvoice(int id) async {
    final response = await apiClient.dio.get('invoices/$id/');
    return InvoiceModel.fromJson(response.data);
  }

  @override
  Future<InvoiceModel> createInvoice(Invoice invoice) async {
    final model = InvoiceModel(
      customerId: invoice.customerId,
      discountPercentage: invoice.discountPercentage,
      paymentMethod: invoice.paymentMethod,
      items: invoice.items.map((i) => InvoiceItemModel(
        productId: i.productId,
        quantity: i.quantity,
      )).toList(),
    );

    final response = await apiClient.dio.post('invoices/', data: model.toJson());
    // The create response is minimal — fetch the full invoice by ID
    final int newId = response.data['id'];
    return getInvoice(newId);
  }

  @override
  Future<void> deleteInvoice(int id) async {
    await apiClient.dio.delete('invoices/$id/');
  }
}
