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

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(productListProvider.notifier).fetchProducts();
      ref.read(categoryListProvider.notifier).fetchCategories();
      ref.read(customerListProvider.notifier).fetchCustomers();
    });
  }

  void _showOpenSessionDialog() {
    final controller = TextEditingController();
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
              prefixIcon: const Icon(Icons.attach_money),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.go('/'),
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
              prefixIcon: const Icon(Icons.attach_money),
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

  void _showCheckoutDialog() {
    final cartState = ref.read(posCartControllerProvider);
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
              Text('\$${cartState.grandTotal.toStringAsFixed(2)}', style: AppTextStyles.h1.copyWith(color: AppColors.primary)),
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
                prefixIcon: const Icon(Icons.attach_money),
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
                final amount = double.tryParse(amountController.text) ?? 0;
                final invoice = await ref.read(posCartControllerProvider.notifier).checkout(amount, paymentMethod);
                if (invoice != null && mounted) {
                  Navigator.pop(context);
                  ref.read(posCartControllerProvider.notifier).clearCart();
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

    ref.listen<POSSessionState>(posSessionControllerProvider, (previous, next) {
      final wasLoading = previous?.isLoading ?? true;
      if (wasLoading && !next.isLoading && next.session == null) {
        _showOpenSessionDialog();
      }
    });

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
                onPressed: _showOpenSessionDialog,
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
      appBar: AppBar(
        title: const Text('Point of Sale'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16),
            child: SecondaryButton(
              label: 'Close Session',
              onPressed: _showCloseSessionDialog,
            ),
          )
        ],
      ),
      body: isTablet ? _buildTabletLayout(filteredProducts, cartState, categoriesState.categories) : _buildPhoneLayout(filteredProducts, cartState, categoriesState.categories),
    );
  }

  Widget _buildTabletLayout(List<Product> products, POSCartState cartState, List<dynamic> categories) {
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
          child: _buildProductsGrid(products, 3),
        ),
        
        const VerticalDivider(width: 1, color: AppColors.border),
        
        // CART SIDEBAR
        Container(
          width: 350,
          color: AppColors.surface,
          child: _buildCartSidebar(cartState),
        ),
      ],
    );
  }

  Widget _buildPhoneLayout(List<Product> products, POSCartState cartState, List<dynamic> categories) {
    return Column(
      children: [
        // CATEGORIES TABS
        SizedBox(
          height: 60,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16, vertical: AppSpacing.p8),
            children: [
              _buildCategoryChip('All', null),
              ...categories.map((c) => _buildCategoryChip(c.name, c.id)),
            ],
          ),
        ),
        
        // PRODUCTS GRID
        Expanded(
          child: _buildProductsGrid(products, 2),
        ),
        
        // BOTTOM SHEET CART SUMMRAY (Mini cart)
        Container(
          padding: const EdgeInsets.all(AppSpacing.p16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${cartState.items.length} items', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                  Text('\$${cartState.grandTotal.toStringAsFixed(2)}', style: AppTextStyles.h2.copyWith(color: AppColors.primary)),
                ],
              ),
              PrimaryButton(
                label: 'View Cart & Pay',
                onPressed: () => _showPhoneCartSheet(cartState),
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

  Widget _buildProductsGrid(List<Product> products, int crossAxisCount) {
    return GridView.builder(
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
        return AppCard(
          padding: EdgeInsets.zero,
          onTap: () => ref.read(posCartControllerProvider.notifier).addProduct(p),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  color: AppColors.surfaceAlt,
                  child: p.image != null 
                    ? Image.network(p.image!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2_outlined, size: 40, color: AppColors.textDisabled))
                    : const Icon(Icons.inventory_2_outlined, size: 40, color: AppColors.textDisabled),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.p12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('\$${p.price.toStringAsFixed(2)}', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCartSidebar(POSCartState cartState) {
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
                                Text('\$${item.unitPrice.toStringAsFixed(2)}', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          QuantityStepper(
                            value: item.quantity,
                            onChanged: (val) {
                              if (val > 0) {
                                ref.read(posCartControllerProvider.notifier).updateQuantity(item.product.id!, val);
                              } else {
                                // removing item handling if quantity is 0? The pos controller might handle it, or I can do:
                                // but steppers usually prevent going to 0 unless specifically built for it.
                              }
                            },
                          ),
                          const SizedBox(width: AppSpacing.p12),
                          SizedBox(
                            width: 60,
                            child: Text(
                              '\$${(item.unitPrice * item.quantity).toStringAsFixed(2)}', 
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
              TotalsBlock(
                subtotal: cartState.subtotal,
                discountAmount: cartState.discountAmount,
                taxTotal: cartState.taxTotal,
                grandTotal: cartState.grandTotal,
              ),const SizedBox(height: AppSpacing.p16),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  isLarge: true,
                  label: 'Pay Now',
                  onPressed: cartState.items.isEmpty ? null : _showCheckoutDialog,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  void _showPhoneCartSheet(POSCartState cartState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
                Expanded(child: _buildCartSidebar(cartState)),
              ],
            ),
          ),
        );
      },
    );
  }
}
