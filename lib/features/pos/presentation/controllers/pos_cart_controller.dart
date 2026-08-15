import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/cart_item.dart';
import '../../../products/domain/entities/product.dart';
import '../../../customers/domain/entities/customer.dart';
import '../../domain/repositories/pos_repository.dart';
import '../../../invoices/domain/repositories/invoice_repository.dart';
import '../../../invoices/domain/entities/invoice.dart';

class POSCartState {
  final List<CartItem> items;
  final Customer? customer;
  final double discountPercentage;
  final double discountAmount;
  final bool isProcessing;
  final String? error;

  POSCartState({
    this.items = const [],
    this.customer,
    this.discountPercentage = 0.0,
    this.discountAmount = 0.0,
    this.isProcessing = false,
    this.error,
  });

  double get subtotal {
    return items.fold(0.0, (sum, item) => sum + (item.unitPrice * item.quantity));
  }

  double get taxTotal {
    return items.fold(0.0, (sum, item) => sum + (item.unitPrice * item.quantity * (item.taxPercentage / 100)));
  }

  double get grandTotal {
    final base = subtotal + taxTotal;
    if (discountAmount > 0) {
      return base - discountAmount;
    } else if (discountPercentage > 0) {
      return base - (base * (discountPercentage / 100));
    }
    return base;
  }

  POSCartState copyWith({
    List<CartItem>? items,
    Customer? customer,
    double? discountPercentage,
    double? discountAmount,
    bool? isProcessing,
    String? error,
    bool clearCustomer = false,
    bool clearError = false,
  }) {
    return POSCartState(
      items: items ?? this.items,
      customer: clearCustomer ? null : (customer ?? this.customer),
      discountPercentage: discountPercentage ?? this.discountPercentage,
      discountAmount: discountAmount ?? this.discountAmount,
      isProcessing: isProcessing ?? this.isProcessing,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class POSCartController extends StateNotifier<POSCartState> {
  final InvoiceRepository _invoiceRepository;

  POSCartController(this._invoiceRepository) : super(POSCartState());

  void addProduct(Product product) {
    final existingIndex = state.items.indexWhere((item) => item.product.id == product.id);
    
    if (existingIndex >= 0) {
      final updatedItems = List<CartItem>.from(state.items);
      updatedItems[existingIndex] = updatedItems[existingIndex].copyWith(
        quantity: updatedItems[existingIndex].quantity + 1
      );
      state = state.copyWith(items: updatedItems);
    } else {
      state = state.copyWith(
        items: [...state.items, CartItem(product: product)],
      );
    }
  }

  void updateQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      removeProduct(productId);
      return;
    }
    
    final existingIndex = state.items.indexWhere((item) => item.product.id == productId);
    if (existingIndex >= 0) {
      final updatedItems = List<CartItem>.from(state.items);
      updatedItems[existingIndex] = updatedItems[existingIndex].copyWith(quantity: quantity);
      state = state.copyWith(items: updatedItems);
    }
  }

  void removeProduct(int productId) {
    state = state.copyWith(
      items: state.items.where((item) => item.product.id != productId).toList(),
    );
  }

  void setCustomer(Customer customer) {
    state = state.copyWith(customer: customer);
  }

  void clearCustomer() {
    state = state.copyWith(clearCustomer: true);
  }

  void applyDiscount({double percentage = 0.0, double amount = 0.0}) {
    state = state.copyWith(
      discountPercentage: percentage,
      discountAmount: amount,
    );
  }

  void clearCart() {
    state = POSCartState();
  }

  Future<Invoice?> checkout(double amountPaid, String paymentMethod) async {
    if (state.items.isEmpty) {
      state = state.copyWith(error: 'Cart is empty');
      return null;
    }

    state = state.copyWith(isProcessing: true, clearError: true);

    final invoice = Invoice(
      customerId: state.customer?.id,
      subtotal: state.subtotal,
      discountPercentage: state.discountPercentage,
      discountAmount: state.discountAmount,
      taxTotal: state.taxTotal,
      grandTotal: state.grandTotal,
      amountPaid: amountPaid,
      balanceDue: state.grandTotal - amountPaid > 0 ? state.grandTotal - amountPaid : 0,
      paymentMethod: paymentMethod,
      items: state.items.map((item) => InvoiceItem(
        productId: item.product.id!,
        productName: item.product.name,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        taxPercentage: item.taxPercentage,
        lineTotal: item.unitPrice * item.quantity,
      )).toList(),
    );

    final result = await _invoiceRepository.createInvoice(invoice);

    return result.fold(
      (failure) {
        state = state.copyWith(isProcessing: false, error: failure.message);
        return null;
      },
      (createdInvoice) {
        state = state.copyWith(isProcessing: false);
        return createdInvoice;
      },
    );
  }
}
