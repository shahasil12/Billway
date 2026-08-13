import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import '../../../../core/providers.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../controllers/invoice_list_controller.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_inputs.dart';
import '../../../../core/widgets/app_containers.dart';
import '../../../../core/widgets/app_buttons.dart';

class InvoiceListScreen extends ConsumerStatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  ConsumerState<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends ConsumerState<InvoiceListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(invoiceListProvider.notifier).fetchInvoices();
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(invoiceListProvider.notifier).setSearchQuery(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(invoiceListProvider);
    final currency = ref.watch(settingsProvider).settings?.currency ?? '\$';
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16),
            child: PrimaryButton(
              label: 'New Invoice',
              onPressed: () => context.push('/invoices/create'),
            ),
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? AppSpacing.p32 : AppSpacing.p16,
              vertical: AppSpacing.p8,
            ),
            child: SearchField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              hint: 'Search by invoice # or customer...',
            ),
          ),
        ),
      ),
      body: _buildBody(context, state, currency, isTablet),
    );
  }

  Widget _buildBody(BuildContext context, InvoiceListState state, String currency, bool isTablet) {
    if (state.isLoading && state.invoices.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.invoices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: AppSpacing.p16),
            Text(state.error!, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: AppSpacing.p16),
            SizedBox(
              width: 120,
              child: PrimaryButton(
                label: 'Retry',
                onPressed: () => ref.read(invoiceListProvider.notifier).fetchInvoices(isRefresh: true),
              ),
            ),
          ],
        ),
      );
    }

    if (state.invoices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textDisabled),
            const SizedBox(height: AppSpacing.p16),
            const Text('No invoices found', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.p24),
            SizedBox(
              width: 200,
              child: PrimaryButton(
                label: 'Create First Invoice',
                onPressed: () => context.push('/invoices/create'),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(invoiceListProvider.notifier).fetchInvoices(isRefresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? AppSpacing.p32 : 0,
          vertical: AppSpacing.p16,
        ),
        itemCount: state.invoices.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.invoices.length) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.p16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final invoice = state.invoices[index];
          
          final row = ListRow(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppSpacing.p8),
              ),
              child: const Icon(Icons.receipt, color: AppColors.primary),
            ),
            title: invoice.customer?.name ?? 'Unknown Customer',
            subtitle: 'Invoice #${invoice.id} • ${invoice.paymentMethod}',
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$currency${invoice.grandTotal.toStringAsFixed(2)}',
                  style: AppTextStyles.financialLine.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                StatusChip(
                  label: invoice.status,
                  status: invoice.status == 'PAID' ? StatusType.success : StatusType.warning,
                ),
              ],
            ),
            onTap: () => context.push('/invoices/${invoice.id}', extra: invoice),
          );

          if (isTablet) {
            return AppCard(
              padding: EdgeInsets.zero,
              child: row,
            );
          }
          return row;
        },
      ),
    );
  }
}
