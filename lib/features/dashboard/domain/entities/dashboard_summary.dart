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

class SalesTrend {
  final String date;
  final double total;
  SalesTrend({required this.date, required this.total});
}

class TopProduct {
  final String productName;
  final int quantitySold;
  final double revenue;
  TopProduct({required this.productName, required this.quantitySold, required this.revenue});
}

class PaymentMethodSummary {
  final String method;
  final double amount;
  PaymentMethodSummary({required this.method, required this.amount});
}

class LowStockProduct {
  final int id;
  final String name;
  final int stock;
  LowStockProduct({required this.id, required this.name, required this.stock});
}

class DashboardSummary {
  final double todaysSales;
  final double todaysProfit;
  final int todaysInvoiceCount;
  final int totalCustomers;
  final int totalProducts;
  final List<RecentInvoice> recentInvoices;
  final double overdueCredit;
  final List<SalesTrend> salesTrend;
  final List<TopProduct> topProducts;
  final List<PaymentMethodSummary> paymentMethods;
  final List<LowStockProduct> lowStockProducts;

  DashboardSummary({
    required this.todaysSales,
    this.todaysProfit = 0.0,
    required this.todaysInvoiceCount,
    required this.totalCustomers,
    required this.totalProducts,
    required this.recentInvoices,
    this.overdueCredit = 0.0,
    this.salesTrend = const [],
    this.topProducts = const [],
    this.paymentMethods = const [],
    this.lowStockProducts = const [],
  });
}
