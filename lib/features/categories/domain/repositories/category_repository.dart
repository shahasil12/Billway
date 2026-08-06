import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/category.dart';

abstract class CategoryRepository {
  Future<Either<Failure, PaginatedCategories>> getCategories({int page = 1, String? search});
  Future<Either<Failure, Category>> getCategory(int id);
  Future<Either<Failure, Category>> createCategory(Category category);
  Future<Either<Failure, Category>> updateCategory(Category category);
  Future<Either<Failure, void>> deleteCategory(int id);
}
