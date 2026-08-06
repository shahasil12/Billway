import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_remote_data_source.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDataSource remoteDataSource;

  CategoryRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, PaginatedCategories>> getCategories({int page = 1, String? search}) async {
    try {
      final categories = await remoteDataSource.getCategories(page, search);
      return Right(categories);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Server error'));
    } catch (e) {
      return const Left(ServerFailure('Failed to fetch categories'));
    }
  }

  @override
  Future<Either<Failure, Category>> getCategory(int id) async {
    try {
      final category = await remoteDataSource.getCategory(id);
      return Right(category);
    } catch (e) {
      return const Left(ServerFailure('Failed to get category'));
    }
  }

  @override
  Future<Either<Failure, Category>> createCategory(Category category) async {
    try {
      final newCategory = await remoteDataSource.createCategory(category);
      return Right(newCategory);
    } on DioException catch (e) {
       final errors = e.response?.data;
       String message = 'Failed to create category';
       if (errors is Map) {
         message = errors.values.first.toString();
       }
       return Left(ServerFailure(message));
    } catch (e) {
      return const Left(ServerFailure('Failed to create category'));
    }
  }

  @override
  Future<Either<Failure, Category>> updateCategory(Category category) async {
    try {
      final updatedCategory = await remoteDataSource.updateCategory(category);
      return Right(updatedCategory);
    } on DioException catch (e) {
       final errors = e.response?.data;
       String message = 'Failed to update category';
       if (errors is Map) {
         message = errors.values.first.toString();
       }
       return Left(ServerFailure(message));
    } catch (e) {
      return const Left(ServerFailure('Failed to update category'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCategory(int id) async {
    try {
      await remoteDataSource.deleteCategory(id);
      return const Right(null);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 && e.response?.data['detail'] != null) {
        return Left(ServerFailure(e.response!.data['detail']));
      }
      return const Left(ServerFailure('Failed to delete category'));
    } catch (e) {
      return const Left(ServerFailure('Failed to delete category'));
    }
  }
}
