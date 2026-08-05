import '../../domain/entities/customer.dart';

class CustomerModel extends Customer {
  CustomerModel({
    super.id,
    required super.name,
    super.email,
    super.phone,
    super.createdAt,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      'phone': phone,
    };
  }
}

class PaginatedCustomersModel extends PaginatedCustomers {
  PaginatedCustomersModel({
    required super.count,
    super.next,
    super.previous,
    required super.results,
  });

  factory PaginatedCustomersModel.fromJson(Map<String, dynamic> json) {
    return PaginatedCustomersModel(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      results: (json['results'] as List?)?.map((i) => CustomerModel.fromJson(i)).toList() ?? [],
    );
  }
}
