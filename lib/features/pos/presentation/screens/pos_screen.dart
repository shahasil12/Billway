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
import '../../domain/entities/cart_item.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_inputs.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_containers.dart';
import '../../../../core/widgets/billing_specifics.dart';
import '../../../../core/widgets/app_inputs.dart';

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
    final currency = ref.read(settingsProvider).settings?.currency ?? '\$';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Text('Open POS Session', style: AppTextStyles.h2),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter the opening cash amount in the drawer:', style: AppTextStyles.bodyMedium),
            const SizedBox(height: AppSpacing.p16),
            AppTextField(
              controller: controller,
              label: 'Opening Cash Amount',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: AppSpacing.p16, right: AppSpacing.p8),
                child: Center(
                  widthFactor: 1,
                  child: Text(currency, style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/');
            },
            child: const Text('Cancel & Exit', style: TextStyle(color: AppColors.textSecondary)),
          ),
          PrimaryButton(
            label: 'Open Session',
            onPressed: () async {
              final amount = double.tryParse(controller.text) ?? 0;
              final success = await ref.read(posSessionControllerProvider.notifier).openSession(amount);
              if (success && mounted) {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showCloseSessionDialog() {
    final controller = TextEditingController();
    final currency = ref.read(settingsProvider).settings?.currency ?? '\$';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Text('Close POS Session', style: AppTextStyles.h2),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter the actual cash amount in the drawer:', style: AppTextStyles.bodyMedium),
            const SizedBox(height: AppSpacing.p16),
            AppTextField(
              controller: controller,
              label: 'Closing Cash Amount',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: AppSpacing.p16, right: AppSpacing.p8),
                child: Center(
                  widthFactor: 1,
                  child: Text(currency, style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          PrimaryButton(
            label: 'Close Session',
            onPressed: () async {
              final amount = double.tryParse(controller.text) ?? 0;
              final success = await ref.read(posSessionControllerProvider.notifier).closeSession(amount);
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
    final currency = ref.read(settingsProvider).settings?.currency ?? '\$';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          title: Text('Petty Cash', style: AppTextStyles.h2),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Cash In'),
                      value: 'IN',
                      groupValue: type,
                      onChanged: (val) => setState(() => type = val!),
                      activeColor: AppColors.primary,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Cash Out'),
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
                label: 'Amount',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.p16, right: AppSpacing.p8),
                  child: Center(
                    widthFactor: 1,
                    child: Text(currency, style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary)),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.p16),
              AppTextField(
                controller: reasonController,
                label: 'Reason',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
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
                
                final success = await ref.read(posSessionControllerProvider.notifier)
                    .recordCashMovement(amount, type, reasonController.text.trim());
                    
                if (success && mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cash movement recorded successfully')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCheckoutDialog({bool fromBottomSheet = false}) {
    final cartState = ref.read(posCartControllerProvider);
    final currency = ref.read(settingsProvider).settings?.currency ?? '\$';
    final amountController = TextEditingController(text: cartState.grandTotal.toStringAsFixed(2));
    String paymentMethod = 'CASH';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          title: Text('Checkout', style: AppTextStyles.h2),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total Due', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.p4),
              Text('$currency${cartState.grandTotal.toStringAsFixed(2)}', style: AppTextStyles.h1.copyWith(color: AppColors.primary)),
              const SizedBox(height: AppSpacing.p24),
              
              PaymentMethodSelector(
                selectedMethod: paymentMethod,
                onSelected: (val) => setState(() => paymentMethod = val),
              ),
              const SizedBox(height: AppSpacing.p16),
              
              AppTextField(
                controller: amountController,
                label: 'Amount Paid',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.p16, right: AppSpacing.p8),
                  child: Center(
                    widthFactor: 1,
                    child: Text(currency, style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            PrimaryButton(
              label: 'Complete Sale',
              isLarge: true,
              onPressed: () async {
                if (paymentMethod == 'CREDIT' && cartState.customer == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a customer for CREDIT payments')),
                  );
                  return;
                }
                
                final amount = paymentMethod == 'CREDIT' ? 0.0 : (double.tryParse(amountController.text) ?? 0);
                final invoice = await ref.read(posCartControllerProvider.notifier).checkout(amount, paymentMethod);
                if (invoice != null && mounted) {
                  Navigator.pop(context);
                  if (fromBottomSheet) Navigator.pop(context);
                  ref.read(posCartControllerProvider.notifier).clearCart();
                  context.push('/invoices/${invoice.id}', extra: invoice);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Sale successful! Invoice #${invoice.id}'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
            ),
          ],
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
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final currency = ref.watch(settingsProvider).settings?.currency ?? '\$';

    // When session check finishes and no session found, show dialog once
    if (!sessionState.isLoading && sessionState.session == null && !_dialogShown) {
      _dialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showOpenSessionDialog();
      });
    }

    if (sessionState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (sessionState.session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Point of Sale')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.point_of_sale, size: 64, color: AppColors.textDisabled),
              const SizedBox(height: AppSpacing.p16),
              const Text('No Active Session', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.p24),
              PrimaryButton(
                label: 'Open Session',
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

    final products = productsState.products;
    final filteredProducts = _selectedCategoryId == null
        ? products
        : products.where((p) => p.categoryId == _selectedCategoryId).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Point of Sale'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p8),
            child: SecondaryButton(
              label: 'Petty Cash',
              onPressed: _showPettyCashDialog,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16),
            child: SecondaryButton(
              label: 'Close Session',
              onPressed: _showCloseSessionDialog,
            ),
          )
        ],
      ),
      body: isTablet
          ? _buildTabletLayout(filteredProducts, cartState, categoriesState.categories, currency)
          : _buildPhoneLayout(filteredProducts, cartState, categoriesState.categories, currency),
    );
  }


  Widget _buildTabletLayout(List<Product> products, POSCartState cartState, List<dynamic> categories, String currency) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // CATEGORIES SIDEBAR
        Container(
          width: 200,
          color: AppColors.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.p16),
                child: Text('Categories', style: AppTextStyles.h3),
              ),
              Expanded(
                child: ListView(
                  children: [
                    _buildCategoryItem('All', null),
                    ...categories.map((c) => _buildCategoryItem(c.name, c.id)),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const VerticalDivider(width: 1, color: AppColors.border),
        
        // PRODUCTS GRID
        Expanded(
          flex: 2,
          child: _buildProductsGrid(products, 3, currency),
        ),
        
        const VerticalDivider(width: 1, color: AppColors.border),
        
        // CART SIDEBAR
        Container(
          width: 350,
          color: AppColors.surface,
          child: _buildCartSidebar(cartState, currency),
        ),
      ],
    );
  }

  Widget _buildPhoneLayout(List<Product> products, POSCartState cartState, List<dynamic> categories, String currency) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // CATEGORIES TABS
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16, vertical: AppSpacing.p8),
            children: [
              _buildCategoryChip('All', null),
              ...categories.map((c) => _buildCategoryChip(c.name, c.id)),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        // PRODUCTS GRID
        Expanded(
          child: _buildProductsGrid(products, 2, currency),
        ),
        // MINI CART BAR
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16, vertical: AppSpacing.p12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: const Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${cartState.items.length} items', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                  Text('$currency${cartState.grandTotal.toStringAsFixed(2)}', style: AppTextStyles.h2.copyWith(color: AppColors.primary)),
                ],
              ),
              PrimaryButton(
                label: 'View Cart & Pay',
                onPressed: () => _showPhoneCartSheet(cartState, currency),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(String name, int? id) {
    final isSelected = _selectedCategoryId == id;
    return InkWell(
      onTap: () => setState(() => _selectedCategoryId = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p24, vertical: AppSpacing.p16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : Colors.transparent,
          border: Border(left: BorderSide(color: isSelected ? AppColors.primary : Colors.transparent, width: 4)),
        ),
        child: Text(
          name, 
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
  
  Widget _buildCategoryChip(String name, int? id) {
    final isSelected = _selectedCategoryId == id;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.p8),
      child: ChoiceChip(
        label: Text(name),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedCategoryId = id),
        selectedColor: AppColors.primaryLight,
        labelStyle: TextStyle(color: isSelected ? AppColors.primary : AppColors.textPrimary),
      ),
    );
  }

  Widget _buildProductsGrid(List<Product> products, int crossAxisCount, String currency) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(productListProvider.notifier).fetchProducts(isRefresh: true);
        await ref.read(categoryListProvider.notifier).fetchCategories();
      },
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.p16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.85,
        crossAxisSpacing: AppSpacing.p16,
        mainAxisSpacing: AppSpacing.p16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final p = products[index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Material(
            color: AppColors.surface,
            elevation: 1,
            child: InkWell(
              onTap: () => ref.read(posCartControllerProvider.notifier).addProduct(p),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Container(
                      color: AppColors.surfaceAlt,
                      child: p.image != null
                          ? Image.network(
                              p.image!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.inventory_2_outlined, size: 40, color: AppColors.textDisabled),
                              ),
                            )
                          : const Center(
                              child: Icon(Icons.inventory_2_outlined, size: 40, color: AppColors.textDisabled),
                            ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.p12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$currency${p.price.toStringAsFixed(2)}',
                          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ));
  }


  Widget _buildCartSidebar(POSCartState cartState, String currency, {bool fromBottomSheet = false}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.p16),
          color: AppColors.surface,
          child: Row(
            children: [
              const Icon(Icons.shopping_cart_outlined, color: AppColors.textPrimary),
              const SizedBox(width: AppSpacing.p8),
              Text('Current Order', style: AppTextStyles.h3),
              const Spacer(),
              if (cartState.items.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.error),
                  onPressed: () => ref.read(posCartControllerProvider.notifier).clearCart(),
                  tooltip: 'Clear Cart',
                ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: cartState.items.isEmpty
              ? const Center(child: Text('Cart is empty', style: TextStyle(color: AppColors.textSecondary)))
              : ListView.separated(
                  itemCount: cartState.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                  itemBuilder: (context, index) {
                    final item = cartState.items[index];
                    return Padding(
                      padding: const EdgeInsets.all(AppSpacing.p16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.product.name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text('$currency${item.unitPrice.toStringAsFixed(2)}', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          QuantityStepper(
                            value: item.quantity,
                            onChanged: (val) {
                              ref.read(posCartControllerProvider.notifier).updateQuantity(item.product.id!, val);
                            },
                          ),
                          const SizedBox(width: AppSpacing.p12),
                          SizedBox(
                            width: 60,
                            child: Text(
                              '$currency${(item.unitPrice * item.quantity).toStringAsFixed(2)}', 
                              style: AppTextStyles.financialLine.copyWith(fontWeight: FontWeight.w700),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
          ),
          padding: const EdgeInsets.all(AppSpacing.p16),
          child: Column(
            children: [
              DropdownButtonFormField<int?>(
                value: cartState.customer?.id,
                decoration: const InputDecoration(
                  labelText: 'Customer',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Walk-in Customer'),
                  ),
                  ...ref.watch(customerListProvider).customers.map((c) {
                    return DropdownMenuItem<int?>(
                      value: c.id,
                      child: Text(c.name),
                    );
                  }),
                ],
                onChanged: (val) {
                  if (val == null) {
                    ref.read(posCartControllerProvider.notifier).clearCustomer();
                  } else {
                    final customer = ref.read(customerListProvider).customers.firstWhere((c) => c.id == val);
                    ref.read(posCartControllerProvider.notifier).setCustomer(customer);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.p16),
              TotalsBlock(
                subtotal: cartState.subtotal,
                discountAmount: cartState.discountAmount,
                taxTotal: cartState.taxTotal,
                grandTotal: cartState.grandTotal,
                currency: currency,
              ),
              const SizedBox(height: AppSpacing.p16),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  isLarge: true,
                  label: 'Pay Now',
                  onPressed: cartState.items.isEmpty ? null : () => _showCheckoutDialog(fromBottomSheet: fromBottomSheet),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  void _showPhoneCartSheet(POSCartState initialCartState, String currency) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final cartState = ref.watch(posCartControllerProvider);
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.p16),
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Cart', style: AppTextStyles.h2),
                          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                        ],
                      ),
                    ),
                    Expanded(child: _buildCartSidebar(cartState, currency, fromBottomSheet: true)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
