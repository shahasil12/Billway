import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/customer.dart';
import '../../domain/repositories/customer_repository.dart';
import '../datasources/customer_remote_data_source.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerRemoteDataSource remoteDataSource;

  CustomerRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, PaginatedCustomers>> getCustomers({int page = 1, String? search}) async {
    try {
      final customers = await remoteDataSource.getCustomers(page, search);
      return Right(customers);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Server error'));
    } catch (e) {
      return const Left(ServerFailure('Failed to fetch customers'));
    }
  }

  @override
  Future<Either<Failure, Customer>> getCustomer(int id) async {
    try {
      final customer = await remoteDataSource.getCustomer(id);
      return Right(customer);
    } catch (e) {
      return const Left(ServerFailure('Failed to get customer'));
    }
  }

  @override
  Future<Either<Failure, Customer>> createCustomer(Customer customer) async {
    try {
      final newCustomer = await remoteDataSource.createCustomer(customer);
      return Right(newCustomer);
    } on DioException catch (e) {
       final errors = e.response?.data;
       String message = 'Failed to create customer';
       if (errors is Map) {
         message = errors.values.first.toString();
       }
       return Left(ServerFailure(message));
    } catch (e) {
      return const Left(ServerFailure('Failed to create customer'));
    }
  }

  @override
  Future<Either<Failure, Customer>> updateCustomer(Customer customer) async {
    try {
      final updatedCustomer = await remoteDataSource.updateCustomer(customer);
      return Right(updatedCustomer);
    } on DioException catch (e) {
       final errors = e.response?.data;
       String message = 'Failed to update customer';
       if (errors is Map) {
         message = errors.values.first.toString();
       }
       return Left(ServerFailure(message));
    } catch (e) {
      return const Left(ServerFailure('Failed to update customer'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCustomer(int id) async {
    try {
      await remoteDataSource.deleteCustomer(id);
      return const Right(null);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 && e.response?.data['detail'] != null) {
        return Left(ServerFailure(e.response!.data['detail']));
      }
      return const Left(ServerFailure('Failed to delete customer'));
    } catch (e) {
      return const Left(ServerFailure('Failed to delete customer'));
    }
  }
}
