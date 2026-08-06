import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/payment.dart';

abstract class PaymentRepository {
  Future<Either<Failure, PaginatedPayments>> getPayments({int page = 1});
  Future<Either<Failure, Payment>> createPayment(Payment payment);
}
