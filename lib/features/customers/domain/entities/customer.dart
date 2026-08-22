class Customer {
  final int? id;
  final String name;
  final String? email;
  final String? phone;
  final String? createdAt;
  final double creditBalance;

  Customer({
    this.id,
    required this.name,
    this.email,
    this.phone,
    this.createdAt,
    this.creditBalance = 0.0,
  });

  Customer copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? createdAt,
    double? creditBalance,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      creditBalance: creditBalance ?? this.creditBalance,
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
