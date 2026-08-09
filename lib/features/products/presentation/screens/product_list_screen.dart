import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../controllers/product_list_controller.dart';
import '../../../categories/presentation/controllers/category_list_controller.dart';
import 'dart:async';

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

    ref.listen<ProductListState>(productListProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.error!)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search products by name or barcode...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                ),
              ),
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  itemCount: categoryState.categories.length + 1,
                  itemBuilder: (context, index) {
                    final isAll = index == 0;
                    final category = isAll ? null : categoryState.categories[index - 1];
                    final isSelected = state.categoryId == category?.id;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(isAll ? 'All Categories' : category!.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          ref.read(productListProvider.notifier).setCategoryFilter(category?.id);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(productListProvider.notifier).fetchProducts(isRefresh: true),
        child: state.products.isEmpty && state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : state.products.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 100),
                      Center(child: Text('No products found.')),
                    ],
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: state.products.length + (state.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.products.length) {
                        return const Center(child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ));
                      }
                      final product = state.products[index];
                      return Dismissible(
                        key: ValueKey(product.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onSurface),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text("Confirm"),
                                content: const Text("Are you sure you wish to delete this product?"),
                                actions: [
                                  TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("CANCEL")),
                                  TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text("DELETE")),
                                ],
                              );
                            },
                          );
                        },
                        onDismissed: (direction) {
                          ref.read(productListProvider.notifier).deleteProduct(product.id!);
                        },
                        child: ListTile(
                          leading: product.image != null 
                              ? Image.network(product.image!, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.image))
                              : const Icon(Icons.inventory, size: 40),
                          title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${product.categoryName ?? 'No Category'} | Stock: ${product.stock}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('$currency${product.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => context.push('/products/edit', extra: product),
                              ),
                            ],
                          ),
                          onTap: () => context.push('/products/${product.id}', extra: product),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/products/add');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
