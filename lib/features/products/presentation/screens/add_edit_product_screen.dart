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

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'Add Product'),
      ),
      body: ProductFormWidget(
        initialProduct: widget.product,
        onSubmit: _handleSubmit,
        isLoading: _isLoading,
      ),
    );
  }
}
