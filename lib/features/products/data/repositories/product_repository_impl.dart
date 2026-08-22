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
      // Always save locally first — never block on the server (server may be sleeping on free tier)
      final model = ProductModel(
        id: product.id,
        name: product.name,
        categoryId: product.categoryId,
        categoryName: product.categoryName,
        price: product.price,
        taxPercentage: product.taxPercentage,
        barcode: product.barcode,
        description: product.description,
        // Store the local image path so SyncService can upload it later
        image: imagePath ?? product.image,
        productType: product.productType,
        trackStock: product.trackStock,
        minStock: product.minStock,
        unit: product.unit,
        stock: product.stock,
        status: product.status,
      );
      
      final localProduct = await localDataSource.createProduct(model);
      
      // Queue for background sync — SyncService will upload the image when online
      await syncService.addToQueue(
        'CREATE', 
        'PRODUCT', 
        localProduct.toJson(), 
        localId: localProduct.id,
      );
      
      return Right(localProduct);
    } catch (e) {
      return const Left(ServerFailure('Failed to create product'));
    }
  }

  @override
  Future<Either<Failure, Product>> updateProduct(Product product, {String? imagePath}) async {
    try {
      // Always save locally first — never block on the server
      final model = ProductModel(
        id: product.id,
        name: product.name,
        categoryId: product.categoryId,
        categoryName: product.categoryName,
        price: product.price,
        taxPercentage: product.taxPercentage,
        barcode: product.barcode,
        description: product.description,
        // Store the local image path so SyncService can upload it later
        image: imagePath ?? product.image,
        productType: product.productType,
        trackStock: product.trackStock,
        minStock: product.minStock,
        unit: product.unit,
        stock: product.stock,
        status: product.status,
      );
      
      final updatedLocal = await localDataSource.updateProduct(model);
      
      // Queue for background sync — SyncService will upload image when online
      await syncService.addToQueue('UPDATE', 'PRODUCT', updatedLocal.toJson());
      
      return Right(updatedLocal);
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
