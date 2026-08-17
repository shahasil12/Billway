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

class SalesTrendModel extends SalesTrend {
  SalesTrendModel({required super.date, required super.total});
  factory SalesTrendModel.fromJson(Map<String, dynamic> json) {
    return SalesTrendModel(
      date: json['date'] ?? '',
      total: double.tryParse(json['total'].toString()) ?? 0.0,
    );
  }
}

class TopProductModel extends TopProduct {
  TopProductModel({required super.productName, required super.quantitySold, required super.revenue});
  factory TopProductModel.fromJson(Map<String, dynamic> json) {
    return TopProductModel(
      productName: json['product_name'] ?? '',
      quantitySold: json['quantity_sold'] ?? 0,
      revenue: double.tryParse(json['revenue'].toString()) ?? 0.0,
    );
  }
}

class PaymentMethodSummaryModel extends PaymentMethodSummary {
  PaymentMethodSummaryModel({required super.method, required super.amount});
  factory PaymentMethodSummaryModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodSummaryModel(
      method: json['method'] ?? '',
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
    );
  }
}

class LowStockProductModel extends LowStockProduct {
  LowStockProductModel({required super.id, required super.name, required super.stock});
  factory LowStockProductModel.fromJson(Map<String, dynamic> json) {
    return LowStockProductModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      stock: json['stock'] ?? 0,
    );
  }
}

class DashboardSummaryModel extends DashboardSummary {
  DashboardSummaryModel({
    required super.todaysSales,
    super.todaysProfit = 0.0,
    required super.todaysInvoiceCount,
    required super.totalCustomers,
    required super.totalProducts,
    required super.recentInvoices,
    super.overdueCredit = 0.0,
    super.salesTrend = const [],
    super.topProducts = const [],
    super.paymentMethods = const [],
    super.lowStockProducts = const [],
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryModel(
      todaysSales: double.tryParse(json['todays_sales'].toString()) ?? 0.0,
      todaysProfit: double.tryParse(json['todays_profit'].toString()) ?? 0.0,
      todaysInvoiceCount: json['todays_invoice_count'] ?? 0,
      totalCustomers: json['total_customers'] ?? 0,
      totalProducts: json['total_products'] ?? 0,
      overdueCredit: double.tryParse(json['overdue_credit'].toString()) ?? 0.0,
      recentInvoices: (json['recent_invoices'] as List?)
              ?.map((i) => RecentInvoiceModel.fromJson(i))
              .toList() ?? [],
      salesTrend: (json['sales_trend'] as List?)
              ?.map((i) => SalesTrendModel.fromJson(i))
              .toList() ?? [],
      topProducts: (json['top_products'] as List?)
              ?.map((i) => TopProductModel.fromJson(i))
              .toList() ?? [],
      paymentMethods: (json['payment_methods'] as List?)
              ?.map((i) => PaymentMethodSummaryModel.fromJson(i))
              .toList() ?? [],
      lowStockProducts: (json['low_stock_products'] as List?)
              ?.map((i) => LowStockProductModel.fromJson(i))
              .toList() ?? [],
    );
  }
}
