import '../../domain/entities/dashboard_summary.dart';

class RecentInvoiceModel extends RecentInvoice {
  RecentInvoiceModel({
    required super.id,
    required super.customerName,
    super.reference,
    required super.totalAmount,
    required super.createdAt,
  });

  factory RecentInvoiceModel.fromJson(Map<String, dynamic> json) {
    return RecentInvoiceModel(
      id: json['id'],
      customerName: json['customer'] != null ? json['customer']['name'] : 'Unknown',
      reference: json['reference'],
      totalAmount: double.tryParse((json['grand_total'] ?? 0).toString()) ?? 0.0,
      createdAt: json['created_at'] ?? '',
    );
  }
}

class DashboardSummaryModel extends DashboardSummary {
  DashboardSummaryModel({
    required super.todaysSales,
    required super.todaysInvoiceCount,
    required super.totalCustomers,
    required super.totalProducts,
    required super.recentInvoices,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryModel(
      todaysSales: double.tryParse(json['todays_sales'].toString()) ?? 0.0,
      todaysInvoiceCount: json['todays_invoice_count'] ?? 0,
      totalCustomers: json['total_customers'] ?? 0,
      totalProducts: json['total_products'] ?? 0,
      recentInvoices: (json['recent_invoices'] as List?)
              ?.map((i) => RecentInvoiceModel.fromJson(i))
              .toList() ??
          [],
    );
  }
}
