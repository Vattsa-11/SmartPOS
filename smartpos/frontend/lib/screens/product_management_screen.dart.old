import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/inventory.dart';
import '../models/product.dart';
import '../providers/inventory_provider.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({Key? key}) : super(key: key);

  @override
  _ProductManagementScreenState createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  String _selectedFilter = 'All';
  late TabController _tabController;

  // Form controllers for add product
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _reorderLevelController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Edit mode
  Product? _editingProduct;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InventoryProvider>(context, listen: false).fetchInventory();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _nameController.dispose();
    _barcodeController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _reorderLevelController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _nameController.clear();
    _barcodeController.clear();
    _priceController.clear();
    _quantityController.clear();
    _reorderLevelController.clear();
    setState(() {
      _editingProduct = null;
      _isEditing = false;
    });
  }

  void _loadProductForEdit(Product product) {
    _nameController.text = product.name;
    _barcodeController.text = product.barcode;
    _priceController.text = product.price.toString();
    
    // Get quantity from inventory if available
    final inventory = Provider.of<InventoryProvider>(context, listen: false)
        .inventoryItems
        .where((inv) => inv.productId == product.id)
        .firstOrNull;
    
    if (inventory != null) {
      _quantityController.text = inventory.quantity.toString();
      _reorderLevelController.text = inventory.reorderLevel.toString();
    } else {
      _quantityController.text = '0';
      _reorderLevelController.text = '10';
    }
    
    setState(() {
      _editingProduct = product;
      _isEditing = true;
      _tabController.index = 0; // Switch to add/edit tab
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = Provider.of<InventoryProvider>(context, listen: false);
    
    try {
      final product = Product(
        id: _editingProduct?.id,
        name: _nameController.text.trim(),
        barcode: _barcodeController.text.trim().isNotEmpty ? _barcodeController.text.trim() : 'BARCODE-${DateTime.now().millisecondsSinceEpoch}',
        price: double.parse(_priceController.text),
        category: 'General', // Default category since we removed category selection
      );

      final quantity = int.parse(_quantityController.text);
      final reorderLevel = int.parse(_reorderLevelController.text);

      if (_isEditing && _editingProduct != null) {
        await provider.updateProduct(
          _editingProduct!.id!,
          product,
          quantity,
          reorderLevel,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully')),
        );
      } else {
        await provider.addProduct(
          product,
          quantity,
          reorderLevel,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product added successfully')),
        );
      }

      _clearForm();
      _tabController.index = 1; // Switch to list tab
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _showUpdateStockDialog(BuildContext context, Inventory item) {
    final _stockQuantityController = TextEditingController(text: item.quantity.toString());
    int _change = 0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update Stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Quantity: ${item.quantity}'),
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle),
                  onPressed: () {
                    setState(() {
                      _change -= 1;
                      _stockQuantityController.text = (item.quantity + _change).toString();
                    });
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _stockQuantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'New Quantity',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        try {
                          final newQty = int.parse(value);
                          _change = newQty - item.quantity;
                        } catch (_) {}
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  onPressed: () {
                    setState(() {
                      _change += 1;
                      _stockQuantityController.text = (item.quantity + _change).toString();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Change: ${_change > 0 ? '+$_change' : _change}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _change > 0 ? Colors.green : (_change < 0 ? Colors.red : null),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              try {
                final newQuantity = int.parse(_stockQuantityController.text);
                if (newQuantity < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Quantity cannot be negative')),
                  );
                  return;
                }
                
                Provider.of<InventoryProvider>(context, listen: false)
                    .updateStock(item.productId, newQuantity);
                Navigator.of(ctx).pop();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Stock updated successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Invalid quantity: ${e.toString()}')),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddProductTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEditing ? 'Edit Product' : 'Add New Product',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              
              // Product Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.shopping_bag),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Product name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Barcode
              TextFormField(
                controller: _barcodeController,
                decoration: const InputDecoration(
                  labelText: 'Barcode',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.qr_code),
                ),
              ),
              const SizedBox(height: 16),
              
              // Price
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Price is required';
                  }
                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Quantity
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Initial Quantity *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Quantity is required';
                  }
                  if (int.tryParse(value) == null || int.parse(value) < 0) {
                    return 'Please enter a valid quantity';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Reorder Level
              TextFormField(
                controller: _reorderLevelController,
                decoration: const InputDecoration(
                  labelText: 'Reorder Level *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.warning),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Reorder level is required';
                  }
                  if (int.tryParse(value) == null || int.parse(value) < 0) {
                    return 'Please enter a valid reorder level';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Action Buttons
              Row(
                children: [
                  if (_isEditing) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _clearForm,
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveProduct,
                      child: Text(_isEditing ? 'Update Product' : 'Add Product'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductListTab() {
    return Column(
      children: [
        // Search and filter area
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // Search field
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name or barcode',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      Provider.of<InventoryProvider>(context, listen: false)
                          .setSearchQuery('');
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (value) {
                  Provider.of<InventoryProvider>(context, listen: false)
                      .setSearchQuery(value);
                },
              ),
              const SizedBox(height: 8),
              
              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _selectedFilter == 'All',
                      onSelected: (_) {
                        setState(() {
                          _selectedFilter = 'All';
                        });
                        Provider.of<InventoryProvider>(context, listen: false).resetFilters();
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Low Stock'),
                      selected: _selectedFilter == 'Low Stock',
                      onSelected: (_) {
                        setState(() {
                          _selectedFilter = 'Low Stock';
                        });
                        final provider = Provider.of<InventoryProvider>(context, listen: false);
                        provider.resetFilters();
                        provider.toggleLowStockFilter();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Inventory list
        Expanded(
          child: Consumer<InventoryProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (provider.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: ${provider.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => provider.fetchInventory(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              
              final filteredInventory = provider.filteredInventory;
              
              if (filteredInventory.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No products found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Add your first product using the form above',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }
              
              return ListView.builder(
                itemCount: filteredInventory.length,
                itemBuilder: (context, index) {
                  final item = filteredInventory[index];
                  final product = item.product is Map<String, dynamic> 
                      ? Product.fromJson(item.product) 
                      : item.product as Product;
                  
                  final isLowStock = item.isLowStock;
                  
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    color: isLowStock ? Colors.red.shade50 : null,
                    child: ListTile(
                      title: Text(
                        product.name,
                        style: TextStyle(
                          fontWeight: isLowStock ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Price: ₹${product.price.toStringAsFixed(2)}'),
                          Text(
                            'Quantity: ${item.quantity} ${isLowStock ? "(Low Stock)" : ""}',
                            style: TextStyle(
                              color: isLowStock ? Colors.red : null,
                              fontWeight: isLowStock ? FontWeight.bold : null,
                            ),
                          ),
                          Text('Reorder Level: ${item.reorderLevel}'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _loadProductForEdit(product),
                            icon: const Icon(Icons.edit),
                            tooltip: 'Edit Product',
                          ),
                          ElevatedButton(
                            onPressed: () => _showUpdateStockDialog(context, item),
                            child: const Text('Update Stock'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<InventoryProvider>(context, listen: false).fetchInventory();
            },
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.add), text: 'Add/Edit'),
            Tab(icon: Icon(Icons.list), text: 'Products'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAddProductTab(),
          _buildProductListTab(),
        ],
      ),
    );
  }
}
