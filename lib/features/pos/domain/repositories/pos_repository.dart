import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/pos_session.dart';
import '../../../invoices/domain/entities/invoice.dart';

abstract class POSRepository {
  Future<Either<Failure, POSSession?>> getCurrentSession();
  Future<Either<Failure, POSSession>> openSession(double openingCash);
  Future<Either<Failure, POSSession>> closeSession(String sessionId, double closingCash);
  Future<Either<Failure, Invoice>> checkout(Map<String, dynamic> checkoutData);
}
