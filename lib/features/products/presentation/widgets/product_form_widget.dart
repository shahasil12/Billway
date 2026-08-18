import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';

import '../../../categories/presentation/controllers/category_list_controller.dart';
import '../../domain/entities/product.dart';
import '../../../../core/widgets/barcode_scanner_screen.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_inputs.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_containers.dart';

class ProductFormWidget extends ConsumerStatefulWidget {
  final Product? initialProduct;
  final Function(Product, String?) onSubmit;
  final bool isLoading;

  const ProductFormWidget({
    super.key,
    this.initialProduct,
    required this.onSubmit,
    this.isLoading = false,
  });

  @override
  ConsumerState<ProductFormWidget> createState() => _ProductFormWidgetState();
}

class _ProductFormWidgetState extends ConsumerState<ProductFormWidget> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _taxController;
  late TextEditingController _barcodeController;
  late TextEditingController _descriptionController;
  late TextEditingController _stockController;
  
  int? _selectedCategoryId;
  bool _isActive = true;
  File? _imageFile;
  bool _isAdvancedExpanded = false;
  
  String _productType = 'NORMAL';
  bool _trackStock = false;
  late TextEditingController _minStockController;
  String _unit = 'Piece';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialProduct?.name ?? '');
    _priceController = TextEditingController(text: widget.initialProduct?.price.toString() ?? '');
    _taxController = TextEditingController(text: widget.initialProduct?.taxPercentage.toString() ?? '0.0');
    _barcodeController = TextEditingController(text: widget.initialProduct?.barcode ?? '');
    _descriptionController = TextEditingController(text: widget.initialProduct?.description ?? '');
    _stockController = TextEditingController(text: widget.initialProduct?.stock.toString() ?? '0');
    _minStockController = TextEditingController(text: widget.initialProduct?.minStock.toString() ?? '0');
    _selectedCategoryId = widget.initialProduct?.categoryId;
    _isActive = widget.initialProduct?.status ?? true;
    _productType = widget.initialProduct?.productType ?? 'NORMAL';
    _trackStock = widget.initialProduct?.trackStock ?? false;
    _unit = widget.initialProduct?.unit ?? 'Piece';
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryListProvider.notifier).fetchCategories();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _taxController.dispose();
    _barcodeController.dispose();
    _descriptionController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Library'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')),
        );
        return;
      }
      final product = Product(
        id: widget.initialProduct?.id,
        name: _nameController.text.trim(),
        categoryId: _selectedCategoryId,
        productType: _productType,
        trackStock: _trackStock,
        minStock: int.tryParse(_minStockController.text.trim()) ?? 0,
        unit: _unit,
        price: double.parse(_priceController.text.trim()),
        taxPercentage: double.parse(_taxController.text.trim()),
        barcode: _barcodeController.text.trim(),
        description: _descriptionController.text.trim(),
        stock: int.tryParse(_stockController.text.trim()) ?? 0,
        status: _isActive,
      );
      widget.onSubmit(product, _imageFile?.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryListProvider).categories;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.p24),
        children: [
          Center(
            child: GestureDetector(
              onTap: _showImagePickerOptions,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.border),
                      image: _imageFile != null 
                          ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                          : (widget.initialProduct?.image != null 
                              ? DecorationImage(image: NetworkImage(widget.initialProduct!.image!), fit: BoxFit.cover)
                              : null),
                    ),
                    child: _imageFile == null && widget.initialProduct?.image == null
                        ? const Icon(Icons.add_a_photo_outlined, size: 40, color: AppColors.textDisabled)
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.p8),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit, size: 16, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.p24),
          
          AppTextField(
            label: 'Product Name *',
            controller: _nameController,
            validator: (value) => value == null || value.isEmpty ? 'Name is required' : null,
          ),
          const SizedBox(height: AppSpacing.p16),
          
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Price *',
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) => value == null || double.tryParse(value) == null ? 'Valid price required' : null,
                ),
              ),
              const SizedBox(width: AppSpacing.p16),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        decoration: InputDecoration(
                          labelText: 'Category *',
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                        ),
                        value: _selectedCategoryId,
                        items: categories.map((cat) => DropdownMenuItem(
                          value: cat.id,
                          child: Text(cat.name, style: AppTextStyles.bodyMedium),
                        )).toList(),
                        onChanged: (val) => setState(() => _selectedCategoryId = val),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: AppColors.primary),
                      onPressed: () => context.push('/categories/add'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.p16),
          
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Tax %',
                  controller: _taxController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: AppSpacing.p16),
              Expanded(
                child: AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16, vertical: 4),
                  child: SwitchListTile(
                    title: const Text('Active', style: AppTextStyles.bodyMedium),
                    value: _isActive,
                    onChanged: (val) => setState(() => _isActive = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.p24),
          
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Product Type'),
                  value: _productType,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'NORMAL', child: Text('Normal Product')),
                    DropdownMenuItem(value: 'FOOD', child: Text('Food Item')),
                  ],
                  onChanged: (val) => setState(() => _productType = val!),
                ),
              ),
              const SizedBox(width: AppSpacing.p16),
              Expanded(
                child: SwitchListTile(
                  title: const Text('Track Stock'),
                  value: _trackStock,
                  onChanged: (val) => setState(() => _trackStock = val),
                ),
              ),
            ],
          ),
          if (_trackStock) ...[
            const SizedBox(height: AppSpacing.p16),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: widget.initialProduct == null ? 'Opening Stock' : 'Current Stock',
                    controller: _stockController,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: AppSpacing.p16),
                Expanded(
                  child: AppTextField(
                    label: 'Min Stock',
                    controller: _minStockController,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: AppSpacing.p16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Unit'),
                    value: _unit,
                    items: const [
                      'Piece', 'Kg', 'Gram', 'Liter', 'ML', 'Plate', 'Packet', 'Box', 'Bottle'
                    ].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                    onChanged: (val) => setState(() => _unit = val!),
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: AppSpacing.p24),
          
          ExpansionTile(
            title: const Text('Advanced', style: AppTextStyles.h3),
            tilePadding: EdgeInsets.zero,
            onExpansionChanged: (val) => setState(() => _isAdvancedExpanded = val),
            children: [
              const SizedBox(height: AppSpacing.p16),
              TextFormField(
                controller: _barcodeController,
                style: AppTextStyles.bodyLarge,
                decoration: InputDecoration(
                  labelText: 'Barcode (Optional)', 
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: () async {
                      final scannedCode = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BarcodeScannerScreen(),
                        ),
                      );
                      if (scannedCode != null && scannedCode is String) {
                        setState(() {
                          _barcodeController.text = scannedCode;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.p16),
              AppTextField(
                label: 'Description',
                controller: _descriptionController,
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.p32),
          
          if (widget.isLoading)
            const Center(child: CircularProgressIndicator())
          else
            PrimaryButton(
              isLarge: true,
              label: widget.initialProduct == null ? 'Create Product' : 'Update Product',
              onPressed: _submit,
            ),
        ],
      ),
    );
  }
}
