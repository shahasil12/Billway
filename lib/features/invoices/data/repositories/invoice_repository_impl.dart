import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/sync/sync_service.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../datasources/invoice_remote_data_source.dart';
import '../datasources/invoice_local_data_source.dart';
import '../models/invoice_model.dart';

class InvoiceRepositoryImpl implements InvoiceRepository {
  final InvoiceRemoteDataSource remoteDataSource;
  final InvoiceLocalDataSource localDataSource;
  final SyncService syncService;

  InvoiceRepositoryImpl(this.remoteDataSource, this.localDataSource, this.syncService);

  @override
  Future<Either<Failure, PaginatedInvoices>> getInvoices({int page = 1, String? search}) async {
    try {
      final localInvoices = await localDataSource.getInvoices(search: search);
      
      // Fire and forget background sync
      _syncRemoteInvoices(page, search);
      
      return Right(PaginatedInvoicesModel(count: localInvoices.length, results: localInvoices));
    } catch (e) {
      return const Left(ServerFailure('Failed to fetch invoices'));
    }
  }

  Future<void> _syncRemoteInvoices(int page, String? search) async {
    try {
      final remoteInvoices = await remoteDataSource.getInvoices(page, search);
      await localDataSource.upsertInvoices(remoteInvoices.results as List<InvoiceModel>);
    } catch (_) {
      // Ignore background sync errors
    }
  }

  @override
  Future<Either<Failure, Invoice>> getInvoice(int id) async {
    try {
      final localInvoice = await localDataSource.getInvoice(id);
      if (localInvoice != null) {
        try {
          final remoteInvoice = await remoteDataSource.getInvoice(id);
          await localDataSource.upsertInvoices([remoteInvoice]);
          return Right(remoteInvoice);
        } catch (e) {
          return Right(localInvoice);
        }
      } else {
        final remoteInvoice = await remoteDataSource.getInvoice(id);
        await localDataSource.upsertInvoices([remoteInvoice]);
        return Right(remoteInvoice);
      }
    } catch (e) {
      return const Left(ServerFailure('Failed to get invoice'));
    }
  }

  @override
  Future<Either<Failure, Invoice>> createInvoice(Invoice invoice) async {
    try {
      final model = InvoiceModel(
        customerId: invoice.customerId,
        reference: invoice.reference,
        subtotal: invoice.subtotal,
        discountPercentage: invoice.discountPercentage,
        discountAmount: invoice.discountAmount,
        taxTotal: invoice.taxTotal,
        grandTotal: invoice.grandTotal,
        amountPaid: invoice.amountPaid,
        balanceDue: invoice.balanceDue,
        paymentMethod: invoice.paymentMethod,
        status: invoice.status,
        items: invoice.items,
      );
      
      final localInvoice = await localDataSource.createInvoice(model);
      
      await syncService.addToQueue('CREATE', 'INVOICE', localInvoice.toJson(), localId: localInvoice.id);
      
      return Right(localInvoice);
    } catch (e) {
      return const Left(ServerFailure('Failed to create invoice'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteInvoice(int id) async {
    try {
      await localDataSource.deleteInvoice(id);
      await syncService.addToQueue('DELETE', 'INVOICE', {'id': id});
      
      return const Right(null);
    } catch (e) {
      return const Left(ServerFailure('Failed to delete invoice'));
    }
  }
}
