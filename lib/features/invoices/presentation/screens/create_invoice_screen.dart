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
import '../../../../core/widgets/barcode_scanner_screen.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_inputs.dart';
import '../../../../core/widgets/app_containers.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/billing_specifics.dart';

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
  final _barcodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerListProvider.notifier).fetchCustomers();
      ref.read(productListProvider.notifier).fetchProducts();
    });
  }

  @override
  void dispose() {
    _discountController.dispose();
    _referenceController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  void _showAddProductModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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

  void _handleScannedBarcode(String barcode) {
    if (barcode.isEmpty) return;
    
    final products = ref.read(productListProvider).products;
    try {
      final product = products.firstWhere((p) => p.barcode == barcode && p.status);
      if (product.stock < 1) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Not enough stock for ${product.name}')));
        return;
      }
      
      setState(() {
        final existingIndex = _items.indexWhere((i) => i.productId == product.id);
        if (existingIndex >= 0) {
          final existing = _items[existingIndex];
          if (existing.quantity + 1 > product.stock) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Not enough stock. Max: ${product.stock}')));
            return;
          }
          _items[existingIndex] = InvoiceItem(
            productId: existing.productId,
            productName: existing.productName,
            quantity: existing.quantity + 1,
            unitPrice: existing.unitPrice,
            taxPercentage: existing.taxPercentage,
          );
        } else {
          _items.add(InvoiceItem(
            productId: product.id!,
            productName: product.name,
            quantity: 1,
            unitPrice: product.price,
            taxPercentage: product.taxPercentage,
          ));
        }
        _barcodeController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added ${product.name} to invoice')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Product not found for barcode: $barcode')));
    }
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
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Invoice'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan Barcode',
            onPressed: () async {
              final scannedCode = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BarcodeScannerScreen(),
                ),
              );
              if (scannedCode != null && scannedCode is String) {
                _handleScannedBarcode(scannedCode);
              }
            },
          ),
          const SizedBox(width: AppSpacing.p8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? AppSpacing.p32 : AppSpacing.p16,
                  vertical: AppSpacing.p16,
                ),
                children: [
                  _buildCustomerSection(customers),
                  const SizedBox(height: AppSpacing.p24),
                  _buildCartSection(currency),
                  const SizedBox(height: AppSpacing.p24),
                  _buildDetailsSection(),
                  const SizedBox(height: AppSpacing.p24),
                  _buildPaymentSection(),
                ],
              ),
            ),
            _buildCheckoutBar(currency),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSection(List<Customer> customers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Customer Details', style: AppTextStyles.h3),
        const SizedBox(height: AppSpacing.p16),
        AppCard(
          child: Column(
            children: [
              DropdownButtonFormField<Customer>(
                decoration: InputDecoration(
                  labelText: 'Select Customer *',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    borderSide: BorderSide.none,
                  ),
                ),
                value: _selectedCustomer,
                items: customers.map((c) => DropdownMenuItem(value: c, child: Text(c.name, style: AppTextStyles.bodyMedium))).toList(),
                onChanged: (val) => setState(() => _selectedCustomer = val),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCartSection(String currency) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Cart Items', style: AppTextStyles.h3),
            TextButton.icon(
              onPressed: _showAddProductModal,
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.p8),
        
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16, vertical: AppSpacing.p8),
          child: Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Barcode',
                  controller: _barcodeController,
                  hint: 'Enter barcode manually...',
                  onFieldSubmitted: _handleScannedBarcode,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.search, color: AppColors.primary),
                onPressed: () => _handleScannedBarcode(_barcodeController.text.trim()),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.p16),
        
        if (_items.isEmpty)
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.p32),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.shopping_cart_outlined, size: 48, color: AppColors.textDisabled),
                  const SizedBox(height: AppSpacing.p16),
                  const Text('Cart is empty', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
          )
        else
          AppCard(
            padding: EdgeInsets.zero,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _items[index];
                final lineTotal = item.unitPrice! * item.quantity;
                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.p16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.productName!, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('$currency${item.unitPrice} (Tax: ${item.taxPercentage}%)', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      QuantityStepper(
                        value: item.quantity,
                        onChanged: (val) {
                          if (val > 0) {
                            setState(() => _items[index] = InvoiceItem(
                              productId: item.productId,
                              productName: item.productName,
                              quantity: val,
                              unitPrice: item.unitPrice,
                              taxPercentage: item.taxPercentage,
                            ));
                          }
                        },
                      ),
                      const SizedBox(width: AppSpacing.p16),
                      SizedBox(
                        width: 80,
                        child: Text(
                          '$currency${lineTotal.toStringAsFixed(2)}',
                          style: AppTextStyles.financialLine.copyWith(fontWeight: FontWeight.w700),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.error),
                        onPressed: () => setState(() => _items.removeAt(index)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Invoice Details', style: AppTextStyles.h3),
        const SizedBox(height: AppSpacing.p16),
        AppCard(
          child: Column(
            children: [
              AppTextField(
                label: 'Reference Number (Optional)',
                controller: _referenceController,
              ),
              const SizedBox(height: AppSpacing.p16),
              AppTextField(
                label: 'Discount Percentage (%)',
                controller: _discountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (val) {
                  setState(() {
                    _discountPercentage = double.tryParse(val) ?? 0.0;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payment Method', style: AppTextStyles.h3),
        const SizedBox(height: AppSpacing.p16),
        PaymentMethodSelector(
          selectedMethod: _paymentMethod,
          onSelected: (val) => setState(() => _paymentMethod = val),
        ),
      ],
    );
  }

  Widget _buildCheckoutBar(String currency) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.p16),
      child: Column(
        children: [
          TotalsBlock(
            subtotal: _calculatedSubtotal,
            discountAmount: _calculatedDiscount,
            taxTotal: _calculatedTax,
            grandTotal: _calculatedGrandTotal,
            currency: currency,
          ),
          const SizedBox(height: AppSpacing.p16),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              isLarge: true,
              label: 'Generate Invoice',
              isLoading: _isLoading,
              onPressed: _submit,
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
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productListProvider).products.where((p) => p.status).toList();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.p24,
        left: AppSpacing.p24,
        right: AppSpacing.p24,
        top: AppSpacing.p24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add Product', style: AppTextStyles.h2),
          const SizedBox(height: AppSpacing.p24),
          DropdownButtonFormField<Product>(
            decoration: InputDecoration(
              labelText: 'Select Product',
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: BorderSide.none,
              ),
            ),
            value: _selectedProduct,
            items: products.map((p) => DropdownMenuItem(value: p, child: Text('${p.name} (Stock: ${p.stock})'))).toList(),
            onChanged: (val) => setState(() {
              _selectedProduct = val;
              _qty = 1;
              _qtyController.text = '1';
            }),
          ),
          const SizedBox(height: AppSpacing.p24),
          
          if (_selectedProduct != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Quantity', style: AppTextStyles.bodyLarge),
                QuantityStepper(
                  value: _qty,
                  onChanged: (val) {
                    if (val > 0) {
                      setState(() {
                        _qty = val;
                        _qtyController.text = val.toString();
                      });
                    }
                  },
                ),
              ],
            ),
            
          const SizedBox(height: AppSpacing.p32),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              isLarge: true,
              label: 'Add to Cart',
              onPressed: () {
                if (_selectedProduct != null) {
                  if (_qty > _selectedProduct!.stock) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Not enough stock. Max: ${_selectedProduct!.stock}')));
                    return;
                  }
                  widget.onAdd(_selectedProduct!, _qty);
                  Navigator.pop(context);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
