import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/invoice.dart';

abstract class InvoiceRepository {
  Future<Either<Failure, PaginatedInvoices>> getInvoices({int page = 1, String? search, String? status, int? customerId});
  Future<Either<Failure, Invoice>> getInvoice(int id);
  Future<Either<Failure, Invoice>> createInvoice(Invoice invoice);
  Future<Either<Failure, void>> deleteInvoice(int id);
}
