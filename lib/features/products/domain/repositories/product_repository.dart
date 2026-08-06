import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/product.dart';

abstract class ProductRepository {
  Future<Either<Failure, PaginatedProducts>> getProducts({int page = 1, String? search, int? categoryId});
  Future<Either<Failure, Product>> getProduct(int id);
  Future<Either<Failure, Product>> createProduct(Product product, {String? imagePath});
  Future<Either<Failure, Product>> updateProduct(Product product, {String? imagePath});
  Future<Either<Failure, void>> deleteProduct(int id);
}
