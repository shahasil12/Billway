import '../../../products/domain/entities/product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  CartItem copyWith({
    Product? product,
    int? quantity,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  double get unitPrice => product.price;
  double get taxPercentage => product.taxPercentage;
  
  double get lineTotal {
    final baseTotal = unitPrice * quantity;
    final taxAmount = baseTotal * (taxPercentage / 100);
    return baseTotal + taxAmount;
  }
}
