import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/report_controller.dart';
import '../../domain/entities/report.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_containers.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reportProvider);
    final currency = ref.watch(settingsProvider).settings?.currency ?? '\$';
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16),
            child: PopupMenuButton<String>(
              initialValue: state.dateRangeLabel,
              onSelected: (label) => ref.read(reportProvider.notifier).setDateRange(label),
              itemBuilder: (context) => [
                'Today',
                'This Week',
                'This Month',
                'Last 30 Days',
              ].map((label) => PopupMenuItem(
                value: label, 
                child: Text(label, style: AppTextStyles.bodyMedium),
              )).toList(),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p12, vertical: AppSpacing.p8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.date_range, size: 20, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.p8),
                    Text(state.dateRangeLabel, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(context, ref, state, currency, isTablet),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, ReportState state, String currency, bool isTablet) {
    if (state.isLoading && state.report == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.report == null) {
      return Center(child: Text(state.error!, style: const TextStyle(color: AppColors.error)));
    }

    if (state.report == null) {
      return const Center(child: Text('No data available', style: TextStyle(color: AppColors.textSecondary)));
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(reportProvider.notifier).fetchReport(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? AppSpacing.p32 : AppSpacing.p16,
          vertical: AppSpacing.p24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSummaryCards(state.report!.summary, currency, isTablet),
            const SizedBox(height: AppSpacing.p32),
            
            Text('Sales Trend', style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.p16),
            _buildSalesChart(state.report!.salesTrend),
            const SizedBox(height: AppSpacing.p32),
            
            if (isTablet)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Top Products', style: AppTextStyles.h3),
                        const SizedBox(height: AppSpacing.p16),
                        _buildTopProducts(state.report!.topProducts, currency),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.p24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Recent Invoices', style: AppTextStyles.h3),
                        const SizedBox(height: AppSpacing.p16),
                        _buildRecentInvoices(state.report!.recentInvoices, currency),
                      ],
                    ),
                  ),
                ],
              )
            else ...[
              Text('Top Products', style: AppTextStyles.h3),
              const SizedBox(height: AppSpacing.p16),
              _buildTopProducts(state.report!.topProducts, currency),
              const SizedBox(height: AppSpacing.p32),
              
              Text('Recent Invoices', style: AppTextStyles.h3),
              const SizedBox(height: AppSpacing.p16),
              _buildRecentInvoices(state.report!.recentInvoices, currency),
            ],
            
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(ReportSummary summary, String currency, bool isTablet) {
    final cards = [
      _buildMetricCard('Total Sales', '$currency${summary.totalSales.toStringAsFixed(2)}', Icons.point_of_sale, AppColors.primary),
      _buildMetricCard('Collected', '$currency${summary.totalCollected.toStringAsFixed(2)}', Icons.check_circle, AppColors.success),
      _buildMetricCard('Pending', '$currency${summary.totalPending.toStringAsFixed(2)}', Icons.pending_actions, AppColors.warning),
    ];

    if (isTablet) {
      return Row(
        children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: AppSpacing.p16), child: c))).toList(),
      );
    } else {
      return Column(
        children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: AppSpacing.p16), child: c)).toList(),
      );
    }
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.p16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: AppSpacing.p16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(value, style: AppTextStyles.h2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesChart(List<SalesTrend> trend) {
    if (trend.isEmpty) {
      return AppCard(
        child: SizedBox(
          height: 250,
          child: Center(
            child: Text('No sales data for this period', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          ),
        ),
      );
    }

    final maxY = trend.map((e) => e.total).reduce((a, b) => a > b ? a : b);
    
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.p24),
      child: SizedBox(
        height: 250,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: AppColors.border,
                strokeWidth: 1,
                dashArray: [5, 5],
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    if (value == 0) return const SizedBox.shrink();
                    return Text(value.toInt().toString(), style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary));
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: (trend.length / 5).ceilToDouble(),
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= trend.length) return const SizedBox.shrink();
                    final date = trend[index].date;
                    final dayStr = date.substring(8, 10);
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(dayStr, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: trend.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.total)).toList(),
                isCurved: true,
                color: AppColors.primary,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.3),
                      AppColors.primary.withOpacity(0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
            minX: 0,
            maxX: (trend.length - 1).toDouble(),
            minY: 0,
            maxY: maxY * 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildTopProducts(List<TopProduct> products, String currency) {
    if (products.isEmpty) {
      return AppCard(child: const Center(child: Text('No products sold')));
    }
    return AppCard(
      padding: EdgeInsets.zero,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: products.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final p = products[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16, vertical: AppSpacing.p8),
            leading: CircleAvatar(
              backgroundColor: AppColors.surfaceAlt,
              child: Text('${index + 1}', style: const TextStyle(color: AppColors.textPrimary)),
            ),
            title: Text(p.productName, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Text('Sold: ${p.quantitySold}', style: AppTextStyles.caption),
            trailing: Text(
              '$currency${p.revenue.toStringAsFixed(2)}', 
              style: AppTextStyles.financialLine.copyWith(fontWeight: FontWeight.w700, color: AppColors.success),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentInvoices(List invoices, String currency) {
    if (invoices.isEmpty) {
      return AppCard(child: const Center(child: Text('No recent invoices')));
    }
    return AppCard(
      padding: EdgeInsets.zero,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: invoices.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final inv = invoices[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16, vertical: AppSpacing.p8),
            leading: const CircleAvatar(
              backgroundColor: AppColors.primaryLight,
              child: Icon(Icons.receipt, color: AppColors.primary, size: 20),
            ),
            title: Text(inv.customer?.name ?? 'Unknown', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Text('Invoice #${inv.id}', style: AppTextStyles.caption),
            trailing: Text(
              '$currency${inv.grandTotal.toStringAsFixed(2)}', 
              style: AppTextStyles.financialLine.copyWith(fontWeight: FontWeight.w700),
            ),
          );
        },
      ),
    );
  }
}
