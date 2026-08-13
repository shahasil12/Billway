import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/pos_session.dart';
import '../../domain/repositories/pos_repository.dart';
import '../../../invoices/domain/entities/invoice.dart';
import '../datasources/pos_remote_data_source.dart';

class POSRepositoryImpl implements POSRepository {
  final POSRemoteDataSource remoteDataSource;

  POSRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, POSSession?>> getCurrentSession() async {
    try {
      final session = await remoteDataSource.getCurrentSession();
      return Right(session);
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        return const Right(null);
      }
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, POSSession>> openSession(double openingCash) async {
    try {
      final session = await remoteDataSource.openSession(openingCash);
      return Right(session);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, POSSession>> closeSession(String sessionId, double closingCash) async {
    try {
      final session = await remoteDataSource.closeSession(sessionId, closingCash);
      return Right(session);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Invoice>> checkout(Map<String, dynamic> checkoutData) async {
    try {
      final invoice = await remoteDataSource.checkout(checkoutData);
      return Right(invoice);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
