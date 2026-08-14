import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
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
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final currency = ref.watch(settingsProvider).settings?.currency ?? '\$';

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
        data: (summary) => _buildBody(context, ref, summary, user, posSessionState, isTablet, currency),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, DashboardSummary summary, dynamic user, dynamic posSessionState, bool isTablet, String currency) {
    final children = [
      _buildSummaryCards(context, summary, isTablet, currency),
      const SizedBox(height: AppSpacing.p24),
      if (!posSessionState.isLoading && posSessionState.session != null) ...[
        _buildActiveSessionBanner(context, posSessionState.session, currency),
        const SizedBox(height: AppSpacing.p24),
      ],
      _buildQuickActions(context, user, isTablet),
      const SizedBox(height: AppSpacing.p24),
      _buildRecentInvoices(context, summary.recentInvoices, currency),
      const SizedBox(height: AppSpacing.p32),
    ];

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dashboardSummaryProvider);
        await ref.read(posSessionControllerProvider.notifier).checkCurrentSession();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? AppSpacing.p32 : AppSpacing.p16,
          vertical: AppSpacing.p24,
        ),
        children: children,
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, DashboardSummary summary, bool isTablet, String currency) {
    final cards = [
      _StatCard(title: 'Sales Today', value: '$currency${summary.todaysSales.toStringAsFixed(2)}', icon: Icons.trending_up, color: AppColors.primary),
      _StatCard(title: 'Invoices Today', value: '${summary.todaysInvoiceCount}', icon: Icons.receipt_long, color: AppColors.secondary),
      _StatCard(title: 'Customers', value: '${summary.totalCustomers}', icon: Icons.people_alt, color: AppColors.success),
      _StatCard(title: 'Products', value: '${summary.totalProducts}', icon: Icons.inventory_2, color: AppColors.warning),
    ];

    if (isTablet) {
      return Row(
        children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: AppSpacing.p16), child: c))).toList(),
      );
    } else {
      return SizedBox(
        height: 140,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: cards.map((c) => Container(width: 160, margin: const EdgeInsets.only(right: AppSpacing.p12), child: c)).toList(),
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



  Widget _buildRecentInvoices(BuildContext context, List<RecentInvoice> invoices, String currency) {
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
              title: inv.customerName == 'Unknown' ? 'POS/INV/${inv.id}' : inv.customerName,
              subtitle: inv.customerName == 'Unknown' ? 'POS Sale' : 'Invoice #${inv.id}',
              trailing: Text('$currency${inv.totalAmount.toStringAsFixed(2)}', style: AppTextStyles.financialLine),
              onTap: () async {
                final repo = ref.read(invoiceRepositoryProvider);
                final result = await repo.getInvoice(inv.id!);
                result.fold(
                  (failure) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message)));
                    }
                  },
                  (invoice) {
                    if (context.mounted) {
                      context.push('/invoices/${invoice.id}', extra: invoice);
                    }
                  }
                );
              },
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveSessionBanner(BuildContext context, POSSession session, String currency) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.p16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withAlpha(60)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.p12),
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: const Icon(Icons.point_of_sale, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.p16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Active POS Session', style: AppTextStyles.h3.copyWith(color: AppColors.primary)),
                const SizedBox(height: 4),
                Text('Opened with $currency${session.openingCash.toStringAsFixed(2)}', style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
          PrimaryButton(
            label: 'Go to POS',
            onPressed: () => context.go('/pos'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.p8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: AppSpacing.p12),
              Expanded(
                child: Text(title, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.p16),
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
