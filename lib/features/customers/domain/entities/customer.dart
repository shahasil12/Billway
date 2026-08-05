class Customer {
  final int? id;
  final String name;
  final String? email;
  final String? phone;
  final String? createdAt;

  Customer({
    this.id,
    required this.name,
    this.email,
    this.phone,
    this.createdAt,
  });

  Customer copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class PaginatedCustomers {
  final int count;
  final String? next;
  final String? previous;
  final List<Customer> results;

  PaginatedCustomers({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });
}
