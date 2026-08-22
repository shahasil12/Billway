import 'package:flutter/material.dart';
import '../../../../core/providers.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../domain/entities/product.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';
import '../../../../features/auth/domain/entities/user.dart';
import '../controllers/product_list_controller.dart';

class ProductDetailScreen extends ConsumerWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(settingsProvider).settings?.currency ?? '\$';
    final user = ref.watch(authStateProvider).value;
    final isAdmin = user?.role == UserRole.admin;

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Product'),
                    content: const Text('Are you sure you want to delete this product?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true), 
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  final success = await ref.read(productListProvider.notifier).deleteProduct(product.id!);
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted')));
                    context.pop();
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(ref.read(productListProvider).error ?? 'Failed to delete')),
                    );
                  }
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (product.image != null && product.image!.isNotEmpty)
              product.image!.startsWith('http')
                  ? Image.network(
                      product.image!,
                      height: 250,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 250,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                      ),
                    )
                  : Image.file(
                      File(product.image!),
                      height: 250,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 250,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                      ),
                    )
            else
              Container(
                height: 250,
                color: Colors.grey[200],
                child: const Icon(Icons.inventory, size: 80, color: Colors.grey),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        '$currency${product.price.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(product.categoryName ?? 'Uncategorized'),
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    labelStyle: const TextStyle(color: Colors.blue),
                  ),
                  const SizedBox(height: 24),
                  _buildDetailRow('Stock', product.stock.toString()),
                  _buildDetailRow('Tax', '${product.taxPercentage}%'),
                  if (product.barcode != null && product.barcode!.isNotEmpty)
                    _buildDetailRow('Barcode', product.barcode!),
                  _buildDetailRow('Status', product.status ? 'Active' : 'Inactive'),
                  const SizedBox(height: 24),
                  const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    product.description?.isNotEmpty == true ? product.description! : 'No description provided.',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
