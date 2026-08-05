import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/customer.dart';

abstract class CustomerRepository {
  Future<Either<Failure, PaginatedCustomers>> getCustomers({int page = 1, String? search});
  Future<Either<Failure, Customer>> getCustomer(int id);
  Future<Either<Failure, Customer>> createCustomer(Customer customer);
  Future<Either<Failure, Customer>> updateCustomer(Customer customer);
  Future<Either<Failure, void>> deleteCustomer(int id);
}
