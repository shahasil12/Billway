import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_containers.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../controllers/dashboard_controller.dart';
import '../../../../core/providers.dart';
import '../../../../features/auth/domain/entities/user.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final user = ref.watch(authStateProvider).value;
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: summaryAsync.when(
        data: (summary) => _buildBody(context, summary, user, isTablet),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildBody(BuildContext context, DashboardSummary summary, dynamic user, bool isTablet) {
    final children = [
      _buildSummaryCards(context, summary, isTablet),
      const SizedBox(height: AppSpacing.p24),
      _buildQuickActions(context, user, isTablet),
      const SizedBox(height: AppSpacing.p24),
      _buildRecentInvoices(context, summary.recentInvoices),
      const SizedBox(height: AppSpacing.p32),
    ];

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? AppSpacing.p32 : AppSpacing.p16,
        vertical: AppSpacing.p24,
      ),
      children: children,
    );
  }

  Widget _buildSummaryCards(BuildContext context, DashboardSummary summary, bool isTablet) {
    final cards = [
      _StatCard(title: 'Sales Today', value: '\$${summary.todaysSales.toStringAsFixed(2)}'),
      _StatCard(title: 'Invoices Today', value: '${summary.todaysInvoiceCount}'),
      _StatCard(title: 'Customers', value: '${summary.totalCustomers}'),
      _StatCard(title: 'Products', value: '${summary.totalProducts}'),
    ];

    if (isTablet) {
      return Row(
        children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: AppSpacing.p16), child: c))).toList(),
      );
    } else {
      return SizedBox(
        height: 120,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: cards.map((c) => Container(width: 140, margin: const EdgeInsets.only(right: AppSpacing.p12), child: c)).toList(),
        ),
      );
    }
  }

  Widget _buildQuickActions(BuildContext context, dynamic user, bool isTablet) {
    final actions = [
      _ActionCard(icon: Icons.add, label: 'New Invoice', onTap: () => context.go('/invoices/create')),
      if (user?.role != UserRole.cashier) ...[
        _ActionCard(icon: Icons.person_add, label: 'Add Customer', onTap: () => context.go('/customers/add')),
        _ActionCard(icon: Icons.inventory_2, label: 'Add Product', onTap: () => context.go('/products/add')),
      ]
    ];

    if (isTablet) {
      return Row(
        children: actions.map((a) => Padding(padding: const EdgeInsets.only(right: AppSpacing.p16), child: a)).toList(),
      );
    } else {
      return SizedBox(
        height: 100,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: actions.map((a) => Container(width: 100, margin: const EdgeInsets.only(right: AppSpacing.p12), child: a)).toList(),
        ),
      );
    }
  }



  Widget _buildRecentInvoices(BuildContext context, List<RecentInvoice> invoices) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Invoices', style: AppTextStyles.h3),
            TextButton(
              onPressed: () => context.go('/invoices'),
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.p16),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: invoices.map((inv) => ListRow(
              title: inv.customerName,
              subtitle: 'Invoice #${inv.id}',
              trailing: Text('\$${inv.totalAmount.toStringAsFixed(2)}', style: AppTextStyles.financialLine),
              onTap: () => context.go('/invoices/${inv.id}'), // Or proper route
            )).toList(),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.p8),
          Text(value, style: AppTextStyles.h2),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.p12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: AppSpacing.p8),
          Text(label, style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
