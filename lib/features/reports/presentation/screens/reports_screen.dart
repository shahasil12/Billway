import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/report_controller.dart';
import '../../domain/entities/report.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reportProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Reports'),
        actions: [
          PopupMenuButton<String>(
            initialValue: state.dateRangeLabel,
            onSelected: (label) => ref.read(reportProvider.notifier).setDateRange(label),
            itemBuilder: (context) => [
              'Today',
              'This Week',
              'This Month',
              'Last 30 Days',
            ].map((label) => PopupMenuItem(value: label, child: Text(label))).toList(),
            icon: const Icon(Icons.date_range),
          ),
        ],
      ),
      body: state.isLoading && state.report == null
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.report == null
              ? Center(child: Text(state.error!, style: const TextStyle(color: Colors.red)))
              : state.report == null
                  ? const Center(child: Text('No data available'))
                  : RefreshIndicator(
                      onRefresh: () => ref.read(reportProvider.notifier).fetchReport(),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(state.dateRangeLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 16),
                            _buildSummaryCards(state.report!.summary),
                            const SizedBox(height: 32),
                            const Text('Sales Trend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            _buildSalesChart(state.report!.salesTrend),
                            const SizedBox(height: 32),
                            const Text('Top Products', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            _buildTopProducts(state.report!.topProducts),
                            const SizedBox(height: 32),
                            const Text('Recent Invoices', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            _buildRecentInvoices(state.report!.recentInvoices),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildSummaryCards(ReportSummary summary) {
    return Column(
      children: [
        _buildMetricCard('Total Sales', '\$${summary.totalSales.toStringAsFixed(2)}', Icons.point_of_sale, Colors.blue),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildMetricCard('Collected', '\$${summary.totalCollected.toStringAsFixed(2)}', Icons.check_circle, Colors.green)),
            const SizedBox(width: 16),
            Expanded(child: _buildMetricCard('Pending', '\$${summary.totalPending.toStringAsFixed(2)}', Icons.pending_actions, Colors.orange)),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesChart(List<SalesTrend> trend) {
    if (trend.isEmpty) {
      return const SizedBox(
        height: 250,
        child: Center(child: Text('No sales data for this period')),
      );
    }

    final maxY = trend.map((e) => e.total).reduce((a, b) => a > b ? a : b);
    
    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                    child: Text(dayStr, style: const TextStyle(fontSize: 10)),
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
              color: Colors.blue,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withOpacity(0.2),
              ),
            ),
          ],
          minX: 0,
          maxX: (trend.length - 1).toDouble(),
          minY: 0,
          maxY: maxY * 1.2,
        ),
      ),
    );
  }

  Widget _buildTopProducts(List<TopProduct> products) {
    if (products.isEmpty) {
      return const Center(child: Text('No products sold'));
    }
    return Card(
      elevation: 2,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: products.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final p = products[index];
          return ListTile(
            leading: CircleAvatar(child: Text('${index + 1}')),
            title: Text(p.productName),
            subtitle: Text('Sold: ${p.quantitySold}'),
            trailing: Text('\$${p.revenue.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          );
        },
      ),
    );
  }

  Widget _buildRecentInvoices(List invoices) {
    if (invoices.isEmpty) {
      return const Center(child: Text('No recent invoices'));
    }
    return Card(
      elevation: 2,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: invoices.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final inv = invoices[index];
          return ListTile(
            title: Text(inv.customer?.name ?? 'Unknown'),
            subtitle: Text('Invoice #${inv.id}'),
            trailing: Text('\$${inv.grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
          );
        },
      ),
    );
  }
}
