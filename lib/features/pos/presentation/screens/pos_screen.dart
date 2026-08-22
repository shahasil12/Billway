import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/pos_providers.dart';
import '../controllers/pos_session_controller.dart';
import '../../../products/presentation/controllers/product_list_controller.dart';
import '../../../customers/presentation/controllers/customer_list_controller.dart';
import '../../../categories/presentation/controllers/category_list_controller.dart';
import '../controllers/pos_cart_controller.dart';
import '../../../products/domain/entities/product.dart';
import '../../../customers/domain/entities/customer.dart';
import '../../../invoices/domain/entities/invoice.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_inputs.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/billing_specifics.dart';
import '../../../../core/widgets/barcode_scanner_screen.dart';

class POSScreen extends ConsumerStatefulWidget {
  const POSScreen({super.key});

  @override
  ConsumerState<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends ConsumerState<POSScreen> {
  int? _selectedCategoryId;
  final TextEditingController _searchController = TextEditingController();
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(productListProvider.notifier).fetchProducts();
      ref.read(categoryListProvider.notifier).fetchCategories();
      ref.read(customerListProvider.notifier).fetchCustomers();
      _checkSession();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _checkSession() {
    final sessionState = ref.read(posSessionControllerProvider);
    if (!sessionState.isLoading && sessionState.session == null && !_dialogShown) {
      _dialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showOpenSessionDialog();
      });
    }
  }

  void _showOpenSessionDialog() {
    final controller = TextEditingController();
    final currency = ref.read(settingsProvider).settings?.currency ?? '₹';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Open POS Session', style: AppTextStyles.h2),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter the opening cash amount in the drawer:',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.p16),
            AppTextField(
              controller: controller,
              label: 'Opening Cash Amount ($currency)',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/');
            },
            child: Text('Cancel & Exit',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          ),
          PrimaryButton(
            label: 'Open Session',
            onPressed: () async {
              final amount = double.tryParse(controller.text) ?? 0;
              final success =
                  await ref.read(posSessionControllerProvider.notifier).openSession(amount);
              if (success && mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showCloseSessionDialog() {
    final controller = TextEditingController();
    final currency = ref.read(settingsProvider).settings?.currency ?? '₹';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Close POS Session', style: AppTextStyles.h2),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter the actual cash amount in the drawer:',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.p16),
            AppTextField(
              controller: controller,
              label: 'Closing Cash Amount ($currency)',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          ),
          PrimaryButton(
            label: 'Close Session',
            onPressed: () async {
              final amount = double.tryParse(controller.text) ?? 0;
              final success =
                  await ref.read(posSessionControllerProvider.notifier).closeSession(amount);
              if (success && mounted) {
                Navigator.pop(context);
                context.go('/');
              }
            },
          ),
        ],
      ),
    );
  }

  void _showPettyCashDialog() {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();
    String type = 'IN';
    final currency = ref.read(settingsProvider).settings?.currency ?? '₹';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Petty Cash', style: AppTextStyles.h2),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text('Cash In', style: AppTextStyles.bodyMedium),
                      value: 'IN',
                      groupValue: type,
                      onChanged: (val) => setState(() => type = val!),
                      activeColor: AppColors.primary,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text('Cash Out', style: AppTextStyles.bodyMedium),
                      value: 'OUT',
                      groupValue: type,
                      onChanged: (val) => setState(() => type = val!),
                      activeColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.p16),
              AppTextField(
                controller: amountController,
                label: 'Amount ($currency)',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: AppSpacing.p16),
              AppTextField(controller: reasonController, label: 'Reason'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
            ),
            PrimaryButton(
              label: 'Save',
              onPressed: () async {
                final amount = double.tryParse(amountController.text) ?? 0;
                if (amount <= 0 || reasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid amount and reason')),
                  );
                  return;
                }
                final success = await ref
                    .read(posSessionControllerProvider.notifier)
                    .recordCashMovement(amount, type, reasonController.text.trim());
                if (success && mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cash movement recorded')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openBarcodeScannerForSearch() async {
    final scannedValue = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (scannedValue != null && mounted) {
      _searchController.text = scannedValue;
      ref.read(productListProvider.notifier).setSearchQuery(scannedValue);
    }
  }

  void _navigateToPayment(POSCartState cartState, String currency) {
    if (cartState.items.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PaymentScreen(
          cartState: cartState,
          currency: currency,
          onComplete: (invoice) {
            ref.read(posCartControllerProvider.notifier).clearCart();
            if (mounted) context.push('/invoices/${invoice.id}', extra: invoice);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(posSessionControllerProvider);
    final cartState = ref.watch(posCartControllerProvider);
    final productsState = ref.watch(productListProvider);
    final categoriesState = ref.watch(categoryListProvider);
    final isTablet = MediaQuery.of(context).size.width >= 700;
    final currency = ref.watch(settingsProvider).settings?.currency ?? '₹';

    ref.listen<POSCartState>(posCartControllerProvider, (previous, next) {
      if (next.error != null && (previous == null || previous.error != next.error)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error!, style: AppTextStyles.bodyMedium),
          backgroundColor: AppColors.error,
        ));
      }
    });

    if (!sessionState.isLoading && sessionState.session == null && !_dialogShown) {
      _dialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showOpenSessionDialog();
      });
    }

    if (sessionState.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading POS…', style: AppTextStyles.bodyLarge),
            ],
          ),
        ),
      );
    }

    if (sessionState.session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Point of Sale')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.point_of_sale, size: 72, color: AppColors.textDisabled),
              const SizedBox(height: AppSpacing.p16),
              Text('No Active Session', style: AppTextStyles.h2.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.p8),
              Text('Open a session to start selling.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.p32),
              PrimaryButton(
                label: 'Open Session',
                isLarge: true,
                onPressed: () {
                  _dialogShown = false;
                  _showOpenSessionDialog();
                },
              ),
            ],
          ),
        ),
      );
    }

    // Filter products
    final search = _searchController.text.toLowerCase();
    final products = productsState.products.where((p) {
      final matchSearch = search.isEmpty ||
          p.name.toLowerCase().contains(search) ||
          (p.barcode?.toLowerCase().contains(search) ?? false);
      final matchCat = _selectedCategoryId == null || p.categoryId == _selectedCategoryId;
      return matchSearch && matchCat;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Point of Sale', style: AppTextStyles.h2),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.attach_money, size: 20),
            label: Text('Petty Cash', style: AppTextStyles.label),
            onPressed: _showPettyCashDialog,
            style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
          ),
          const SizedBox(width: 4),
          OutlinedButton(
            onPressed: _showCloseSessionDialog,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.borderStrong),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: Text('Close Session', style: AppTextStyles.label.copyWith(color: AppColors.textPrimary)),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: isTablet
          ? _buildTabletLayout(products, cartState, categoriesState.categories, currency)
          : _buildPhoneLayout(products, cartState, categoriesState.categories, currency),
    );
  }

  // ─── TABLET LAYOUT ───────────────────────────────────────────────────────────

  Widget _buildTabletLayout(
      List<Product> products, POSCartState cartState, List<dynamic> categories, String currency) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // LEFT — search + categories + product grid
        Expanded(
          flex: 65,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSearchBar(),
              _buildCategoryRow(categories),
              Expanded(child: _buildProductGrid(products, 3, currency)),
            ],
          ),
        ),

        const VerticalDivider(width: 1, color: AppColors.border),

        // RIGHT — bill panel
        SizedBox(
          width: 340,
          child: _buildBillPanel(cartState, currency, fromBottomSheet: false),
        ),
      ],
    );
  }

  // ─── PHONE LAYOUT ─────────────────────────────────────────────────────────

  Widget _buildPhoneLayout(
      List<Product> products, POSCartState cartState, List<dynamic> categories, String currency) {
    final itemCount = cartState.items.length;
    final total = cartState.grandTotal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSearchBar(),
        _buildCategoryRow(categories),
        Expanded(child: _buildProductGrid(products, 2, currency)),
        // Persistent "View Bill" bar — spec requirement
        GestureDetector(
          onTap: itemCount > 0 ? () => _showPhoneCartSheet(cartState, currency) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16, vertical: 14),
            decoration: BoxDecoration(
              color: itemCount > 0 ? AppColors.primary : AppColors.surface,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -4))
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  color: itemCount > 0 ? AppColors.textOnPrimary : AppColors.textDisabled,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.p12),
                Expanded(
                  child: Text(
                    itemCount > 0 ? 'View Bill ($itemCount items)' : 'Your bill is empty',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: itemCount > 0 ? AppColors.textOnPrimary : AppColors.textDisabled,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (itemCount > 0)
                  Text(
                    '$currency${total.toStringAsFixed(2)}',
                    style: AppTextStyles.financialLine.copyWith(
                      color: AppColors.textOnPrimary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── SEARCH BAR (with barcode scan button on right) ──────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.p16, AppSpacing.p16, AppSpacing.p16, AppSpacing.p8),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 56,
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {});
                  if (val.isEmpty) {
                    ref.read(productListProvider.notifier).fetchProducts();
                  }
                },
                style: AppTextStyles.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Search product or scan barcode',
                  hintStyle: AppTextStyles.bodyLarge.copyWith(color: AppColors.textDisabled),
                  prefixIcon: const Icon(Icons.search, size: 26, color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 22),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                            ref.read(productListProvider.notifier).fetchProducts();
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.p8),
          // Barcode scan button — spec: large, always icon + label visible
          Tooltip(
            message: 'Scan Barcode',
            child: InkWell(
              onTap: _openBarcodeScannerForSearch,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.qr_code_scanner, color: AppColors.textOnPrimary, size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── CATEGORY PILLS ───────────────────────────────────────────────────────

  Widget _buildCategoryRow(List<dynamic> categories) {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16, vertical: AppSpacing.p4),
        children: [
          _buildCategoryPill('All', null),
          ...categories.map((c) => _buildCategoryPill(c.name, c.id)),
        ],
      ),
    );
  }

  Widget _buildCategoryPill(String name, int? id) {
    final isSelected = _selectedCategoryId == id;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.p8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategoryId = id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: 1.5,
            ),
          ),
          child: Text(
            name,
            style: AppTextStyles.label.copyWith(
              color: isSelected ? AppColors.textOnPrimary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // ─── PRODUCT GRID ─────────────────────────────────────────────────────────

  Widget _buildProductGrid(List<Product> products, int crossAxisCount, String currency) {
    if (products.isEmpty && _searchController.text.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 60, color: AppColors.textDisabled),
            const SizedBox(height: 12),
            Text('No products found', style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary)),
            Text('Try a different search or scan a barcode',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textDisabled)),
          ],
        ),
      );
    }

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 60, color: AppColors.textDisabled),
            const SizedBox(height: 12),
            Text('No products yet', style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary)),
            Text('Add your first product to start billing',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textDisabled)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(productListProvider.notifier).fetchProducts(isRefresh: true);
        await ref.read(categoryListProvider.notifier).fetchCategories(isRefresh: true);
      },
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.p16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 0.72,
          crossAxisSpacing: AppSpacing.p12,
          mainAxisSpacing: AppSpacing.p12,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) => _ProductCard(
          product: products[index],
          currency: currency,
          onAdd: () => ref.read(posCartControllerProvider.notifier).addProduct(products[index]),
        ),
      ),
    );
  }

  // ─── BILL PANEL (tablet right side) ──────────────────────────────────────

  Widget _buildBillPanel(POSCartState cartState, String currency,
      {bool fromBottomSheet = false}) {
    final itemCount = cartState.items.length;
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16, vertical: AppSpacing.p16),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Text(
                'CURRENT BILL',
                style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
              if (itemCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$itemCount items',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textOnPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (itemCount > 0)
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.error, size: 24),
                  tooltip: 'Clear Bill',
                  onPressed: () => ref.read(posCartControllerProvider.notifier).clearCart(),
                ),
            ],
          ),
        ),

        // Items list
        Expanded(
          child: cartState.items.isEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.receipt_long_outlined, size: 56, color: AppColors.textDisabled),
                    const SizedBox(height: 12),
                    Text('Your bill is empty', style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text('Search or scan a product to begin',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textDisabled),
                        textAlign: TextAlign.center),
                  ],
                )
              : ListView.separated(
                  itemCount: cartState.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                  itemBuilder: (context, index) {
                    final item = cartState.items[index];
                    return _BillLineItem(
                      item: item,
                      currency: currency,
                      onQuantityChanged: (val) {
                        ref.read(posCartControllerProvider.notifier)
                            .updateQuantity(item.product.id!, val);
                      },
                      onRemove: () {
                        ref.read(posCartControllerProvider.notifier)
                            .removeProduct(item.product.id!);
                      },
                    );
                  },
                ),
        ),

        // Customer selector
        if (cartState.items.isNotEmpty)
          _buildCustomerSelector(cartState),

        // Totals + Pay button
        Container(
          padding: const EdgeInsets.fromLTRB(AppSpacing.p16, AppSpacing.p16, AppSpacing.p16, AppSpacing.p20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -4))
            ],
          ),
          child: Column(
            children: [
              TotalsBlock(
                subtotal: cartState.subtotal,
                discountAmount: cartState.discountAmount,
                taxTotal: cartState.taxTotal,
                grandTotal: cartState.grandTotal,
                currency: currency,
              ),
              const SizedBox(height: AppSpacing.p16),
              PrimaryButton(
                label: 'Pay $currency${cartState.grandTotal.toStringAsFixed(2)}',
                isLarge: true,
                isFullWidth: true,
                icon: Icons.payment,
                onPressed: cartState.items.isEmpty
                    ? null
                    : () {
                        if (fromBottomSheet) Navigator.pop(context);
                        _navigateToPayment(cartState, currency);
                      },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerSelector(POSCartState cartState) {
    final customers = ref.watch(customerListProvider).customers;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16, vertical: AppSpacing.p8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: DropdownButtonFormField<int?>(
        value: cartState.customer?.id,
        isDense: false,
        decoration: InputDecoration(
          labelText: '+ Add Customer',
          labelStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        items: [
          DropdownMenuItem<int?>(
            value: null,
            child: Text('Walk-in Customer', style: AppTextStyles.bodyMedium),
          ),
          ...customers.map((c) => DropdownMenuItem<int?>(
            value: c.id,
            child: Text(c.name, style: AppTextStyles.bodyMedium),
          )),
        ],
        onChanged: (val) {
          if (val == null) {
            ref.read(posCartControllerProvider.notifier).clearCustomer();
          } else {
            final customer = customers.firstWhere((c) => c.id == val);
            ref.read(posCartControllerProvider.notifier).setCustomer(customer);
          }
        },
      ),
    );
  }

  void _showPhoneCartSheet(POSCartState initialCartState, String currency) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final cartState = ref.watch(posCartControllerProvider);
          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (_, scrollController) => Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                child: _buildBillPanel(cartState, currency, fromBottomSheet: true),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── PRODUCT CARD ──────────────────────────────────────────────────────────

class _ProductCard extends StatefulWidget {
  final Product product;
  final String currency;
  final VoidCallback onAdd;

  const _ProductCard({required this.product, required this.currency, required this.onAdd});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _justAdded = false;

  void _handleAdd() {
    if (widget.product.stock <= 0 && widget.product.trackStock) return;
    widget.onAdd();
    setState(() => _justAdded = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _justAdded = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final isOutOfStock = p.trackStock && p.stock <= 0;

    return Opacity(
      opacity: isOutOfStock ? 0.55 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Product image / placeholder
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: _buildProductImage(p),
              ),
            ),

            // Info section
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${widget.currency}${p.price.toStringAsFixed(2)}',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      StockBadge(stock: p.stock, minStock: p.minStock),
                    ],
                  ),
                ],
              ),
            ),

            // ADD button
            Padding(
              padding: const EdgeInsets.all(10),
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: isOutOfStock ? null : _handleAdd,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _justAdded ? AppColors.success : AppColors.primary,
                    disabledBackgroundColor: AppColors.border,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _justAdded ? Icons.check : Icons.add,
                        color: isOutOfStock ? AppColors.textDisabled : AppColors.textOnPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _justAdded ? 'Added!' : (isOutOfStock ? 'Out of Stock' : 'ADD'),
                        style: AppTextStyles.label.copyWith(
                          color: isOutOfStock ? AppColors.textDisabled : AppColors.textOnPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(Product p) {
    if (p.image != null && p.image!.isNotEmpty) {
      if (p.image!.startsWith('http')) {
        return Image.network(
          p.image!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(p.name),
        );
      } else {
        // Local file path (offline image)
        return Image.file(
          File(p.image!),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(p.name),
        );
      }
    }
    return _buildPlaceholder(p.name);
  }

  Widget _buildPlaceholder(String name) {
    final colors = [
      AppColors.primary, AppColors.success, AppColors.warning, AppColors.violet,
    ];
    final color = colors[name.codeUnitAt(0) % colors.length];
    return Container(
      color: color.withOpacity(0.12),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: color),
        ),
      ),
    );
  }
}

// ─── BILL LINE ITEM ────────────────────────────────────────────────────────

class _BillLineItem extends StatelessWidget {
  final dynamic item;
  final String currency;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  const _BillLineItem({
    required this.item,
    required this.currency,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16, vertical: AppSpacing.p12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$currency${item.unitPrice.toStringAsFixed(2)} each',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Text(
                '$currency${(item.unitPrice * item.quantity).toStringAsFixed(2)}',
                style: AppTextStyles.financialLine.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              QuantityStepper(
                value: item.quantity,
                onChanged: onQuantityChanged,
              ),
              const Spacer(),
              // Remove button — always visible (spec: never hidden behind swipe)
              TextButton.icon(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                label: Text('Remove', style: AppTextStyles.bodySmall.copyWith(color: AppColors.error, fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── PAYMENT SCREEN (full-screen, spec 4.2) ───────────────────────────────

class _PaymentScreen extends ConsumerStatefulWidget {
  final POSCartState cartState;
  final String currency;
  final ValueChanged<Invoice> onComplete;

  const _PaymentScreen({
    required this.cartState,
    required this.currency,
    required this.onComplete,
  });

  @override
  ConsumerState<_PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<_PaymentScreen> {
  String _method = 'CASH';
  final TextEditingController _cashController = TextEditingController();
  bool _isProcessing = false;
  Invoice? _completedInvoice;

  @override
  void initState() {
    super.initState();
    _cashController.text = widget.cartState.grandTotal.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  double get _cashReceived => double.tryParse(_cashController.text) ?? 0;
  double get _changeToReturn => (_cashReceived - widget.cartState.grandTotal).clamp(0, double.infinity);

  Future<void> _completeSale() async {
    setState(() => _isProcessing = true);
    final amountPaid = _method == 'CREDIT' ? 0.0 : _cashReceived;

    if (_method == 'CASH' && amountPaid < widget.cartState.grandTotal) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cash received must be at least ${widget.currency}${widget.cartState.grandTotal.toStringAsFixed(2)}',
              style: AppTextStyles.bodyMedium),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final invoice = await ref
        .read(posCartControllerProvider.notifier)
        .checkout(amountPaid, _method);

    setState(() => _isProcessing = false);

    if (invoice != null && mounted) {
      setState(() => _completedInvoice = invoice);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_completedInvoice != null) {
      return _buildSuccessScreen(_completedInvoice!);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back to Bill',
        ),
        title: Text('Payment', style: AppTextStyles.h2),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.p24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'How is the customer paying?',
                style: AppTextStyles.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.p24),

              // Payment method 2x2 grid
              PaymentMethodSelector(
                selectedMethod: _method,
                onSelected: (m) => setState(() => _method = m),
                gridLayout: true,
              ),
              const SizedBox(height: AppSpacing.p32),

              const Divider(color: AppColors.border),
              const SizedBox(height: AppSpacing.p16),

              // Amount to pay
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Amount to pay', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary)),
                  Text(
                    '${widget.currency}${widget.cartState.grandTotal.toStringAsFixed(2)}',
                    style: AppTextStyles.financialLine.copyWith(fontSize: 26, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.p24),

              // Cash section
              if (_method == 'CASH') ...[
                Text('Cash received', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.p8),
                SizedBox(
                  height: 64,
                  child: TextField(
                    controller: _cashController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: AppTextStyles.h2.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      prefixText: '${widget.currency} ',
                      prefixStyle: AppTextStyles.h2.copyWith(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.p12),
                // Quick amount buttons
                Row(
                  children: [
                    widget.cartState.grandTotal,
                    widget.cartState.grandTotal + 50,
                    widget.cartState.grandTotal + 100,
                    widget.cartState.grandTotal + 250,
                  ].map((amt) {
                    final label = '${widget.currency}${amt.toStringAsFixed(0)}';
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: OutlinedButton(
                          onPressed: () {
                            _cashController.text = amt.toStringAsFixed(2);
                            setState(() {});
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            side: const BorderSide(color: AppColors.border),
                          ),
                          child: Text(label, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.p16),
                // Change to return — spec: 48px, bold, green, own card
                if (_cashReceived >= widget.cartState.grandTotal)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.p20),
                    decoration: BoxDecoration(
                      color: AppColors.successBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.success.withOpacity(0.3), width: 1.5),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Change to return',
                          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.success, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.currency}${_changeToReturn.toStringAsFixed(2)}',
                          style: AppTextStyles.financialTotal.copyWith(color: AppColors.success, fontSize: 48),
                        ),
                      ],
                    ),
                  ),
              ] else ...[
                // UPI/Card/Credit — waiting state
                Container(
                  padding: const EdgeInsets.all(AppSpacing.p24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _method == 'UPI' ? Icons.qr_code : _method == 'CARD' ? Icons.credit_card : Icons.account_balance_wallet,
                        size: 48,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Waiting for ${_method == 'CREDIT' ? 'Credit' : _method} payment…',
                        style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Click "Complete Sale" once payment is received.',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textDisabled),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.p32),

              // Complete sale button
              PrimaryButton(
                label: _isProcessing ? 'Processing…' : 'Complete Sale',
                isLarge: true,
                isFullWidth: true,
                isLoading: _isProcessing,
                icon: Icons.check_circle_outline,
                onPressed: _isProcessing ? null : _completeSale,
              ),
              const SizedBox(height: AppSpacing.p12),
              // Back button — spec: always visible
              SecondaryButton(
                label: '← Back to Bill',
                isFullWidth: true,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessScreen(Invoice invoice) {
    final change = _method == 'CASH' ? _changeToReturn : 0.0;
    return Scaffold(
      backgroundColor: AppColors.successBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.p32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Green check
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 60),
                ),
              ),
              const SizedBox(height: AppSpacing.p24),
              Text(
                'Payment Successful',
                style: AppTextStyles.h1.copyWith(color: AppColors.success),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.p8),
              Text(
                'Bill #${invoice.id}',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.p32),
              Container(
                padding: const EdgeInsets.all(AppSpacing.p20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _successRow('Amount paid',
                        '${widget.currency}${widget.cartState.grandTotal.toStringAsFixed(2)}'),
                    if (_method == 'CASH' && change > 0) ...[
                      const Divider(height: 20),
                      _successRow('Change to return', '${widget.currency}${change.toStringAsFixed(2)}',
                          valueColor: AppColors.success),
                    ],
                  ],
                ),
              ),
              const Spacer(),
              // Action buttons — spec: NEW SALE visually primary
              PrimaryButton(
                label: 'New Sale',
                isLarge: true,
                isFullWidth: true,
                icon: Icons.add_shopping_cart,
                onPressed: () {
                  widget.onComplete(invoice);
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
              const SizedBox(height: AppSpacing.p12),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'View Bill',
                      icon: Icons.receipt_long_outlined,
                      onPressed: () {
                        widget.onComplete(invoice);
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _successRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary)),
        Text(
          value,
          style: AppTextStyles.financialLine.copyWith(
            fontSize: 20,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
