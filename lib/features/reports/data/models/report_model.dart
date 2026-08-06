import '../../domain/entities/report.dart';
import '../../../../features/invoices/data/models/invoice_model.dart';

class ReportModel extends Report {
  ReportModel({
    required super.summary,
    required super.salesTrend,
    required super.topProducts,
    required super.recentInvoices,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      summary: ReportSummaryModel.fromJson(json['summary'] ?? {}),
      salesTrend: (json['sales_trend'] as List?)?.map((i) => SalesTrendModel.fromJson(i)).toList() ?? [],
      topProducts: (json['top_products'] as List?)?.map((i) => TopProductModel.fromJson(i)).toList() ?? [],
      recentInvoices: (json['recent_invoices'] as List?)?.map((i) => InvoiceModel.fromJson(i)).toList() ?? [],
    );
  }
}

class ReportSummaryModel extends ReportSummary {
  ReportSummaryModel({
    required super.totalSales,
    required super.totalCollected,
    required super.totalPending,
    required super.invoiceCount,
  });

  factory ReportSummaryModel.fromJson(Map<String, dynamic> json) {
    return ReportSummaryModel(
      totalSales: double.tryParse((json['total_sales'] ?? '0').toString()) ?? 0,
      totalCollected: double.tryParse((json['total_collected'] ?? '0').toString()) ?? 0,
      totalPending: double.tryParse((json['total_pending'] ?? '0').toString()) ?? 0,
      invoiceCount: json['invoice_count'] ?? 0,
    );
  }
}

class SalesTrendModel extends SalesTrend {
  SalesTrendModel({required super.date, required super.total});

  factory SalesTrendModel.fromJson(Map<String, dynamic> json) {
    return SalesTrendModel(
      date: json['date'] ?? '',
      total: double.tryParse((json['total'] ?? '0').toString()) ?? 0,
    );
  }
}

class TopProductModel extends TopProduct {
  TopProductModel({
    required super.productName,
    required super.quantitySold,
    required super.revenue,
  });

  factory TopProductModel.fromJson(Map<String, dynamic> json) {
    return TopProductModel(
      productName: json['product_name'] ?? 'Unknown',
      quantitySold: json['quantity_sold'] ?? 0,
      revenue: double.tryParse((json['revenue'] ?? '0').toString()) ?? 0,
    );
  }
}
