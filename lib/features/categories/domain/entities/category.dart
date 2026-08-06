class Category {
  final int? id;
  final String name;
  final String? description;
  final String? createdAt;

  Category({
    this.id,
    required this.name,
    this.description,
    this.createdAt,
  });

  Category copyWith({
    int? id,
    String? name,
    String? description,
    String? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class PaginatedCategories {
  final int count;
  final String? next;
  final String? previous;
  final List<Category> results;

  PaginatedCategories({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });
}
