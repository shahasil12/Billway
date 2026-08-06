import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payment_repository.dart';
import '../datasources/payment_remote_data_source.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDataSource remoteDataSource;

  PaymentRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, PaginatedPayments>> getPayments({int page = 1}) async {
    try {
      final payments = await remoteDataSource.getPayments(page);
      return Right(payments);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Server error'));
    } catch (e) {
      return const Left(ServerFailure('Failed to fetch payments'));
    }
  }

  @override
  Future<Either<Failure, Payment>> createPayment(Payment payment) async {
    try {
      final newPayment = await remoteDataSource.createPayment(payment);
      return Right(newPayment);
    } on DioException catch (e) {
       final errors = e.response?.data;
       String message = 'Failed to create payment';
       if (errors is List && errors.isNotEmpty) {
           message = errors[0].toString();
       } else if (errors is Map && errors.isNotEmpty) {
         message = errors.values.first.toString();
       }
       return Left(ServerFailure(message));
    } catch (e) {
      return const Left(ServerFailure('Failed to create payment'));
    }
  }
}
