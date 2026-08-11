import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../../../categories/presentation/controllers/category_list_controller.dart';
import '../controllers/product_list_controller.dart';
import '../../domain/entities/product.dart';
import '../../../../core/providers.dart';
import '../../../../core/widgets/barcode_scanner_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialProduct?.name ?? '');
    _priceController = TextEditingController(text: widget.initialProduct?.price.toString() ?? '');
    _taxController = TextEditingController(text: widget.initialProduct?.taxPercentage.toString() ?? '0.0');
    _barcodeController = TextEditingController(text: widget.initialProduct?.barcode ?? '');
    _descriptionController = TextEditingController(text: widget.initialProduct?.description ?? '');
    _stockController = TextEditingController(text: widget.initialProduct?.stock.toString() ?? '0');
    _selectedCategoryId = widget.initialProduct?.categoryId;
    _isActive = widget.initialProduct?.status ?? true;
    
    // Fetch categories for the dropdown if not already loaded
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
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final product = Product(
        id: widget.initialProduct?.id,
        name: _nameController.text.trim(),
        categoryId: _selectedCategoryId,
        price: double.parse(_priceController.text.trim()),
        taxPercentage: double.parse(_taxController.text.trim()),
        barcode: _barcodeController.text.trim(),
        description: _descriptionController.text.trim(),
        stock: int.parse(_stockController.text.trim()),
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
        padding: const EdgeInsets.all(16.0),
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  image: _imageFile != null 
                      ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                      : (widget.initialProduct?.image != null 
                          ? DecorationImage(image: NetworkImage(widget.initialProduct!.image!), fit: BoxFit.cover)
                          : null),
                ),
                child: _imageFile == null && widget.initialProduct?.image == null
                    ? const Icon(Icons.camera_alt, size: 50, color: Colors.grey)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(child: Text("Tap to select image", style: TextStyle(color: Colors.grey))),
          const SizedBox(height: 24),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Product Name *', border: OutlineInputBorder()),
            validator: (value) => value == null || value.isEmpty ? 'Name is required' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
            value: _selectedCategoryId,
            items: categories.map((cat) => DropdownMenuItem(
              value: cat.id,
              child: Text(cat.name),
            )).toList(),
            onChanged: (val) => setState(() => _selectedCategoryId = val),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'Price *', border: OutlineInputBorder()),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) => value == null || double.tryParse(value) == null ? 'Valid price required' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _taxController,
                  decoration: const InputDecoration(labelText: 'Tax %', border: OutlineInputBorder()),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) => value != null && value.isNotEmpty && double.tryParse(value) == null ? 'Invalid tax' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _stockController,
                  decoration: const InputDecoration(labelText: 'Stock', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (value) => value != null && value.isNotEmpty && int.tryParse(value) == null ? 'Invalid stock' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SwitchListTile(
                  title: const Text('Active'),
                  value: _isActive,
                  onChanged: (val) => setState(() => _isActive = val),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _barcodeController,
            decoration: InputDecoration(
              labelText: 'Barcode (Optional)', 
              border: const OutlineInputBorder(), 
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
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
            maxLines: 3,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: widget.isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
            child: widget.isLoading 
                ? const CircularProgressIndicator()
                : Text(widget.initialProduct == null ? 'Create Product' : 'Update Product'),
          ),
        ],
      ),
    );
  }
}
