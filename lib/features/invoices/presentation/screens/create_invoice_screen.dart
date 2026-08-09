import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/invoice.dart';
import '../../../../core/providers.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../../customers/presentation/controllers/customer_list_controller.dart';
import '../../../products/presentation/controllers/product_list_controller.dart';
import '../../../customers/domain/entities/customer.dart';
import '../../../products/domain/entities/product.dart';
import '../controllers/invoice_list_controller.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  ConsumerState<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  Customer? _selectedCustomer;
  final List<InvoiceItem> _items = [];
  double _discountPercentage = 0.0;
  String _paymentMethod = 'CASH';
  bool _isLoading = false;

  final _discountController = TextEditingController(text: '0');
  final _referenceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerListProvider.notifier).fetchCustomers(isRefresh: true);
      ref.read(productListProvider.notifier).fetchProducts(isRefresh: true);
    });
  }

  @override
  void dispose() {
    _discountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  void _showAddProductModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _AddProductBottomSheet(
          onAdd: (product, qty) {
            setState(() {
              final existingIndex = _items.indexWhere((i) => i.productId == product.id);
              if (existingIndex >= 0) {
                final existing = _items[existingIndex];
                _items[existingIndex] = InvoiceItem(
                  productId: existing.productId,
                  productName: existing.productName,
                  quantity: existing.quantity + qty,
                  unitPrice: existing.unitPrice,
                  taxPercentage: existing.taxPercentage,
                );
              } else {
                _items.add(InvoiceItem(
                  productId: product.id!,
                  productName: product.name,
                  quantity: qty,
                  unitPrice: product.price,
                  taxPercentage: product.taxPercentage,
                ));
              }
            });
          },
        );
      }
    );
  }

  double get _calculatedSubtotal {
    return _items.fold(0, (sum, item) => sum + (item.unitPrice! * item.quantity));
  }
  
  double get _calculatedDiscount {
    return _calculatedSubtotal * (_discountPercentage / 100);
  }

  double get _calculatedTax {
    double tax = 0;
    for (var item in _items) {
      final lineSubtotal = item.unitPrice! * item.quantity;
      final discountedLine = lineSubtotal * (1 - _discountPercentage / 100);
      tax += discountedLine * (item.taxPercentage! / 100);
    }
    return tax;
  }

  double get _calculatedGrandTotal {
    return _calculatedSubtotal - _calculatedDiscount + _calculatedTax;
  }

  void _submit() async {
    if (_isLoading) return;

    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a customer')));
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one product')));
      return;
    }

    setState(() => _isLoading = true);

    final invoice = Invoice(
      customerId: _selectedCustomer!.id!,
      reference: _referenceController.text.trim().isNotEmpty ? _referenceController.text.trim() : null,
      discountPercentage: _discountPercentage,
      paymentMethod: _paymentMethod,
      items: _items,
    );

    final result = await ref.read(invoiceRepositoryProvider).createInvoice(invoice);
    
    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (failure) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message)));
      },
      (newInvoice) {
        ref.read(invoiceListProvider.notifier).fetchInvoices(isRefresh: true);
        ref.refresh(dashboardSummaryProvider); // Refresh dashboard to show new invoice
        if (mounted) {
          context.pop();
          context.push('/invoices/${newInvoice.id}', extra: newInvoice);
        }
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customerListProvider).customers;
    final currency = ref.watch(settingsProvider).settings?.currency ?? '\$';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Invoice'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                DropdownButtonFormField<Customer>(
                  decoration: const InputDecoration(labelText: 'Select Customer', border: OutlineInputBorder()),
                  value: _selectedCustomer,
                  items: customers.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                  onChanged: (val) => setState(() => _selectedCustomer = val),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _referenceController,
                  decoration: const InputDecoration(labelText: 'Reference Number (Optional)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Products', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      onPressed: _showAddProductModal,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Item'),
                    ),
                  ],
                ),
                const Divider(),
                if (_items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: Text('No products added yet.', style: TextStyle(color: Colors.grey))),
                  )
                else
                  ..._items.map((item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.productName!),
                    subtitle: Text('$currency${item.unitPrice} x ${item.quantity} (Tax: ${item.taxPercentage}%)'),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _items.remove(item);
                        });
                      },
                    ),
                  )),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _discountController,
                        decoration: const InputDecoration(labelText: 'Discount %', border: OutlineInputBorder()),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (val) {
                          setState(() {
                            _discountPercentage = double.tryParse(val) ?? 0.0;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Payment Method', border: OutlineInputBorder()),
                        value: _paymentMethod,
                        items: ['CASH', 'CARD', 'UPI', 'OTHER'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                        onChanged: (val) => setState(() => _paymentMethod = val!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Expected Total:', style: TextStyle(color: Colors.grey)),
                      Text(
                        '$currency${_calculatedGrandTotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading ? const CircularProgressIndicator(color: Theme.of(context).colorScheme.onSurface) : const Text('Generate Invoice & Save', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddProductBottomSheet extends ConsumerStatefulWidget {
  final Function(Product, int) onAdd;
  const _AddProductBottomSheet({required this.onAdd});

  @override
  ConsumerState<_AddProductBottomSheet> createState() => _AddProductBottomSheetState();
}

class _AddProductBottomSheetState extends ConsumerState<_AddProductBottomSheet> {
  Product? _selectedProduct;
  final _qtyController = TextEditingController(text: '1');

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productListProvider).products.where((p) => p.status).toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Select Product', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          DropdownButtonFormField<Product>(
            decoration: const InputDecoration(labelText: 'Product', border: OutlineInputBorder()),
            value: _selectedProduct,
            items: products.map((p) => DropdownMenuItem(value: p, child: Text('${p.name} (Stock: ${p.stock})'))).toList(),
            onChanged: (val) => setState(() => _selectedProduct = val),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _qtyController,
            decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_selectedProduct != null) {
                  final qty = int.tryParse(_qtyController.text) ?? 1;
                  if (qty > _selectedProduct!.stock) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Not enough stock. Max: ${_selectedProduct!.stock}')));
                    return;
                  }
                  widget.onAdd(_selectedProduct!, qty);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add to Invoice'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
