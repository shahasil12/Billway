import '../../../invoices/domain/entities/invoice.dart';

class ReportSummary {
  final double totalSales;
  final double totalCollected;
  final double totalPending;
  final int invoiceCount;

  ReportSummary({
    required this.totalSales,
    required this.totalCollected,
    required this.totalPending,
    required this.invoiceCount,
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

  TopProduct({
    required this.productName,
    required this.quantitySold,
    required this.revenue,
  });
}

class Report {
  final ReportSummary summary;
  final List<SalesTrend> salesTrend;
  final List<TopProduct> topProducts;
  final List<Invoice> recentInvoices;

  Report({
    required this.summary,
    required this.salesTrend,
    required this.topProducts,
    required this.recentInvoices,
  });
}
