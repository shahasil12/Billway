class RecentInvoice {
  final int id;
  final String customerName;
  final String? reference;
  final double totalAmount;
  final String createdAt;

  RecentInvoice({
    required this.id,
    required this.customerName,
    this.reference,
    required this.totalAmount,
    required this.createdAt,
  });
}

class DashboardSummary {
  final double todaysSales;
  final int todaysInvoiceCount;
  final int totalCustomers;
  final int totalProducts;
  final List<RecentInvoice> recentInvoices;

  DashboardSummary({
    required this.todaysSales,
    required this.todaysInvoiceCount,
    required this.totalCustomers,
    required this.totalProducts,
    required this.recentInvoices,
  });
}
