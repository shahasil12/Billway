import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_data_source.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;

  ProductRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, PaginatedProducts>> getProducts({int page = 1, String? search, int? categoryId}) async {
    try {
      final products = await remoteDataSource.getProducts(page, search, categoryId);
      return Right(products);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Server error'));
    } catch (e) {
      return const Left(ServerFailure('Failed to fetch products'));
    }
  }

  @override
  Future<Either<Failure, Product>> getProduct(int id) async {
    try {
      final product = await remoteDataSource.getProduct(id);
      return Right(product);
    } catch (e) {
      return const Left(ServerFailure('Failed to get product'));
    }
  }

  @override
  Future<Either<Failure, Product>> createProduct(Product product, {String? imagePath}) async {
    try {
      final newProduct = await remoteDataSource.createProduct(product, imagePath: imagePath);
      return Right(newProduct);
    } on DioException catch (e) {
       final errors = e.response?.data;
       String message = 'Failed to create product';
       if (errors is Map) {
         message = errors.values.first.toString();
       }
       return Left(ServerFailure(message));
    } catch (e) {
      return const Left(ServerFailure('Failed to create product'));
    }
  }

  @override
  Future<Either<Failure, Product>> updateProduct(Product product, {String? imagePath}) async {
    try {
      final updatedProduct = await remoteDataSource.updateProduct(product, imagePath: imagePath);
      return Right(updatedProduct);
    } on DioException catch (e) {
       final errors = e.response?.data;
       String message = 'Failed to update product';
       if (errors is Map) {
         message = errors.values.first.toString();
       }
       return Left(ServerFailure(message));
    } catch (e) {
      return const Left(ServerFailure('Failed to update product'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProduct(int id) async {
    try {
      await remoteDataSource.deleteProduct(id);
      return const Right(null);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 && e.response?.data['detail'] != null) {
        return Left(ServerFailure(e.response!.data['detail']));
      }
      return const Left(ServerFailure('Failed to delete product'));
    } catch (e) {
      return const Left(ServerFailure('Failed to delete product'));
    }
  }
}
