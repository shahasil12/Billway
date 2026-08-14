import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/product.dart';
import '../widgets/product_form_widget.dart';
import '../../../../core/providers.dart';
import '../controllers/product_list_controller.dart';

class AddEditProductScreen extends ConsumerStatefulWidget {
  final Product? product;

  const AddEditProductScreen({super.key, this.product});

  @override
  ConsumerState<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends ConsumerState<AddEditProductScreen> {
  bool _isLoading = false;

  void _handleSubmit(Product product, String? imagePath) async {
    setState(() => _isLoading = true);
    final repo = ref.read(productRepositoryProvider);
    
    final result = widget.product == null 
        ? await repo.createProduct(product, imagePath: imagePath)
        : await repo.updateProduct(product, imagePath: imagePath);
        
    setState(() => _isLoading = false);

    result.fold(
      (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message)));
        }
      },
      (_) {
        ref.read(productListProvider.notifier).fetchProducts(isRefresh: true);
        if (mounted) context.pop();
      }
    );
  }

  void _showDeleteDialog(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete ${product.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final repo = ref.read(productRepositoryProvider);
              final result = await repo.deleteProduct(product.id!);
              result.fold(
                (failure) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message)));
                },
                (_) {
                  ref.read(productListProvider.notifier).fetchProducts(isRefresh: true);
                  if (mounted) context.pop(); // Go back to list
                }
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'Add Product'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteDialog(context, widget.product!),
            ),
        ],
      ),
      body: ProductFormWidget(
        initialProduct: widget.product,
        onSubmit: _handleSubmit,
        isLoading: _isLoading,
      ),
    );
  }
}
