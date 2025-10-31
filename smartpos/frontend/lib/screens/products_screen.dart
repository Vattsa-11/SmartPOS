import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/products_provider.dart';
import '../providers/auth_provider.dart';
import '../models/product.dart';
import '../theme/app_colors.dart';
import '../utils/validators.dart';
import '../utils/formatters.dart';
import '../utils/helpers.dart';
import '../widgets/barcode_scanner_modal.dart';
import '../config/api_config.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Load products
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductsProvider>(context, listen: false).fetchProducts();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditDialog({Product? product}) {
    showDialog(
      context: context,
      builder: (context) => _AddEditProductDialog(product: product),
    );
  }

  void _deleteProduct(Product product) async {
    final confirmed = await Helpers.showConfirmDialog(
      context,
      title: 'Delete Product',
      message: 'Are you sure you want to delete "${product.name}"?',
      confirmText: 'Delete',
    );

    if (confirmed && mounted) {
      final provider = Provider.of<ProductsProvider>(context, listen: false);
      final success = await provider.deleteProduct(product.id!);
      
      if (mounted) {
        Helpers.showSnackBar(
          context,
          success ? 'Product deleted successfully' : provider.error ?? 'Failed to delete product',
          isError: !success,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'All Products'),
            Tab(icon: Icon(Icons.add_box), text: 'Add Product'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProductsList(),
          _buildAddProductForm(),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    return Consumer<ProductsProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search products by name or barcode...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            provider.clearSearch();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) => provider.setSearchQuery(value),
              ),
            ),

            // Stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildStatChip(
                    'Total: ${provider.totalProducts}',
                    AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    'Low Stock: ${provider.lowStockCount}',
                    AppColors.warning,
                  ),
                ],
              ),
            ),

            // Products list
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Error: ${provider.error}'),
                              ElevatedButton(
                                onPressed: () => provider.fetchProducts(),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : provider.products.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inventory_2_outlined,
                                      size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No products found',
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: () => _tabController.animateTo(1),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add First Product'),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: provider.products.length,
                              itemBuilder: (context, index) {
                                final product = provider.products[index];
                                return _buildProductCard(product);
                              },
                            ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatChip(String label, Color color) {
    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
    );
  }

  Widget _buildProductCard(Product product) {
    final isLowStock = (product.stock ?? 0) <= (product.minimumStock ?? 0);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isLowStock ? AppColors.error : AppColors.primary,
          child: Text(
            product.name[0].toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.barcode != null)
              Text('Barcode: ${product.barcode}'),
            Text('Price: ${Formatters.formatCurrency(product.sellingPrice)}'),
            Text(
              'Stock: ${product.stock ?? 0} ${product.unit ?? ''}',
              style: TextStyle(
                color: isLowStock ? AppColors.error : AppColors.success,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              _showAddEditDialog(product: product);
            } else if (value == 'delete') {
              _deleteProduct(product);
            }
          },
        ),
      ),
    );
  }

  Widget _buildAddProductForm() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 4,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(24),
            child: _AddEditProductDialog(
              embedded: true,
              onSuccess: () {
                _tabController.animateTo(0);
                Provider.of<ProductsProvider>(context, listen: false).fetchProducts();
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _AddEditProductDialog extends StatefulWidget {
  final Product? product;
  final bool embedded;
  final VoidCallback? onSuccess;

  const _AddEditProductDialog({
    this.product,
    this.embedded = false,
    this.onSuccess,
  });

  @override
  State<_AddEditProductDialog> createState() => _AddEditProductDialogState();
}

class _AddEditProductDialogState extends State<_AddEditProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _barcodeController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _stockController;
  late TextEditingController _minimumStockController;
  String _selectedUnit = 'piece';

  final List<Map<String, String>> _units = [
    {'value': 'piece', 'label': 'Piece (counted items)'},
    {'value': 'kg', 'label': 'Kilogram (weight-based)'},
    {'value': 'gram', 'label': 'Gram (weight-based)'},
    {'value': 'liter', 'label': 'Liter (liquid)'},
    {'value': 'ml', 'label': 'Milliliter (liquid)'},
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _barcodeController = TextEditingController(text: p?.barcode ?? '');
    _sellingPriceController = TextEditingController(
      text: p?.sellingPrice.toString() ?? '',
    );
    _stockController = TextEditingController(
      text: p?.stock?.toString() ?? '0',
    );
    _minimumStockController = TextEditingController(
      text: p?.minimumStock?.toString() ?? '5',
    );
    _selectedUnit = p?.unit ?? 'piece';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _sellingPriceController.dispose();
    _stockController.dispose();
    _minimumStockController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<ProductsProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Check if user is logged in
    if (authProvider.user == null || authProvider.user!.id == null) {
      Helpers.showSnackBar(context, 'Please login to add products', isError: true);
      return;
    }
    
    final product = Product(
      id: widget.product?.id,
      name: _nameController.text.trim(),
      barcode: _barcodeController.text.trim().isNotEmpty
          ? _barcodeController.text.trim()
          : null,
      sellingPrice: double.parse(_sellingPriceController.text),
      unit: _selectedUnit,
      stock: int.parse(_stockController.text),
      minimumStock: int.parse(_minimumStockController.text),
      userId: int.tryParse(authProvider.user!.id!),
    );

    bool success;
    if (widget.product == null) {
      success = await provider.createProduct(product);
    } else {
      success = await provider.updateProduct(widget.product!.id!, product);
    }

    if (mounted) {
      if (success) {
        Helpers.showSnackBar(
          context,
          widget.product == null
              ? 'Product added successfully'
              : 'Product updated successfully',
        );
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        } else {
          Navigator.of(context).pop();
        }
      } else {
        Helpers.showSnackBar(
          context,
          provider.error ?? 'Failed to save product',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.embedded)
            Text(
              widget.product == null ? 'Add Product' : 'Edit Product',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
          if (!widget.embedded) const SizedBox(height: 24),

          // Name
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Product Name *',
              prefixIcon: Icon(Icons.inventory),
            ),
            validator: (v) => Validators.validateRequired(v, 'Product name'),
          ),
          const SizedBox(height: 16),

          // Barcode
          TextFormField(
            controller: _barcodeController,
            decoration: InputDecoration(
              labelText: 'Barcode (Optional)',
              prefixIcon: const Icon(Icons.qr_code),
              hintText: 'Enter barcode if available',
              suffixIcon: IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                onPressed: () async {
                  showDialog(
                    context: context,
                    builder: (context) => BarcodeScannerModal(
                      onBarcodeScanned: (barcode) {
                        setState(() {
                          _barcodeController.text = barcode;
                        });
                      },
                    ),
                  );
                },
                tooltip: 'Scan Barcode',
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Price
          TextFormField(
            controller: _sellingPriceController,
            decoration: const InputDecoration(
              labelText: 'Price *',
              prefixIcon: Icon(Icons.currency_rupee),
              hintText: '0.00',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) => Validators.validateNumber(v, min: 0),
          ),
          const SizedBox(height: 16),

          // Unit Type
          DropdownButtonFormField<String>(
            value: _selectedUnit,
            decoration: const InputDecoration(
              labelText: 'Unit Type *',
              prefixIcon: Icon(Icons.straighten),
              helperText: 'For fruits/vegetables, use Kilogram',
            ),
            items: _units.map((unit) {
              return DropdownMenuItem(
                value: unit['value'],
                child: Text(unit['label']!),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedUnit = value!;
              });
            },
          ),
          const SizedBox(height: 16),

          // Stock
          TextFormField(
            controller: _stockController,
            decoration: const InputDecoration(
              labelText: 'Stock *',
              prefixIcon: Icon(Icons.inventory_2),
            ),
            keyboardType: TextInputType.number,
            validator: (v) => Validators.validateNumber(v, min: 0),
          ),
          const SizedBox(height: 16),

          // Reorder Level
          TextFormField(
            controller: _minimumStockController,
            decoration: const InputDecoration(
              labelText: 'Reorder Level *',
              prefixIcon: Icon(Icons.warning_amber),
            ),
            keyboardType: TextInputType.number,
            validator: (v) => Validators.validateNumber(v, min: 0),
          ),
          const SizedBox(height: 24),

          // Buttons
          Consumer<ProductsProvider>(
            builder: (context, provider, _) {
              return ElevatedButton(
                onPressed: provider.isLoading ? null : _saveProduct,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: provider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.product == null ? 'Add Product' : 'Update Product'),
              );
            },
          ),
          if (!widget.embedded) const SizedBox(height: 8),
          if (!widget.embedded)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
        ],
      ),
    );

    if (widget.embedded) {
      return content;
    }

    return Dialog(
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(24),
          child: content,
        ),
      ),
    );
  }
}
