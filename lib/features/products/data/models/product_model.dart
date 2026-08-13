import '../../domain/entities/product.dart';

class ProductModel extends Product {
  ProductModel({
    super.id,
    required super.name,
    super.categoryId,
    super.categoryName,
    required super.price,
    super.taxPercentage,
    super.barcode,
    super.description,
    super.image,
    super.stock,
    super.status,
    super.createdAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      name: json['name'],
      categoryId: json['category'],
      categoryName: json['category_name'],
      price: double.parse(json['price'].toString()),
      taxPercentage: double.parse((json['tax_percentage'] ?? 0.0).toString()),
      barcode: json['barcode'],
      description: json['description'],
      image: json['image_url'] ?? json['image'], // prefer full URL
      stock: json['stock'] ?? 0,
      status: json['status'] ?? true,
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (categoryId != null) 'category': categoryId,
      'price': price,
      'tax_percentage': taxPercentage,
      if (barcode != null) 'barcode': barcode,
      if (description != null) 'description': description,
      'stock': stock,
      'status': status,
    };
  }
}

class PaginatedProductsModel extends PaginatedProducts {
  PaginatedProductsModel({
    required super.count,
    super.next,
    super.previous,
    required super.results,
  });

  factory PaginatedProductsModel.fromJson(Map<String, dynamic> json) {
    return PaginatedProductsModel(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      results: (json['results'] as List?)?.map((i) => ProductModel.fromJson(i)).toList() ?? [],
    );
  }
}
