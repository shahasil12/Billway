class Payment {
  final int? id;
  final int invoiceId;
  final double amount;
  final String paymentMethod;
  final String? referenceNumber;
  final String? notes;
  final String? paymentDate;

  Payment({
    this.id,
    required this.invoiceId,
    required this.amount,
    this.paymentMethod = 'CASH',
    this.referenceNumber,
    this.notes,
    this.paymentDate,
  });
}

class PaginatedPayments {
  final int count;
  final String? next;
  final String? previous;
  final List<Payment> results;

  PaginatedPayments({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });
}
