import '../../domain/entities/payment.dart';

class PaymentModel extends Payment {
  PaymentModel({
    super.id,
    required super.invoiceId,
    required super.amount,
    super.paymentMethod,
    super.referenceNumber,
    super.notes,
    super.paymentDate,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'],
      invoiceId: json['invoice'],
      amount: double.tryParse((json['amount'] ?? '0').toString()) ?? 0.0,
      paymentMethod: json['payment_method'] ?? 'CASH',
      referenceNumber: json['reference_number'],
      notes: json['notes'],
      paymentDate: json['payment_date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invoice': invoiceId,
      'amount': amount,
      'payment_method': paymentMethod,
      'reference_number': referenceNumber,
      'notes': notes,
    };
  }
}

class PaginatedPaymentsModel extends PaginatedPayments {
  PaginatedPaymentsModel({
    required super.count,
    super.next,
    super.previous,
    required super.results,
  });

  factory PaginatedPaymentsModel.fromJson(Map<String, dynamic> json) {
    return PaginatedPaymentsModel(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      results: (json['results'] as List?)?.map((i) => PaymentModel.fromJson(i)).toList() ?? [],
    );
  }
}
