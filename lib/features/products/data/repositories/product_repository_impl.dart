import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/sync/sync_service.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_data_source.dart';
import '../datasources/product_local_data_source.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;
  final ProductLocalDataSource localDataSource;
  final SyncService syncService;

  ProductRepositoryImpl(this.remoteDataSource, this.localDataSource, this.syncService);

  @override
  Future<Either<Failure, PaginatedProducts>> getProducts({int page = 1, String? search, int? categoryId}) async {
    try {
      final localProducts = await localDataSource.getProducts(search: search, categoryId: categoryId);
      
      // Fire and forget background sync
      _syncRemoteProducts(page, search, categoryId);
      
      return Right(PaginatedProductsModel(count: localProducts.length, results: localProducts));
    } catch (e) {
      return const Left(ServerFailure('Failed to fetch products'));
    }
  }

  Future<void> _syncRemoteProducts(int page, String? search, int? categoryId) async {
    try {
      final remoteProducts = await remoteDataSource.getProducts(page, search, categoryId);
      await localDataSource.upsertProducts(remoteProducts.results as List<ProductModel>);
    } catch (_) {
      // Ignore background sync errors
    }
  }

  @override
  Future<Either<Failure, Product>> getProduct(int id) async {
    try {
      final localProduct = await localDataSource.getProduct(id);
      if (localProduct != null) {
        try {
          final remoteProduct = await remoteDataSource.getProduct(id);
          await localDataSource.upsertProducts([remoteProduct]);
          return Right(remoteProduct);
        } catch (e) {
          return Right(localProduct);
        }
      } else {
        final remoteProduct = await remoteDataSource.getProduct(id);
        await localDataSource.upsertProducts([remoteProduct]);
        return Right(remoteProduct);
      }
    } catch (e) {
      return const Left(ServerFailure('Failed to get product'));
    }
  }

  @override
  Future<Either<Failure, Product>> createProduct(Product product, {String? imagePath}) async {
    try {
      int? remoteId = product.id;
      String? finalImageUrl = product.image;
      if (imagePath != null) {
        try {
          final remoteModel = await remoteDataSource.createProduct(product, imagePath: imagePath);
          finalImageUrl = remoteModel.image;
          remoteId = remoteModel.id;
        } catch (_) {}
      }

      final model = ProductModel(
        id: remoteId,
        name: product.name,
        categoryId: product.categoryId,
        categoryName: product.categoryName,
        price: product.price,
        taxPercentage: product.taxPercentage,
        barcode: product.barcode,
        description: product.description,
        image: finalImageUrl,
        productType: product.productType,
        trackStock: product.trackStock,
        minStock: product.minStock,
        unit: product.unit,
        stock: product.stock,
        status: product.status,
      );
      
      final localProduct = await localDataSource.createProduct(model);
      
      // If we didn't successfully create it remotely with the image, add to queue
      if (imagePath == null || finalImageUrl == product.image) {
        await syncService.addToQueue('CREATE', 'PRODUCT', localProduct.toJson(), localId: localProduct.id);
      } else {
        // We already created it remotely, mark it as synced
        final syncedModel = ProductModel(
          id: remoteId ?? localProduct.id,
          name: model.name,
          categoryId: model.categoryId,
          categoryName: model.categoryName,
          price: model.price,
          taxPercentage: model.taxPercentage,
          barcode: model.barcode,
          description: model.description,
          image: model.image,
          productType: model.productType,
          trackStock: model.trackStock,
          minStock: model.minStock,
          unit: model.unit,
          stock: model.stock,
          status: model.status,
        );
        await localDataSource.upsertProducts([syncedModel]);
        
        // Ensure local_id maps to remote id if it was just created
        if (remoteId != null && localProduct.id != remoteId) {
            final db = await (localDataSource as ProductLocalDataSourceImpl).dbHelper.database;
            await db.update('products', {'id': remoteId, 'is_synced': 1}, where: 'local_id = ?', whereArgs: [localProduct.id]);
        }
      }
      
      return Right(localProduct);
    } catch (e) {
      return const Left(ServerFailure('Failed to create product'));
    }
  }

  @override
  Future<Either<Failure, Product>> updateProduct(Product product, {String? imagePath}) async {
    try {
      String? finalImageUrl = product.image;
      if (imagePath != null) {
        try {
          final remoteModel = await remoteDataSource.updateProduct(product, imagePath: imagePath);
          finalImageUrl = remoteModel.image;
        } catch (_) {}
      }

      final model = ProductModel(
        id: product.id,
        name: product.name,
        categoryId: product.categoryId,
        categoryName: product.categoryName,
        price: product.price,
        taxPercentage: product.taxPercentage,
        barcode: product.barcode,
        description: product.description,
        image: finalImageUrl,
        productType: product.productType,
        trackStock: product.trackStock,
        minStock: product.minStock,
        unit: product.unit,
        stock: product.stock,
        status: product.status,
      );
      
      // If we didn't successfully update it remotely with the image, add to queue
      if (imagePath == null || finalImageUrl == product.image) {
        final updatedLocal = await localDataSource.updateProduct(model);
        await syncService.addToQueue('UPDATE', 'PRODUCT', updatedLocal.toJson());
        return Right(updatedLocal);
      } else {
        // We already updated it remotely! Mark it as synced locally instead of dirty.
        // But localDataSource.updateProduct marks it dirty.
        // We can just use upsertProducts, which forces is_synced=1, BUT upsertProducts ignores dirty items.
        // So we must manually update it or just clear the dirty flag.
        final db = await (localDataSource as ProductLocalDataSourceImpl).dbHelper.database;
        final data = {
          'name': model.name,
          'category_id': model.categoryId,
          'category_name': model.categoryName,
          'price': model.price,
          'tax_percentage': model.taxPercentage,
          'barcode': model.barcode,
          'description': model.description,
          'image_url': model.image,
          'stock': model.stock,
          'status': model.status == true ? 1 : 0,
          'is_synced': 1,
        };
        await db.update(
          'products', 
          data, 
          where: 'id = ? OR local_id = ?', 
          whereArgs: [model.id, model.id]
        );
        return Right(model);
      }
    } catch (e) {
      return const Left(ServerFailure('Failed to update product'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProduct(int id) async {
    try {
      await localDataSource.deleteProduct(id);
      await syncService.addToQueue('DELETE', 'PRODUCT', {'id': id});
      
      return const Right(null);
    } catch (e) {
      return const Left(ServerFailure('Failed to delete product'));
    }
  }
}
