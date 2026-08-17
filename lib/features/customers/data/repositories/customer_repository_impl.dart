import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/sync/sync_service.dart';
import '../../domain/entities/customer.dart';
import '../../domain/repositories/customer_repository.dart';
import '../datasources/customer_remote_data_source.dart';
import '../datasources/customer_local_data_source.dart';
import '../models/customer_model.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerRemoteDataSource remoteDataSource;
  final CustomerLocalDataSource localDataSource;
  final SyncService syncService;

  CustomerRepositoryImpl(this.remoteDataSource, this.localDataSource, this.syncService);

  @override
  Future<Either<Failure, PaginatedCustomers>> getCustomers({int page = 1, String? search}) async {
    try {
      final localCustomers = await localDataSource.getCustomers(search: search);
      
      // Fire and forget background sync
      _syncRemoteCustomers(page, search);
      
      return Right(PaginatedCustomersModel(count: localCustomers.length, results: localCustomers));
    } catch (e) {
      return const Left(ServerFailure('Failed to fetch customers'));
    }
  }

  Future<void> _syncRemoteCustomers(int page, String? search) async {
    try {
      final remoteCustomers = await remoteDataSource.getCustomers(page, search);
      await localDataSource.upsertCustomers(remoteCustomers.results as List<CustomerModel>);
    } catch (_) {
      // Ignore background sync errors
    }
  }

  @override
  Future<Either<Failure, Customer>> getCustomer(int id) async {
    try {
      final localCustomer = await localDataSource.getCustomer(id);
      if (localCustomer != null) {
        try {
          final remoteCustomer = await remoteDataSource.getCustomer(id);
          await localDataSource.upsertCustomers([remoteCustomer]);
          return Right(remoteCustomer);
        } catch (e) {
          return Right(localCustomer);
        }
      } else {
        final remoteCustomer = await remoteDataSource.getCustomer(id);
        await localDataSource.upsertCustomers([remoteCustomer]);
        return Right(remoteCustomer);
      }
    } catch (e) {
      return const Left(ServerFailure('Failed to get customer'));
    }
  }

  @override
  Future<Either<Failure, Customer>> createCustomer(Customer customer) async {
    try {
      final model = CustomerModel(name: customer.name, email: customer.email, phone: customer.phone);
      final localCustomer = await localDataSource.createCustomer(model);
      
      await syncService.addToQueue('CREATE', 'CUSTOMER', localCustomer.toJson(), localId: localCustomer.id);
      
      return Right(localCustomer);
    } catch (e) {
      return const Left(ServerFailure('Failed to create customer'));
    }
  }

  @override
  Future<Either<Failure, Customer>> updateCustomer(Customer customer) async {
    try {
      final model = CustomerModel(id: customer.id, name: customer.name, email: customer.email, phone: customer.phone);
      final updatedLocal = await localDataSource.updateCustomer(model);
      
      await syncService.addToQueue('UPDATE', 'CUSTOMER', updatedLocal.toJson());
      
      return Right(updatedLocal);
    } catch (e) {
      return const Left(ServerFailure('Failed to update customer'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCustomer(int id) async {
    try {
      await localDataSource.deleteCustomer(id);
      await syncService.addToQueue('DELETE', 'CUSTOMER', {'id': id});
      
      return const Right(null);
    } catch (e) {
      return const Left(ServerFailure('Failed to delete customer'));
    }
  }
}
