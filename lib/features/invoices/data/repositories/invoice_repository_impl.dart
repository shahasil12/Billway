import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../datasources/invoice_remote_data_source.dart';

class InvoiceRepositoryImpl implements InvoiceRepository {
  final InvoiceRemoteDataSource remoteDataSource;

  InvoiceRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, PaginatedInvoices>> getInvoices({int page = 1, String? search}) async {
    try {
      final invoices = await remoteDataSource.getInvoices(page, search);
      return Right(invoices);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Server error'));
    } catch (e) {
      return const Left(ServerFailure('Failed to fetch invoices'));
    }
  }

  @override
  Future<Either<Failure, Invoice>> getInvoice(int id) async {
    try {
      final invoice = await remoteDataSource.getInvoice(id);
      return Right(invoice);
    } catch (e) {
      return const Left(ServerFailure('Failed to get invoice'));
    }
  }

  @override
  Future<Either<Failure, Invoice>> createInvoice(Invoice invoice) async {
    try {
      final newInvoice = await remoteDataSource.createInvoice(invoice);
      return Right(newInvoice);
    } on DioException catch (e) {
       final errors = e.response?.data;
       String message = 'Failed to create invoice';
       if (errors is List && errors.isNotEmpty) {
           message = errors[0].toString();
       } else if (errors is Map) {
         if (errors.containsKey('detail')) {
            message = errors['detail'].toString();
         } else if (errors.containsKey('items') && errors['items'] is List) {
             message = errors['items'][0].toString();
         } else if (errors.containsKey('non_field_errors') && errors['non_field_errors'] is List) {
             message = errors['non_field_errors'][0].toString();
         } else {
            message = errors.values.first.toString();
         }
       }
       return Left(ServerFailure(message));
    } catch (e) {
      return const Left(ServerFailure('Failed to create invoice'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteInvoice(int id) async {
    try {
      await remoteDataSource.deleteInvoice(id);
      return const Right(null);
    } catch (e) {
      return const Left(ServerFailure('Failed to delete invoice'));
    }
  }
}
