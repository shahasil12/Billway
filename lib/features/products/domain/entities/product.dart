class Product {
  final int? id;
  final String name;
  final int? categoryId;
  final String? categoryName;
  final double price;
  final double taxPercentage;
  final String? barcode;
  final String? description;
  final String? image;
  final int stock;
  final bool status;
  final String? createdAt;

  Product({
    this.id,
    required this.name,
    this.categoryId,
    this.categoryName,
    required this.price,
    this.taxPercentage = 0.0,
    this.barcode,
    this.description,
    this.image,
    this.stock = 0,
    this.status = true,
    this.createdAt,
  });

  Product copyWith({
    int? id,
    String? name,
    int? categoryId,
    String? categoryName,
    double? price,
    double? taxPercentage,
    String? barcode,
    String? description,
    String? image,
    int? stock,
    bool? status,
    String? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      price: price ?? this.price,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      barcode: barcode ?? this.barcode,
      description: description ?? this.description,
      image: image ?? this.image,
      stock: stock ?? this.stock,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class PaginatedProducts {
  final int count;
  final String? next;
  final String? previous;
  final List<Product> results;

  PaginatedProducts({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });
}
