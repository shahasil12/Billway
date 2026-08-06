import '../../domain/entities/category.dart';

class CategoryModel extends Category {
  CategoryModel({
    super.id,
    required super.name,
    super.description,
    super.createdAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
    };
  }
}

class PaginatedCategoriesModel extends PaginatedCategories {
  PaginatedCategoriesModel({
    required super.count,
    super.next,
    super.previous,
    required super.results,
  });

  factory PaginatedCategoriesModel.fromJson(Map<String, dynamic> json) {
    return PaginatedCategoriesModel(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      results: (json['results'] as List?)?.map((i) => CategoryModel.fromJson(i)).toList() ?? [],
    );
  }
}
