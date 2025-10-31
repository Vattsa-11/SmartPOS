import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/inventory.dart';
import '../models/product.dart';
import '../providers/inventory_provider.dart';
import '../utils/routes.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InventoryProvider>(context, listen: false).fetchInventory();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showUpdateStockDialog(BuildContext context, Inventory item) {
    final _quantityController = TextEditingController(text: item.quantity.toString());
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
                      _quantityController.text = (item.quantity + _change).toString();
                    });
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _quantityController,
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
                      _quantityController.text = (item.quantity + _change).toString();
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
                final newQuantity = int.parse(_quantityController.text);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<InventoryProvider>(context, listen: false).fetchInventory();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
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
                    hintText: 'Search by name, barcode, or category',
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
                    child: Text('No inventory items found'),
                  );
                }
                
                return ListView.builder(
                  itemCount: filteredInventory.length,
                  itemBuilder: (context, index) {
                    final item = filteredInventory[index];
                    final product = item.product is Map<String, dynamic> 
                        ? Product.fromJson(item.product) 
                        : item.product;
                    
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
                            Text('Category: ${product.category}'),
                            Text('Price: ₹${product.price.toStringAsFixed(2)}'),
                            Text(
                              'Quantity: ${item.quantity} ${isLowStock ? "(Low Stock)" : ""}',
                              style: TextStyle(
                                color: isLowStock ? Colors.red : null,
                                fontWeight: isLowStock ? FontWeight.bold : null,
                              ),
                            ),
                            Text('Reorder Level: ${item.reorderLevel}'),
                            if (item.expiryDate != null)
                              Text(
                                'Expires on: ${item.expiryDate!.toString().split(' ')[0]}',
                                style: TextStyle(
                                  color: item.expiryDate!.difference(DateTime.now()).inDays < 30
                                      ? Colors.orange
                                      : null,
                                ),
                              ),
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: () => _showUpdateStockDialog(context, item),
                          child: const Text('Update Stock'),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.addProduct);
        },
        child: const Icon(Icons.add),
        tooltip: 'Manage Products',
      ),
    );
  }
}
