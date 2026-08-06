import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/providers.dart';
import '../controllers/dashboard_controller.dart';
import '../../reports/presentation/controllers/report_controller.dart';
import '../../domain/entities/dashboard_summary.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final reportState = ref.watch(reportProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text('Billway App', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                context.pop(); // close drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Customers'),
              onTap: () {
                context.pop();
                context.push('/customers');
              },
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Categories'),
              onTap: () {
                context.pop();
                context.push('/categories');
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Products'),
              onTap: () {
                context.pop();
                context.push('/products');
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt),
              title: const Text('Invoices'),
              onTap: () {
                context.pop();
                context.push('/invoices');
              },
            ),
            ListTile(
              leading: const Icon(Icons.payments),
              title: const Text('Payments'),
              onTap: () {
                context.pop();
                context.push('/payments');
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Reports'),
              onTap: () {
                context.pop();
                context.push('/reports');
              },
            ),
          ],
        ),
      ),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $err', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(dashboardSummaryProvider),
                child: const Text('Retry'),
              )
            ],
          ),
        ),
        data: (summary) => _buildDashboard(context, ref, summary),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Action for New Invoice
        },
        icon: const Icon(Icons.add),
        label: const Text('New Invoice'),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, WidgetRef ref, DashboardSummary summary) {
    return RefreshIndicator(
      onRefresh: () async {
        // ignore: unused_result
        ref.refresh(dashboardSummaryProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  context,
                  'Today\'s Sales',
                  '\$${summary.todaysSales.toStringAsFixed(2)}',
                  Icons.attach_money,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  context,
                  'Today\'s Invoices',
                  '${summary.todaysInvoiceCount}',
                  Icons.receipt,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  context,
                  'Customers',
                  '${summary.totalCustomers}',
                  Icons.people,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  context,
                  'Products',
                  '${summary.totalProducts}',
                  Icons.inventory_2,
                  Colors.purple,
                  onTap: () => context.push('/products'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  context,
                  'Invoices',
                  '${summary.totalInvoices}',
                  Icons.receipt,
                  Colors.orange,
                  onTap: () => context.push('/invoices'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          if (reportState.report != null && reportState.report!.salesTrend.isNotEmpty)
            _buildMiniSalesChart(reportState.report!.salesTrend),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Invoices',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('See All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (summary.recentInvoices.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: Text('No recent invoices found.')),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: summary.recentInvoices.length,
              itemBuilder: (context, index) {
                final invoice = summary.recentInvoices[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.receipt_long),
                    ),
                    title: Text(invoice.customerName),
                    subtitle: Text('Invoice #${invoice.id} • ${invoice.createdAt}'),
                    trailing: Text(
                      '\$${invoice.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          if (title == 'Customers') {
            context.push('/customers');
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 28),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniSalesChart(List trend) {
    final maxY = trend.map((e) => e.total).reduce((a, b) => a > b ? a : b);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sales Trend (Last 30 Days)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: trend.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.total)).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.2)),
                    ),
                  ],
                  minX: 0,
                  maxX: (trend.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxY * 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
