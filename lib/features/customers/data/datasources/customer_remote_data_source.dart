import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/customer_model.dart';
import '../../domain/entities/customer.dart';

abstract class CustomerRemoteDataSource {
  Future<PaginatedCustomersModel> getCustomers(int page, String? search);
  Future<CustomerModel> getCustomer(int id);
  Future<CustomerModel> createCustomer(Customer customer);
  Future<CustomerModel> updateCustomer(Customer customer);
  Future<void> deleteCustomer(int id);
  Future<void> payCustomerCredit(int id, double amount, String paymentMethod);
}

class CustomerRemoteDataSourceImpl implements CustomerRemoteDataSource {
  final ApiClient apiClient;

  CustomerRemoteDataSourceImpl(this.apiClient);

  @override
  Future<PaginatedCustomersModel> getCustomers(int page, String? search) async {
    final Map<String, dynamic> queryParameters = {'page': page};
    if (search != null && search.isNotEmpty) {
      queryParameters['search'] = search;
    }
    final response = await apiClient.dio.get('customers/', queryParameters: queryParameters);
    return PaginatedCustomersModel.fromJson(response.data);
  }

  @override
  Future<CustomerModel> getCustomer(int id) async {
    final response = await apiClient.dio.get('customers/$id/');
    return CustomerModel.fromJson(response.data);
  }

  @override
  Future<CustomerModel> createCustomer(Customer customer) async {
    final model = CustomerModel(name: customer.name, email: customer.email, phone: customer.phone);
    final response = await apiClient.dio.post('customers/', data: model.toJson());
    return CustomerModel.fromJson(response.data);
  }

  @override
  Future<CustomerModel> updateCustomer(Customer customer) async {
    final model = CustomerModel(id: customer.id, name: customer.name, email: customer.email, phone: customer.phone);
    final response = await apiClient.dio.put('customers/${customer.id}/', data: model.toJson());
    return CustomerModel.fromJson(response.data);
  }

  @override
  Future<void> deleteCustomer(int id) async {
    await apiClient.dio.delete('customers/$id/');
  }

  @override
  Future<void> payCustomerCredit(int id, double amount, String paymentMethod) async {
    await apiClient.dio.post(
      'customers/$id/pay_credit/',
      data: {'amount': amount, 'payment_method': paymentMethod},
    );
  }
}
