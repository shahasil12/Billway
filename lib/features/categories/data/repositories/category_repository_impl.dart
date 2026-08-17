import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/database/database_helper.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_remote_data_source.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDataSource remoteDataSource;
  final DatabaseHelper dbHelper;

  CategoryRepositoryImpl(this.remoteDataSource, this.dbHelper);

  @override
  Future<Either<Failure, PaginatedCategories>> getCategories({int page = 1, String? search}) async {
    try {
      final localMaps = await dbHelper.getLocalCategories(search: search);

      // Always fire a background sync to keep local cache fresh
      _syncRemoteCategories();

      final localCats = localMaps.map(_mapToCategory).toList();
      return Right(PaginatedCategories(count: localCats.length, results: localCats));
    } catch (e) {
      return Left(ServerFailure('Failed to fetch categories: $e'));
    }
  }

  Future<void> _syncRemoteCategories() async {
    try {
      final remote = await remoteDataSource.getCategories(1, null);
      final maps = remote.results.map((c) => {
        'id': c.id,
        'name': c.name,
        'description': c.description,
        'created_at': c.createdAt,
      }).toList();
      await dbHelper.upsertCategories(maps);
    } catch (_) {
      // Ignore — we already returned local data
    }
  }

  Category _mapToCategory(Map<String, dynamic> m) {
    return Category(
      id: m['id'] as int?,
      name: m['name'] as String,
      description: m['description'] as String?,
      createdAt: m['created_at'] as String?,
    );
  }

  @override
  Future<Either<Failure, Category>> getCategory(int id) async {
    try {
      final category = await remoteDataSource.getCategory(id);
      return Right(category);
    } catch (e) {
      return Left(ServerFailure('Failed to get category: $e'));
    }
  }

  @override
  Future<Either<Failure, Category>> createCategory(Category category) async {
    try {
      final newCategory = await remoteDataSource.createCategory(category);
      // Cache it locally
      await dbHelper.upsertCategories([{
        'id': newCategory.id,
        'name': newCategory.name,
        'description': newCategory.description,
        'created_at': newCategory.createdAt,
      }]);
      return Right(newCategory);
    } catch (e) {
      final msg = e.toString();
      return Left(ServerFailure(msg));
    }
  }

  @override
  Future<Either<Failure, Category>> updateCategory(Category category) async {
    try {
      final updated = await remoteDataSource.updateCategory(category);
      await dbHelper.upsertCategories([{
        'id': updated.id,
        'name': updated.name,
        'description': updated.description,
        'created_at': updated.createdAt,
      }]);
      return Right(updated);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCategory(int id) async {
    try {
      await remoteDataSource.deleteCategory(id);
      // Also remove from local cache
      final db = await dbHelper.database;
      await db.delete('categories', where: 'id = ?', whereArgs: [id]);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
