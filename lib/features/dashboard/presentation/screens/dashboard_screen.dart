import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_containers.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../controllers/dashboard_controller.dart';
import '../../../../core/providers.dart';
import '../../../../features/auth/domain/entities/user.dart';
import '../../../../features/pos/presentation/providers/pos_providers.dart';
import '../../../../features/pos/domain/entities/pos_session.dart';
import '../../../../features/settings/presentation/controllers/settings_controller.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final user = ref.watch(authStateProvider).value;
    final posSessionState = ref.watch(posSessionControllerProvider);
    final isTablet = MediaQuery.of(context).size.width >= 720;
    final currency = ref.watch(settingsProvider).settings?.currency ?? '\$';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: summaryAsync.when(
          data: (summary) => _buildBody(context, ref, summary, user, posSessionState, isTablet, currency),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, DashboardSummary summary, dynamic user, dynamic posSessionState, bool isTablet, String currency) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dashboardSummaryProvider);
        await ref.read(posSessionControllerProvider.notifier).checkCurrentSession();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 28 : 16,
          vertical: 18,
        ),
        children: [
          _buildHeader(context, user),
          if (summary.overdueCredit > 0) _buildOfflineBanner(currency, summary.overdueCredit),
          _buildActionRow(context, user, isTablet),
          _buildKPIGrid(context, summary, isTablet, currency),
          if (isTablet)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildSalesOverview(context, summary, currency)),
                const SizedBox(width: 14),
                Expanded(flex: 1, child: _buildPaymentMethods(context, summary, currency)),
              ],
            )
          else ...[
            _buildSalesOverview(context, summary, currency),
            const SizedBox(height: 14),
            _buildPaymentMethods(context, summary, currency),
          ],
          const SizedBox(height: 14),
          if (isTablet)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 13, child: _buildRecentBills(context, ref, summary.recentInvoices, currency)),
                const SizedBox(width: 14),
                Expanded(flex: 10, child: _buildLowStock(context, summary.lowStockProducts)),
              ],
            )
          else ...[
            _buildRecentBills(context, ref, summary.recentInvoices, currency),
            const SizedBox(height: 14),
            _buildLowStock(context, summary.lowStockProducts),
          ],
          const SizedBox(height: 14),
          if (isTablet)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 13, child: _buildTopProducts(context, summary.topProducts, currency)),
                const SizedBox(width: 14),
                Expanded(flex: 10, child: Column(
                  children: [
                    _buildMiniCard('Customers', '${summary.totalCustomers}', '+32 this month', true),
                    const SizedBox(height: 14),
                    _buildMiniCard('Products', '${summary.totalProducts}', 'View inventory →', false, onTap: () => context.go('/products')),
                  ],
                )),
              ],
            )
          else ...[
            _buildTopProducts(context, summary.topProducts, currency),
            const SizedBox(height: 14),
            _buildMiniCard('Customers', '${summary.totalCustomers}', '+32 this month', true),
            const SizedBox(height: 14),
            _buildMiniCard('Products', '${summary.totalProducts}', 'View inventory →', false, onTap: () => context.go('/products')),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic user) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [AppColors.brand, AppColors.brand700],
                  ),
                ),
                alignment: Alignment.center,
                child: Text('B', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BillWay', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.ink900, height: 1.1)),
                  const Text('Shahasil Store', style: TextStyle(fontSize: 12.5, color: AppColors.ink500)),
                ],
              ),
              const SizedBox(width: 16),
              if (MediaQuery.of(context).size.width >= 720) ...[
                Container(width: 1, height: 24, color: AppColors.border),
                const SizedBox(width: 16),
                Text('Good evening, ${user?.name?.split(' ')[0] ?? 'User'} 👋', style: const TextStyle(fontSize: 14.5, color: AppColors.ink700, fontWeight: FontWeight.w500)),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSunk,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 7, height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.money, shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: AppColors.money050, spreadRadius: 3)],
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('Synced', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink500)),
                    ],
                  ),
                ),
              ],
            ],
          ),
          Row(
            children: [
              _buildIconButton(Icons.search),
              const SizedBox(width: 8),
              _buildIconButton(Icons.notifications_none, hasBadge: true),
              const SizedBox(width: 8),
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: AppColors.brand050,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: AppColors.border),
                ),
                alignment: Alignment.center,
                child: Text('SH', style: GoogleFonts.spaceGrotesk(color: AppColors.brand, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, {bool hasBadge = false}) {
    return Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, color: AppColors.ink700, size: 20),
          if (hasBadge)
            Positioned(
              top: 8, right: 8,
              child: Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  color: AppColors.coral,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner(String currency, double amount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.coral050,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF3D2D2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFF8E2E2E), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Overdue Credit Alert: You have $currency${amount.toStringAsFixed(2)} in unpaid invoices older than 30 days.',
              style: const TextStyle(color: Color(0xFF8E2E2E), fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(BuildContext context, dynamic user, bool isTablet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 26),
      child: Flex(
        direction: isTablet ? Axis.horizontal : Axis.vertical,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero Button
          Expanded(
            flex: isTablet ? 1 : 0,
            child: InkWell(
              onTap: () => context.go('/invoices/create'),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [AppColors.brand, AppColors.brand700],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [BoxShadow(color: Color(0x8C153059), offset: Offset(0, 10), blurRadius: 24, spreadRadius: -10)],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('+ New Bill', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 3),
                        const Text('Create a new sale', style: TextStyle(color: Color(0xFFC3D3EA), fontSize: 12.5)),
                      ],
                    ),
                    Container(
                      width: 44, height: 44,
                      decoration: const BoxDecoration(color: Color(0x23FFFFFF), shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: const Icon(Icons.arrow_forward, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isTablet) const SizedBox(width: 14) else const SizedBox(height: 14),
          // Quick Actions
          Expanded(
            flex: isTablet ? 2 : 0,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickAction(context, 'Add Product', Icons.inventory_2_outlined, AppColors.money050, AppColors.money, () => context.go('/products/add')),
                  const SizedBox(width: 10),
                  _buildQuickAction(context, 'Add Customer', Icons.person_add_outlined, AppColors.violet050, AppColors.violet, () => context.go('/customers/add')),
                  const SizedBox(width: 10),
                  _buildQuickAction(context, 'Credits', Icons.account_balance_wallet_outlined, AppColors.amber050, AppColors.amber, () => context.go('/customers/credits')),
                  const SizedBox(width: 10),
                  _buildQuickAction(context, 'Add Expense', Icons.receipt_long_outlined, AppColors.coral050, AppColors.coral, () {}),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, String label, IconData icon, Color bg, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
              alignment: Alignment.center,
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.ink700)),
          ],
        ),
      ),
    );
  }

  Widget _buildKPIGrid(BuildContext context, DashboardSummary summary, bool isTablet, String currency) {
    final children = [
      _buildKPICard('Today\'s Sales', '$currency${summary.todaysSales.toStringAsFixed(0)}', '+12.5%', Icons.receipt_long, AppColors.money, AppColors.money050),
      _buildKPICard('Today\'s Profit', '$currency${summary.todaysProfit.toStringAsFixed(0)}', '30.2% margin', Icons.trending_up, AppColors.violet, AppColors.violet050, trendUp: false),
      _buildKPICard('Bills Today', '${summary.todaysInvoiceCount}', '+18', Icons.receipt, AppColors.brand, AppColors.brand050),
      _buildKPICard('Outstanding Payments', '$currency${summary.overdueCredit.toStringAsFixed(0)}', '24 customers', Icons.people_outline, AppColors.amber, AppColors.amber050, trendUp: false),
    ];

    if (isTablet) {
      return Container(
        margin: const EdgeInsets.only(bottom: 22),
        child: Row(
          children: [
            Expanded(child: children[0]), const SizedBox(width: 14),
            Expanded(child: children[1]), const SizedBox(width: 14),
            Expanded(child: children[2]), const SizedBox(width: 14),
            Expanded(child: children[3]),
          ],
        ),
      );
    } else {
      return Container(
        margin: const EdgeInsets.only(bottom: 22),
        height: 145,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: children.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) => SizedBox(width: 220, child: children[i]),
        ),
      );
    }
  }

  Widget _buildKPICard(String label, String value, String trend, IconData icon, Color iconColor, Color iconBg, {bool trendUp = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(color: Color(0x0A12172A), offset: Offset(0, 1), blurRadius: 2)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: 18),
              ),
              Text(
                trend,
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: trendUp ? AppColors.money : AppColors.ink500),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(value, style: GoogleFonts.ibmPlexMono(fontSize: 26, fontWeight: FontWeight.w600, height: 1.1)),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.ink500)),
        ],
      ),
    );
  }

  Widget _buildSalesOverview(BuildContext context, DashboardSummary summary, String currency) {
    if (summary.salesTrend.isEmpty) return const SizedBox();
    final maxY = summary.salesTrend.map((e) => e.total).reduce((a, b) => a > b ? a : b) * 1.2;
    
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sales Overview', style: GoogleFonts.spaceGrotesk(fontSize: 15.5, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(color: AppColors.surfaceSunk, borderRadius: BorderRadius.circular(100), border: Border.all(color: AppColors.border)),
                child: Row(
                  children: [
                    _buildTab('Today', false),
                    _buildTab('7 Days', true),
                    _buildTab('30 Days', false),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.money, borderRadius: BorderRadius.circular(2))), const SizedBox(width: 6), const Text('Sales', style: TextStyle(fontSize: 12, color: AppColors.ink500, fontWeight: FontWeight.w500))]),
              const SizedBox(width: 18),
              Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.violet, borderRadius: BorderRadius.circular(2))), const SizedBox(width: 6), const Text('Profit', style: TextStyle(fontSize: 12, color: AppColors.ink500, fontWeight: FontWeight.w500))]),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: maxY == 0 ? 100 : maxY/3, getDrawingHorizontalLine: (value) => FlLine(color: AppColors.border, strokeWidth: 1)),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < summary.salesTrend.length) {
                          final dateStr = summary.salesTrend[value.toInt()].date;
                          final day = dateStr.length >= 10 ? dateStr.substring(8, 10) : '';
                          return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(day, style: const TextStyle(fontSize: 11, color: AppColors.ink400)));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: summary.salesTrend.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.total)).toList(),
                    isCurved: true, color: AppColors.money, barWidth: 2.5, isStrokeCapRound: true, dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: AppColors.money.withOpacity(0.1)),
                  ),
                ],
                maxY: maxY == 0 ? 100 : maxY,
                minY: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? AppColors.brand : Colors.transparent,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? Colors.white : AppColors.ink500)),
    );
  }

  Widget _buildPaymentMethods(BuildContext context, DashboardSummary summary, String currency) {
    final colors = [AppColors.brand, AppColors.money, AppColors.amber, AppColors.coral, AppColors.violet];
    double total = summary.paymentMethods.fold(0, (sum, item) => sum + item.amount);
    
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment Methods', style: GoogleFonts.spaceGrotesk(fontSize: 15.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          if (summary.paymentMethods.isEmpty) 
             const Center(child: Text('No payments today', style: TextStyle(color: AppColors.ink500)))
          else
            Row(
              children: [
                SizedBox(
                  width: 120, height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 0,
                          centerSpaceRadius: 45,
                          sections: summary.paymentMethods.asMap().entries.map((e) {
                            return PieChartSectionData(
                              color: colors[e.key % colors.length],
                              value: e.value.amount,
                              title: '',
                              radius: 12,
                            );
                          }).toList(),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('$currency${total.toStringAsFixed(0)}', style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink900)),
                          const Text('today', style: TextStyle(fontSize: 10, color: AppColors.ink400)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: summary.paymentMethods.asMap().entries.map((e) {
                      final item = e.value;
                      final pct = total > 0 ? (item.amount / total * 100).toStringAsFixed(0) : '0';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(width: 9, height: 9, decoration: BoxDecoration(color: colors[e.key % colors.length], borderRadius: BorderRadius.circular(2.5))),
                            const SizedBox(width: 8),
                            Expanded(child: Text(item.method, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink700))),
                            Text('$currency${item.amount.toStringAsFixed(0)}', style: GoogleFonts.ibmPlexMono(fontSize: 12.5, color: AppColors.ink500)),
                            const SizedBox(width: 8),
                            SizedBox(width: 28, child: Text('$pct%', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildRecentBills(BuildContext context, WidgetRef ref, List<RecentInvoice> invoices, String currency) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Bills', style: GoogleFonts.spaceGrotesk(fontSize: 15.5, fontWeight: FontWeight.w600)),
                InkWell(onTap: () => context.go('/invoices'), child: const Text('View All →', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.brand))),
              ],
            ),
          ),
          ...invoices.map((inv) {
            final initials = inv.customerName.length >= 2 ? inv.customerName.substring(0, 2).toUpperCase() : 'RT';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: AppColors.surfaceSunk, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                    alignment: Alignment.center,
                    child: Text(initials, style: GoogleFonts.spaceGrotesk(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.ink500)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('INV-${inv.id}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink900)),
                        Text(inv.customerName, style: const TextStyle(fontSize: 12.5, color: AppColors.ink500)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('$currency${inv.totalAmount.toStringAsFixed(0)}', style: GoogleFonts.ibmPlexMono(fontSize: 14, fontWeight: FontWeight.w600)),
                      const Text('Paid', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.money)),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLowStock(BuildContext context, List<LowStockProduct> products) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Low Stock', style: GoogleFonts.spaceGrotesk(fontSize: 15.5, fontWeight: FontWeight.w600)),
                InkWell(onTap: () => context.go('/products'), child: const Text('Inventory →', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.brand))),
              ],
            ),
          ),
          if (products.isEmpty)
             const Padding(padding: EdgeInsets.all(22), child: Center(child: Text('All stock levels are good!', style: TextStyle(color: AppColors.ink500)))),
          ...products.map((p) {
            final isCritical = p.stock <= 2;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
              child: Row(
                children: [
                  Container(width: 4, height: 34, decoration: BoxDecoration(color: isCritical ? AppColors.coral : AppColors.amber, borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink900)),
                        Text('${p.stock} remaining', style: const TextStyle(fontSize: 12, color: AppColors.ink500)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: isCritical ? AppColors.coral050 : AppColors.amber050, borderRadius: BorderRadius.circular(100)),
                    child: Text(isCritical ? 'Critical' : 'Low', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isCritical ? AppColors.coral : AppColors.amber)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTopProducts(BuildContext context, List<TopProduct> products, String currency) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(22),
            child: Text('Top Selling Products', style: GoogleFonts.spaceGrotesk(fontSize: 15.5, fontWeight: FontWeight.w600)),
          ),
          ...products.asMap().entries.map((e) {
            final p = e.value;
            final rank = (e.key + 1).toString().padLeft(2, '0');
            final maxSold = products.isNotEmpty ? products[0].quantitySold : 1;
            final pct = (p.quantitySold / maxSold).clamp(0.0, 1.0);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
              child: Row(
                children: [
                  Text(rank, style: GoogleFonts.ibmPlexMono(fontSize: 12, color: AppColors.ink400)),
                  const SizedBox(width: 12),
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: AppColors.surfaceSunk, borderRadius: BorderRadius.circular(9), border: Border.all(color: AppColors.border)),
                    alignment: Alignment.center,
                    child: const Icon(Icons.inventory_2_outlined, size: 16, color: AppColors.ink500),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.productName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink900), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('${p.quantitySold} sold · $currency${p.revenue.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: AppColors.ink500)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 70, height: 5,
                    decoration: BoxDecoration(color: AppColors.surfaceSunk, borderRadius: BorderRadius.circular(3)),
                    alignment: Alignment.centerLeft,
                    child: Container(width: 70 * pct, height: 5, decoration: BoxDecoration(color: AppColors.money, borderRadius: BorderRadius.circular(3))),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMiniCard(String label, String value, String footer, bool isTrend, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: const [BoxShadow(color: Color(0x0A12172A), offset: Offset(0, 1), blurRadius: 2)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.ink500)),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.ibmPlexMono(fontSize: 24, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Text(footer, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isTrend ? AppColors.money : AppColors.brand)),
          ],
        ),
      ),
    );
  }
}
