import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../models/product.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../utils/helpers.dart';
import 'add_edit_product_screen.dart';

class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  State<InventoryManagementScreen> createState() => _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InventoryProvider>(context, listen: false).fetchInventory();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Inventory Management'),
        backgroundColor: AppColors.bgSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<InventoryProvider>(context, listen: false).fetchInventory();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // Search Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by name, barcode, or SKU...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white54),
                            onPressed: () {
                              _searchController.clear();
                              Provider.of<InventoryProvider>(context, listen: false).setSearchQuery('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.bgDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    Provider.of<InventoryProvider>(context, listen: false).setSearchQuery(value);
                  },
                ),
              ),
              // Tabs
              Container(
                color: AppColors.bgSurface,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.white60,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.inventory_2),
                      text: 'All Items',
                    ),
                    Tab(
                      icon: Icon(Icons.warning_amber),
                      text: 'Low Stock',
                    ),
                    Tab(
                      icon: Icon(Icons.cancel),
                      text: 'Out of Stock',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Provider.of<InventoryProvider>(context, listen: false).fetchInventory();
        },
        child: Consumer<InventoryProvider>(
          builder: (context, provider, child) {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildInventoryList(provider, 'all'),
                _buildInventoryList(provider, 'low'),
                _buildInventoryList(provider, 'out'),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildInventoryList(InventoryProvider provider, String filter) {
    if (provider.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error: ${provider.error}',
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => provider.fetchInventory(),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Filter products based on tab
    List<Product> filteredProducts;
    switch (filter) {
      case 'low':
        filteredProducts = provider.filteredInventory
            .where((p) => (p.stock ?? 0) > 0 && (p.stock ?? 0) <= (p.minimumStock ?? 0))
            .toList();
        break;
      case 'out':
        filteredProducts = provider.filteredInventory
            .where((p) => (p.stock ?? 0) == 0)
            .toList();
        break;
      default:
        filteredProducts = provider.filteredInventory;
    }

    if (filteredProducts.isEmpty) {
      String message;
      IconData icon;
      switch (filter) {
        case 'low':
          message = 'No low stock items';
          icon = Icons.check_circle_outline;
          break;
        case 'out':
          message = 'No out of stock items';
          icon = Icons.check_circle_outline;
          break;
        default:
          message = provider.searchQuery.isNotEmpty
              ? 'No items found'
              : 'No inventory items';
          icon = provider.searchQuery.isNotEmpty
              ? Icons.search_off
              : Icons.inventory_2_outlined;
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white54,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        return _buildInventoryCard(product, provider);
      },
    );
  }

  Widget _buildInventoryCard(Product product, InventoryProvider provider) {
    final stock = product.stock ?? 0;
    final minStock = product.minimumStock ?? 0;
    final isOutOfStock = stock == 0;
    final isLowStock = stock > 0 && stock <= minStock;
    
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    if (isOutOfStock) {
      statusColor = Colors.red;
      statusText = 'OUT OF STOCK';
      statusIcon = Icons.cancel;
    } else if (isLowStock) {
      statusColor = AppColors.warning;
      statusText = 'LOW STOCK';
      statusIcon = Icons.warning_amber;
    } else {
      statusColor = AppColors.success;
      statusText = 'IN STOCK';
      statusIcon = Icons.check_circle;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.bgSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isOutOfStock || isLowStock
            ? BorderSide(color: statusColor, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                // Product Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (product.barcode != null) ...[
                            const Icon(Icons.qr_code, size: 14, color: Colors.white54),
                            const SizedBox(width: 4),
                            Text(
                              product.barcode!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                          if (product.sku != null) ...[
                            if (product.barcode != null)
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text('•', style: TextStyle(color: Colors.white54)),
                              ),
                            Text(
                              'SKU: ${product.sku}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Stock Info Row
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Current Stock',
                    stock.toString(),
                    Icons.inventory,
                    statusColor,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Min Stock',
                    minStock.toString(),
                    Icons.low_priority,
                    AppColors.info,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Price',
                    Formatters.formatCurrency(product.sellingPrice),
                    Icons.attach_money,
                    AppColors.success,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editProduct(product),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.info,
                      side: BorderSide(color: AppColors.info),
                    ),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit Product'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showStockEditDialog(product, provider),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                    ),
                    icon: const Icon(Icons.inventory, size: 18),
                    label: const Text('Adjust Stock'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  void _editProduct(Product product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditProductScreen(
          product: product,
          isEditing: true,
        ),
      ),
    );
    
    if (result == true) {
      // Refresh inventory after edit
      Provider.of<InventoryProvider>(context, listen: false).fetchInventory();
    }
  }

  void _showStockEditDialog(Product product, InventoryProvider provider) {
    final TextEditingController stockController = TextEditingController(
      text: (product.stock ?? 0).toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Stock - ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Stock: ${product.stock ?? 0} ${product.unit ?? 'pcs'}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: stockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'New Stock Quantity',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory_2),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newStock = int.tryParse(stockController.text);
              if (newStock == null) {
                Helpers.showSnackBar(context, 'Please enter a valid number', isError: true);
                return;
              }

              if (newStock < 0) {
                Helpers.showSnackBar(context, 'Stock cannot be negative', isError: true);
                return;
              }

              Navigator.pop(context);

              final success = await provider.updateStock(product.id!, newStock);
              if (success && mounted) {
                Helpers.showSnackBar(context, 'Stock updated successfully');
              } else if (mounted) {
                Helpers.showSnackBar(context, provider.error ?? 'Failed to update stock', isError: true);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showStockAdjustmentDialog(Product product, InventoryProvider provider, {required bool isAdd}) {
    final TextEditingController quantityController = TextEditingController();
    
    // Check if product is weight-based
    final unit = product.unit?.toLowerCase() ?? 'pcs';
    final isWeightBased = unit == 'kg' || unit == 'g' || unit == 'ltr' || unit == 'ml';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${isAdd ? 'Add' : 'Remove'} Stock - ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Stock: ${product.stock ?? 0} ${product.unit ?? 'pcs'}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Quantity to ${isAdd ? 'Add' : 'Remove'}',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(isAdd ? Icons.add : Icons.remove),
                hintText: isWeightBased ? 'e.g., 2.5' : 'e.g., 10',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final quantity = double.tryParse(quantityController.text);
              if (quantity == null || quantity <= 0) {
                Helpers.showSnackBar(context, 'Please enter a valid quantity', isError: true);
                return;
              }

              final adjustment = isAdd ? quantity.toInt() : -quantity.toInt();
              final currentStock = product.stock ?? 0;
              final newStock = currentStock + adjustment;

              if (newStock < 0) {
                Helpers.showSnackBar(context, 'Not enough stock to remove', isError: true);
                return;
              }

              Navigator.pop(context);

              final success = await provider.adjustStock(product.id!, adjustment);
              if (success && mounted) {
                Helpers.showSnackBar(
                  context,
                  'Stock ${isAdd ? 'added' : 'removed'} successfully',
                );
              } else if (mounted) {
                Helpers.showSnackBar(context, provider.error ?? 'Failed to adjust stock', isError: true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isAdd ? AppColors.success : AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(isAdd ? 'Add' : 'Remove'),
          ),
        ],
      ),
    );
  }
}