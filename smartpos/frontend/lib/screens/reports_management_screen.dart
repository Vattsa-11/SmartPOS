import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/sale.dart';
import '../models/product.dart';
import '../models/customer.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';

class ReportsManagementScreen extends StatefulWidget {
  const ReportsManagementScreen({super.key});

  @override
  State<ReportsManagementScreen> createState() => _ReportsManagementScreenState();
}

class _ReportsManagementScreenState extends State<ReportsManagementScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  
  bool _isLoading = false;
  String? _error;
  
  // Sales data
  List<Sale> _sales = [];
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();
  
  // Inventory data
  List<Product> _inventory = [];
  
  // Customer data
  List<Customer> _customers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _apiService.getSales(),
        _apiService.getInventory(),
        _apiService.getCustomers(),
      ]);

      setState(() {
        _sales = (results[0] as List<Sale>?) ?? [];
        _inventory = (results[1] as List<Product>?) ?? [];
        _customers = (results[2] as List<Customer>?) ?? [];
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading reports data: $e');
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _sales = [];
        _inventory = [];
        _customers = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Sales', icon: Icon(Icons.monetization_on)),
            Tab(text: 'Inventory', icon: Icon(Icons.inventory_2)),
            Tab(text: 'Customers', icon: Icon(Icons.people)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSalesTab(),
                    _buildInventoryTab(),
                    _buildCustomersTab(),
                  ],
                ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'Error loading reports',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _error ?? 'Unknown error',
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadAllData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ==================== SALES TAB ====================

  Widget _buildSalesTab() {
    final filteredSales = _sales.where((sale) {
      final saleDate = sale.saleDate;
      return saleDate.isAfter(_fromDate.subtract(const Duration(days: 1))) &&
             saleDate.isBefore(_toDate.add(const Duration(days: 1)));
    }).toList();

    final totalSales = filteredSales.fold<double>(
      0.0,
      (sum, sale) => sum + sale.totalAmount,
    );

    final totalTransactions = filteredSales.length;

    final totalItems = filteredSales.fold<int>(
      0,
      (sum, sale) => sum + sale.items.fold<int>(0, (s, item) {
        try {
          if (item.quantity == null) return s;
          if (item.quantity is int) return s + (item.quantity as int);
          return s + (item.quantity as double).round();
        } catch (e) {
          return s;
        }
      }),
    );

    final avgSaleValue = totalTransactions > 0 ? totalSales / totalTransactions : 0.0;

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Filter
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Date Range',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateField(
                            label: 'From',
                            date: _fromDate,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _fromDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() {
                                  _fromDate = picked;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDateField(
                            label: 'To',
                            date: _toDate,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _toDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() {
                                  _toDate = picked;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _fromDate = DateTime.now().subtract(const Duration(days: 7));
                                _toDate = DateTime.now();
                              });
                            },
                            child: const Text('Last 7 Days'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _fromDate = DateTime.now().subtract(const Duration(days: 30));
                                _toDate = DateTime.now();
                              });
                            },
                            child: const Text('Last 30 Days'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Sales',
                    Formatters.formatCurrency(totalSales),
                    Icons.monetization_on,
                    AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Transactions',
                    totalTransactions.toString(),
                    Icons.receipt,
                    AppColors.primary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Items Sold',
                    totalItems.toString(),
                    Icons.shopping_cart,
                    AppColors.info,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Avg. Sale',
                    Formatters.formatCurrency(avgSaleValue),
                    Icons.trending_up,
                    AppColors.warning,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Sales List
            Text(
              'Recent Transactions',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            if (filteredSales.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long, size: 64, color: AppColors.textSecondary),
                      const SizedBox(height: 16),
                      const Text(
                        'No sales in selected period',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...filteredSales.take(20).map((sale) => _buildSaleCard(sale)),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          Formatters.formatDate(date),
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildSaleCard(Sale sale) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.success,
          child: const Icon(Icons.receipt, color: Colors.white),
        ),
        title: Text(
          'Invoice: ${sale.invoiceNumber}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${sale.items.length} items • ${sale.paymentMethod}'),
            Text(
              Formatters.formatDateTime(sale.saleDate),
              style: const TextStyle(fontSize: 12),
            ),
            if (sale.customerName != null)
              Text(
                'Customer: ${sale.customerName}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        trailing: Text(
          Formatters.formatCurrency(sale.totalAmount),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.success,
          ),
        ),
        onTap: () => _showSaleDetails(sale),
      ),
    );
  }

  void _showSaleDetails(Sale sale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Invoice: ${sale.invoiceNumber}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Date: ${Formatters.formatDateTime(sale.saleDate)}'),
              if (sale.customerName != null)
                Text('Customer: ${sale.customerName}'),
              Text('Payment: ${sale.paymentMethod}'),
              const Divider(height: 24),
              const Text(
                'Items:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...sale.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('${item.productName} x${(item.quantity ?? 0).round()}'),
                    ),
                    Text(Formatters.formatCurrency(item.total)),
                  ],
                ),
              )),
              const Divider(height: 24),
              if (sale.discountAmount > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Discount:'),
                    Text(
                      '- ${Formatters.formatCurrency(sale.discountAmount)}',
                      style: const TextStyle(color: AppColors.success),
                    ),
                  ],
                ),
              if (sale.taxAmount > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tax:'),
                    Text(Formatters.formatCurrency(sale.taxAmount)),
                  ],
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    Formatters.formatCurrency(sale.totalAmount),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ==================== INVENTORY TAB ====================

  Widget _buildInventoryTab() {
    final lowStockProducts = _inventory.where((p) {
      final stock = p.stock ?? 0;
      final minStock = p.minimumStock ?? 0;
      return stock <= minStock;
    }).toList();

    final outOfStockProducts = _inventory.where((p) => (p.stock ?? 0) == 0).toList();

    final totalValue = _inventory.fold<double>(
      0.0,
      (sum, p) => sum + ((p.stock ?? 0) * (p.costPrice ?? p.sellingPrice)),
    );

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Items',
                    _inventory.length.toString(),
                    Icons.inventory_2,
                    AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Low Stock',
                    lowStockProducts.length.toString(),
                    Icons.warning_amber,
                    AppColors.warning,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Out of Stock',
                    outOfStockProducts.length.toString(),
                    Icons.remove_shopping_cart,
                    AppColors.error,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Total Value',
                    Formatters.formatCurrency(totalValue),
                    Icons.account_balance_wallet,
                    AppColors.success,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Low Stock Products
            if (lowStockProducts.isNotEmpty) ...[
              Text(
                'Low Stock Alert (${lowStockProducts.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(height: 12),
              ...lowStockProducts.take(10).map((product) => _buildInventoryCard(product, isLowStock: true)),
              const SizedBox(height: 24),
            ],
            
            // Out of Stock Products
            if (outOfStockProducts.isNotEmpty) ...[
              Text(
                'Out of Stock (${outOfStockProducts.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 12),
              ...outOfStockProducts.take(10).map((product) => _buildInventoryCard(product, isOutOfStock: true)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryCard(Product product, {bool isLowStock = false, bool isOutOfStock = false}) {
    final stock = product.stock ?? 0;
    final minStock = product.minimumStock ?? 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isOutOfStock ? AppColors.error.withOpacity(0.1) : (isLowStock ? AppColors.warning.withOpacity(0.1) : null),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isOutOfStock ? AppColors.error : (isLowStock ? AppColors.warning : AppColors.primary),
          child: Icon(
            isOutOfStock ? Icons.not_interested : Icons.inventory_2,
            color: Colors.white,
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Stock: $stock ${product.unit ?? "pcs"} • Min: $minStock'),
            Text('Price: ${Formatters.formatCurrency(product.sellingPrice)}'),
          ],
        ),
        trailing: Icon(
          isOutOfStock ? Icons.error : (isLowStock ? Icons.warning : Icons.check_circle),
          color: isOutOfStock ? AppColors.error : (isLowStock ? AppColors.warning : AppColors.success),
        ),
      ),
    );
  }

  // ==================== CUSTOMERS TAB ====================

  Widget _buildCustomersTab() {
    final totalCustomers = _customers.length;

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Card
            _buildStatCard(
              'Total Customers',
              totalCustomers.toString(),
              Icons.people,
              AppColors.primary,
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'Customer List',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            if (_customers.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.people_outline, size: 64, color: AppColors.textSecondary),
                      const SizedBox(height: 16),
                      const Text(
                        'No customers yet',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._customers.map((customer) => _buildCustomerCard(customer)),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard(Customer customer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary,
          child: Text(
            customer.name[0].toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          customer.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('📱 ${customer.phone}'),
      ),
    );
  }

  // ==================== SHARED WIDGETS ====================

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
