import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/inventory_provider.dart';
import '../widgets/barcode_scanner_widget.dart';
import '../theme/app_colors.dart';

class AddEditProductScreen extends StatefulWidget {
  final Product? product;
  final bool isEditing;

  const AddEditProductScreen({
    Key? key,
    this.product,
    this.isEditing = false,
  }) : super(key: key);

  @override
  _AddEditProductScreenState createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _quantityController = TextEditingController();
  final _reorderLevelController = TextEditingController();

  bool _isLoading = false;
  String _selectedUnit = 'pcs';

  // Valid unit values that match dropdown
  static const List<String> validUnits = ['pcs', 'kg', 'g', 'ltr', 'ml', 'box', 'pack', 'dozen'];

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.product != null) {
      _nameController.text = widget.product!.name;
      _priceController.text = widget.product!.sellingPrice.toString();
      _barcodeController.text = widget.product!.barcode ?? '';
      
      // Normalize unit value to match dropdown exactly
      String productUnit = (widget.product!.unit ?? 'pcs').toLowerCase().trim();
      print('🔍 Product unit from DB: "${widget.product!.unit}" -> normalized: "$productUnit"');
      print('🔍 Valid units: $validUnits');
      print('🔍 Contains check: ${validUnits.contains(productUnit)}');
      _selectedUnit = validUnits.contains(productUnit) ? productUnit : 'pcs';
      print('🔍 Selected unit after init: "$_selectedUnit"');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _barcodeController.dispose();
    _quantityController.dispose();
    _reorderLevelController.dispose();
    super.dispose();
  }

  void _openBarcodeScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScannerWidget(
          onBarcodeDetected: (barcode) {
            setState(() {
              _barcodeController.text = barcode;
            });
          },
        ),
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final product = Product(
        id: widget.product?.id,
        name: _nameController.text.trim(),
        barcode: _barcodeController.text.trim(),
        sellingPrice: double.parse(_priceController.text.trim()),
        unit: _selectedUnit,
        userId: null, // Will be set by provider
        createdAt: widget.product?.createdAt ?? DateTime.now().toIso8601String(),
      );

      // Check if product is weight-based to allow decimal quantities
      final unit = _selectedUnit.toLowerCase();
      final isWeightBased = unit == 'kg' || unit == 'g' || unit == 'ltr' || unit == 'ml';
      
      // Parse quantities as double first
      final quantityDouble = double.parse(_quantityController.text.trim());
      final reorderLevelDouble = double.parse(_reorderLevelController.text.trim());
      
      // Convert to int for provider (backend handles decimal storage)
      final quantity = quantityDouble.toInt();
      final reorderLevel = reorderLevelDouble.toInt();

      final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);

      if (widget.isEditing && widget.product != null) {
        await inventoryProvider.updateProduct(
          widget.product!.id!,
          product,
          quantity,
          reorderLevel,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await inventoryProvider.addProduct(
          product,
          quantity,
          reorderLevel,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Product' : 'Add New Product'),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Product Information',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name *',
                        hintText: 'Enter product name',
                        prefixIcon: Icon(Icons.shopping_bag),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Product name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Barcode field with scan button
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _barcodeController,
                            decoration: const InputDecoration(
                              labelText: 'Barcode *',
                              hintText: 'Enter or scan barcode',
                              prefixIcon: Icon(Icons.qr_code),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Barcode is required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Scan Button (same color as billing and add product)
                        ElevatedButton.icon(
                          onPressed: _openBarcodeScanner,
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('Scan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            decoration: const InputDecoration(
                              labelText: 'Price *',
                              hintText: '0.00',
                              prefixIcon: Icon(Icons.currency_rupee),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Price is required';
                              }
                              if (double.tryParse(value.trim()) == null) {
                                return 'Invalid price';
                              }
                              if (double.parse(value.trim()) < 0) {
                                return 'Price cannot be negative';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedUnit,
                            decoration: const InputDecoration(
                              labelText: 'Unit Type *',
                              prefixIcon: Icon(Icons.category),
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'pcs', child: Text('Pieces (pcs)')),
                              DropdownMenuItem(value: 'kg', child: Text('Kilogram (kg)')),
                              DropdownMenuItem(value: 'g', child: Text('Gram (g)')),
                              DropdownMenuItem(value: 'ltr', child: Text('Litre (ltr)')),
                              DropdownMenuItem(value: 'ml', child: Text('Millilitre (ml)')),
                              DropdownMenuItem(value: 'box', child: Text('Box')),
                              DropdownMenuItem(value: 'pack', child: Text('Pack')),
                              DropdownMenuItem(value: 'dozen', child: Text('Dozen')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedUnit = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inventory Information',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _quantityController,
                            decoration: InputDecoration(
                              labelText: 'Initial Quantity *',
                              hintText: _selectedUnit == 'kg' || _selectedUnit == 'g' || _selectedUnit == 'ltr' || _selectedUnit == 'ml' ? 'e.g., 2.5' : '0',
                              prefixIcon: Icon(Icons.inventory),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Quantity is required';
                              }
                              if (double.tryParse(value.trim()) == null) {
                                return 'Invalid quantity';
                              }
                              if (double.parse(value.trim()) < 0) {
                                return 'Quantity cannot be negative';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _reorderLevelController,
                            decoration: InputDecoration(
                              labelText: 'Reorder Level *',
                              hintText: _selectedUnit == 'kg' || _selectedUnit == 'g' || _selectedUnit == 'ltr' || _selectedUnit == 'ml' ? 'e.g., 5.0' : '0',
                              prefixIcon: Icon(Icons.low_priority),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Reorder level is required';
                              }
                              if (double.tryParse(value.trim()) == null) {
                                return 'Invalid reorder level';
                              }
                              if (double.parse(value.trim()) < 0) {
                                return 'Reorder level cannot be negative';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProduct,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(widget.isEditing ? 'Update Product' : 'Add Product'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}