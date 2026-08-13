import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import '../../../../core/providers.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../controllers/product_list_controller.dart';
import '../../../categories/presentation/controllers/category_list_controller.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_inputs.dart';
import '../../../../core/widgets/app_containers.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../domain/entities/product.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
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
      ref.read(productListProvider.notifier).fetchProducts();
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(productListProvider.notifier).setSearchQuery(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productListProvider);
    final currency = ref.watch(settingsProvider).settings?.currency ?? '\$';
    final categoryState = ref.watch(categoryListProvider);
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16),
            child: PrimaryButton(
              label: 'Add Product',
              onPressed: () => context.push('/products/add'),
            ),
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(116),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? AppSpacing.p32 : AppSpacing.p16,
                  vertical: AppSpacing.p8,
                ),
                child: SearchField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  hint: 'Search products by name or barcode...',
                ),
              ),
              SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: isTablet ? AppSpacing.p32 : AppSpacing.p16),
                  itemCount: categoryState.categories.length + 1,
                  itemBuilder: (context, index) {
                    final isAll = index == 0;
                    final category = isAll ? null : categoryState.categories[index - 1];
                    final isSelected = state.categoryId == category?.id;

                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.p8),
                      child: ChoiceChip(
                        label: Text(isAll ? 'All Categories' : category!.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          ref.read(productListProvider.notifier).setCategoryFilter(category?.id);
                        },
                        selectedColor: AppColors.primaryLight,
                        labelStyle: AppTextStyles.bodyMedium.copyWith(
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : AppColors.border,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.p8),
            ],
          ),
        ),
      ),
      body: _buildBody(context, state, currency, isTablet),
    );
  }

  Widget _buildBody(BuildContext context, ProductListState state, String currency, bool isTablet) {
    if (state.isLoading && state.products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.products.isEmpty) {
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
                onPressed: () => ref.read(productListProvider.notifier).fetchProducts(isRefresh: true),
              ),
            ),
          ],
        ),
      );
    }

    if (state.products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textDisabled),
            const SizedBox(height: AppSpacing.p16),
            const Text('No products found', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.p24),
            SizedBox(
              width: 200,
              child: PrimaryButton(
                label: 'Add First Product',
                onPressed: () => context.push('/products/add'),
              ),
            ),
          ],
        ),
      );
    }

    final crossAxisCount = isTablet ? 3 : 2;

    return RefreshIndicator(
      onRefresh: () => ref.read(productListProvider.notifier).fetchProducts(isRefresh: true),
      child: GridView.builder(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? AppSpacing.p32 : AppSpacing.p16,
          vertical: AppSpacing.p16,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: AppSpacing.p16,
          mainAxisSpacing: AppSpacing.p16,
          childAspectRatio: 0.8,
        ),
        itemCount: state.products.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.products.length) {
            return const Center(child: CircularProgressIndicator());
          }
          final product = state.products[index];
          return _buildProductCard(context, product, currency);
        },
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product, String currency) {
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () => context.push('/products/${product.id}', extra: product),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (product.image != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.p12)),
                    child: Image.network(
                      // Cache-bust with product ID to force reload after edits
                      '${product.image!}?v=${product.id}',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                    ),
                  )
                else
                  _buildPlaceholder(),
                Positioned(
                  top: AppSpacing.p8,
                  right: AppSpacing.p8,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: product.status ? AppColors.success : AppColors.textDisabled,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
              padding: const EdgeInsets.all(AppSpacing.p12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product.categoryName ?? 'No Category',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$currency${product.price.toStringAsFixed(2)}',
                        style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.textSecondary),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => context.push('/products/edit', extra: product),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.p12)),
      ),
      child: const Icon(Icons.inventory_2_outlined, size: 40, color: AppColors.textDisabled),
    );
  }
}
