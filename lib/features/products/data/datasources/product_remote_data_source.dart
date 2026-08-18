import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/product_model.dart';
import '../../domain/entities/product.dart';

abstract class ProductRemoteDataSource {
  Future<PaginatedProductsModel> getProducts(int page, String? search, int? categoryId);
  Future<ProductModel> getProduct(int id);
  Future<ProductModel> createProduct(Product product, {String? imagePath});
  Future<ProductModel> updateProduct(Product product, {String? imagePath});
  Future<void> deleteProduct(int id);
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final ApiClient apiClient;

  ProductRemoteDataSourceImpl(this.apiClient);

  @override
  Future<PaginatedProductsModel> getProducts(int page, String? search, int? categoryId) async {
    final Map<String, dynamic> queryParameters = {'page': page};
    if (search != null && search.isNotEmpty) queryParameters['search'] = search;
    if (categoryId != null) queryParameters['category'] = categoryId;
    
    final response = await apiClient.dio.get('products/', queryParameters: queryParameters);
    return PaginatedProductsModel.fromJson(response.data);
  }

  @override
  Future<ProductModel> getProduct(int id) async {
    final response = await apiClient.dio.get('products/$id/');
    return ProductModel.fromJson(response.data);
  }

  Future<String?> _uploadImage(String imagePath) async {
    try {
      final fileName = imagePath.split('/').last;
      
      // 1. Get presigned URL
      final urlResponse = await apiClient.dio.post('core/generate-upload-url/', data: {
        'file_name': fileName,
        'content_type': 'image/jpeg', // Could be dynamic based on ext
      });
      
      final uploadUrl = urlResponse.data['upload_url'];
      final publicUrl = urlResponse.data['public_url'];
      
      // 2. Upload directly to S3/Supabase
      final file = await MultipartFile.fromFile(imagePath);
      final rawDio = Dio(); // Raw dio without base URL or auth interceptors
      await rawDio.put(
        uploadUrl,
        data: file.finalize(),
        options: Options(
          headers: {
            'Content-Type': 'image/jpeg',
            'Content-Length': file.length,
          },
        ),
      );
      
      return publicUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  @override
  Future<ProductModel> createProduct(Product product, {String? imagePath}) async {
    String? imageUrl;
    if (imagePath != null) {
      imageUrl = await _uploadImage(imagePath);
    }

    final model = ProductModel(
      name: product.name,
      price: product.price,
      categoryId: product.categoryId,
      taxPercentage: product.taxPercentage,
      barcode: product.barcode,
      description: product.description,
      image: imageUrl,
      stock: product.stock,
      status: product.status,
    );

    final response = await apiClient.dio.post('products/', data: model.toJson());
    return ProductModel.fromJson(response.data);
  }

  @override
  Future<ProductModel> updateProduct(Product product, {String? imagePath}) async {
    String? imageUrl = product.image;
    if (imagePath != null) {
      imageUrl = await _uploadImage(imagePath);
    }

    final model = ProductModel(
      id: product.id,
      name: product.name,
      price: product.price,
      categoryId: product.categoryId,
      taxPercentage: product.taxPercentage,
      barcode: product.barcode,
      description: product.description,
      image: imageUrl,
      stock: product.stock,
      status: product.status,
    );

    final response = await apiClient.dio.patch('products/${product.id}/', data: model.toJson());
    return ProductModel.fromJson(response.data);
  }

  @override
  Future<void> deleteProduct(int id) async {
    await apiClient.dio.delete('products/$id/');
  }
}
