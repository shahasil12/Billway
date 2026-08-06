import '../../customers/domain/entities/customer.dart';
import '../../products/domain/entities/product.dart';

class InvoiceItem {
  final int? id;
  final int productId;
  final String? productName;
  final String? productCategory;
  final int quantity;
  final double? unitPrice;
  final double? taxPercentage;
  final double? taxAmount;
  final double? lineTotal;

  InvoiceItem({
    this.id,
    required this.productId,
    this.productName,
    this.productCategory,
    required this.quantity,
    this.unitPrice,
    this.taxPercentage,
    this.taxAmount,
    this.lineTotal,
  });
}

class Invoice {
  final int? id;
  final Customer? customer;
  final int customerId; // Used for creation
  final double subtotal;
  final double discountPercentage;
  final double discountAmount;
  final double taxTotal;
  final double grandTotal;
  final String paymentMethod;
  final String status;
  final String? createdAt;
  final List<InvoiceItem> items;

  Invoice({
    this.id,
    this.customer,
    required this.customerId,
    this.subtotal = 0.0,
    this.discountPercentage = 0.0,
    this.discountAmount = 0.0,
    this.taxTotal = 0.0,
    this.grandTotal = 0.0,
    this.paymentMethod = 'CASH',
    this.status = 'UNPAID',
    this.createdAt,
    required this.items,
  });
}

class PaginatedInvoices {
  final int count;
  final String? next;
  final String? previous;
  final List<Invoice> results;

  PaginatedInvoices({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });
}
