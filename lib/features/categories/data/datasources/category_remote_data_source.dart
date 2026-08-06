import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/category_model.dart';
import '../../domain/entities/category.dart';

abstract class CategoryRemoteDataSource {
  Future<PaginatedCategoriesModel> getCategories(int page, String? search);
  Future<CategoryModel> getCategory(int id);
  Future<CategoryModel> createCategory(Category category);
  Future<CategoryModel> updateCategory(Category category);
  Future<void> deleteCategory(int id);
}

class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  final ApiClient apiClient;

  CategoryRemoteDataSourceImpl(this.apiClient);

  @override
  Future<PaginatedCategoriesModel> getCategories(int page, String? search) async {
    final Map<String, dynamic> queryParameters = {'page': page};
    if (search != null && search.isNotEmpty) {
      queryParameters['search'] = search;
    }
    final response = await apiClient.dio.get('categories/', queryParameters: queryParameters);
    return PaginatedCategoriesModel.fromJson(response.data);
  }

  @override
  Future<CategoryModel> getCategory(int id) async {
    final response = await apiClient.dio.get('categories/$id/');
    return CategoryModel.fromJson(response.data);
  }

  @override
  Future<CategoryModel> createCategory(Category category) async {
    final model = CategoryModel(name: category.name, description: category.description);
    final response = await apiClient.dio.post('categories/', data: model.toJson());
    return CategoryModel.fromJson(response.data);
  }

  @override
  Future<CategoryModel> updateCategory(Category category) async {
    final model = CategoryModel(id: category.id, name: category.name, description: category.description);
    final response = await apiClient.dio.put('categories/${category.id}/', data: model.toJson());
    return CategoryModel.fromJson(response.data);
  }

  @override
  Future<void> deleteCategory(int id) async {
    await apiClient.dio.delete('categories/$id/');
  }
}
