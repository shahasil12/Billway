import '../../domain/entities/invoice.dart';
import '../../../customers/data/models/customer_model.dart';
import '../../../payments/data/models/payment_model.dart';

class InvoiceItemModel extends InvoiceItem {
  InvoiceItemModel({
    super.id,
    required super.productId,
    super.productName,
    super.productCategory,
    required super.quantity,
    super.unitPrice,
    super.taxPercentage,
    super.taxAmount,
    super.lineTotal,
  });

  factory InvoiceItemModel.fromJson(Map<String, dynamic> json) {
    return InvoiceItemModel(
      id: json['id'],
      productId: json['product'],
      productName: json['product_name'],
      productCategory: json['product_category'],
      quantity: json['quantity'],
      unitPrice: double.tryParse((json['unit_price'] ?? '0').toString()),
      taxPercentage: double.tryParse((json['tax_percentage'] ?? '0').toString()),
      taxAmount: double.tryParse((json['tax_amount'] ?? '0').toString()),
      lineTotal: double.tryParse((json['line_total'] ?? '0').toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': productId,
      'quantity': quantity,
    };
  }
}

class InvoiceModel extends Invoice {
  InvoiceModel({
    super.id,
    super.customer,
    required super.customerId,
    super.reference,
    super.subtotal,
    super.discountPercentage,
    super.discountAmount,
    super.taxTotal,
    super.grandTotal,
    super.paymentMethod,
    super.status,
    super.createdAt,
    required super.items,
    super.amountPaid = 0,
    super.balanceDue = 0,
    super.payments = const [],
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'],
      customer: json['customer'] != null ? CustomerModel.fromJson(json['customer']) : null,
      customerId: json['customer'] != null ? json['customer']['id'] : 0,
      reference: json['reference'],
      subtotal: double.tryParse((json['subtotal'] ?? '0').toString()) ?? 0,
      discountPercentage: double.tryParse((json['discount_percentage'] ?? '0').toString()) ?? 0,
      discountAmount: double.tryParse((json['discount_amount'] ?? '0').toString()) ?? 0,
      taxTotal: double.tryParse((json['tax_total'] ?? '0').toString()) ?? 0,
      grandTotal: double.tryParse((json['grand_total'] ?? '0').toString()) ?? 0,
      amountPaid: double.tryParse((json['amount_paid'] ?? '0').toString()) ?? 0,
      balanceDue: double.tryParse((json['balance_due'] ?? '0').toString()) ?? 0,
      paymentMethod: json['payment_method'] ?? 'CASH',
      status: json['status'] ?? 'UNPAID',
      createdAt: json['created_at'],
      items: (json['items'] as List?)?.map((i) => InvoiceItemModel.fromJson(i)).toList() ?? [],
      payments: (json['payments'] as List?)?.map((i) => PaymentModel.fromJson(i)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'reference': reference,
      'discount_percentage': discountPercentage,
      'payment_method': paymentMethod,
      'items': items.map((i) => {
        'product': i.productId,
        'quantity': i.quantity,
      }).toList(),
    };
    if (customerId != 0) {
      data['customer'] = customerId;
    }
    return data;
  }
}

class PaginatedInvoicesModel extends PaginatedInvoices {
  PaginatedInvoicesModel({
    required super.count,
    super.next,
    super.previous,
    required super.results,
  });

  factory PaginatedInvoicesModel.fromJson(Map<String, dynamic> json) {
    return PaginatedInvoicesModel(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      results: (json['results'] as List?)?.map((i) => InvoiceModel.fromJson(i)).toList() ?? [],
    );
  }
}
