import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/transaction.dart';
import '../models/product.dart';
import '../models/inventory.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  
  // Sales Report Data
  List<Transaction> _salesData = [];
  double _totalSales = 0.0;
  int _totalTransactions = 0;
  bool _isLoadingSales = false;
  
  // Inventory Report Data
  List<Inventory> _inventoryData = [];
  List<Inventory> _lowStockItems = [];
  bool _isLoadingInventory = false;
  
  // Date filters
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    await Future.wait([
      _loadSalesReport(),
      _loadInventoryReport(),
    ]);
  }

  Future<void> _loadSalesReport() async {
    setState(() {
      _isLoadingSales = true;
    });

    try {
      // For now, we'll use mock data since the backend endpoints need to be called
      // In a real implementation, you would call:
      // final sales = await _apiService.getSalesReport(_startDate, _endDate);
      
      // Mock data for demonstration
      _salesData = [
        Transaction(
          id: 1,
          customerName: 'John Doe',
          items: [],
          subtotal: 150.00,
          discount: 10.00,
          totalAmount: 140.00,
          paymentType: PaymentType.cash,
          createdAt: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        ),
        Transaction(
          id: 2,
          customerName: 'Jane Smith',
          items: [],
          subtotal: 250.00,
          discount: 0.00,
          totalAmount: 250.00,
          paymentType: PaymentType.upi,
          createdAt: DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        ),
      ];
      
      _totalSales = _salesData.fold(0.0, (sum, transaction) => sum + transaction.totalAmount);
      _totalTransactions = _salesData.length;
      
    } catch (e) {
      print('Error loading sales report: $e');
    } finally {
      setState(() {
        _isLoadingSales = false;
      });
    }
  }

  Future<void> _loadInventoryReport() async {
    setState(() {
      _isLoadingInventory = true;
    });

    try {
      // For now, we'll use mock data
      // In a real implementation: final products = await _apiService.getProducts();
      
      _inventoryData = [
        Inventory(
          id: 1,
          productId: 1,
          quantity: 50,
          reorderLevel: 10,
          product: Product(
            id: 1,
            name: 'Coca Cola',
            barcode: '123456789',
            price: 25.00,
            category: 'Beverages',
          ),
        ),
        Inventory(
          id: 2,
          productId: 2,
          quantity: 5, // Low stock
          reorderLevel: 10,
          product: Product(
            id: 2,
            name: 'Bread',
            barcode: '987654321',
            price: 30.00,
            category: 'Grocery',
          ),
        ),
      ];
      
      _lowStockItems = _inventoryData
          .where((inventory) => inventory.isLowStock)
          .toList();
      
    } catch (e) {
      print('Error loading inventory report: $e');
    } finally {
      setState(() {
        _isLoadingInventory = false;
      });
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadSalesReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'Select Date Range',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
            tooltip: 'Refresh Reports',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Sales', icon: Icon(Icons.trending_up)),
            Tab(text: 'Inventory', icon: Icon(Icons.inventory)),
            Tab(text: 'Summary', icon: Icon(Icons.dashboard)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSalesReport(),
          _buildInventoryReport(),
          _buildSummaryReport(),
        ],
      ),
    );
  }

  Widget _buildSalesReport() {
    return RefreshIndicator(
      onRefresh: _loadSalesReport,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Range Display
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Period: ${DateFormat('MMM dd, yyyy').format(_startDate)} - ${DateFormat('MMM dd, yyyy').format(_endDate)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Sales Summary Cards
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.green[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(Icons.attach_money, 
                               color: Colors.green[700], size: 32),
                          const SizedBox(height: 8),
                          Text(
                            '₹${_totalSales.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text('Total Sales'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(Icons.receipt, 
                               color: Colors.blue[700], size: 32),
                          const SizedBox(height: 8),
                          Text(
                            '$_totalTransactions',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text('Transactions'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Recent Transactions
            Text(
              'Recent Transactions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            
            if (_isLoadingSales)
              const Center(child: CircularProgressIndicator())
            else if (_salesData.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(
                    child: Text('No sales data for selected period'),
                  ),
                ),
              )
            else
              ...(_salesData.map((transaction) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green[100],
                    child: Icon(Icons.shopping_cart, color: Colors.green[700]),
                  ),
                  title: Text(transaction.customerName ?? 'Walk-in Customer'),
                  subtitle: Text(
                    transaction.createdAt != null 
                        ? DateFormat('MMM dd, yyyy HH:mm').format(DateTime.parse(transaction.createdAt!))
                        : 'Unknown date',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${transaction.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        transaction.paymentType.toString().split('.').last.toUpperCase(),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ))),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryReport() {
    return RefreshIndicator(
      onRefresh: _loadInventoryReport,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Inventory Summary
            Card(
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[700], size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Low Stock Items',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.orange[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_lowStockItems.length} items need reordering',
                            style: TextStyle(color: Colors.orange[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Low Stock Items
            if (_lowStockItems.isNotEmpty) ...[
              Text(
                'Items Need Reordering',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ...(_lowStockItems.map((inventory) => Card(
                color: Colors.red[50],
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red[100],
                    child: Icon(Icons.inventory_2, color: Colors.red[700]),
                  ),
                  title: Text((inventory.product as Product).name),
                  subtitle: Text('Category: ${(inventory.product as Product).category}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Stock: ${inventory.quantity}',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Min: ${inventory.reorderLevel}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ))),
              const SizedBox(height: 24),
            ],
            
            // All Inventory Items
            Text(
              'Current Inventory',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            
            if (_isLoadingInventory)
              const Center(child: CircularProgressIndicator())
            else if (_inventoryData.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(
                    child: Text('No inventory data available'),
                  ),
                ),
              )
            else
              ...(_inventoryData.map((inventory) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: !inventory.isLowStock 
                        ? Colors.green[100] 
                        : Colors.red[100],
                    child: Icon(
                      Icons.inventory,
                      color: !inventory.isLowStock 
                          ? Colors.green[700] 
                          : Colors.red[700],
                    ),
                  ),
                  title: Text((inventory.product as Product).name),
                  subtitle: Text('${(inventory.product as Product).category} - ₹${(inventory.product as Product).price.toStringAsFixed(2)}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Qty: ${inventory.quantity}',
                        style: TextStyle(
                          color: !inventory.isLowStock 
                              ? Colors.green[700] 
                              : Colors.red[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Value: ₹${(inventory.quantity * (inventory.product as Product).price).toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ))),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryReport() {
    final totalInventoryValue = _inventoryData.fold<double>(
      0.0, 
      (sum, inventory) => sum + (inventory.quantity * (inventory.product as Product).price),
    );
    
    final averageTransactionValue = _totalTransactions > 0 
        ? _totalSales / _totalTransactions 
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Business Summary',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // Summary Cards Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildSummaryCard(
                'Total Sales',
                '₹${_totalSales.toStringAsFixed(2)}',
                Icons.trending_up,
                Colors.green,
              ),
              _buildSummaryCard(
                'Transactions',
                '$_totalTransactions',
                Icons.receipt,
                Colors.blue,
              ),
              _buildSummaryCard(
                'Avg Transaction',
                '₹${averageTransactionValue.toStringAsFixed(2)}',
                Icons.analytics,
                Colors.orange,
              ),
              _buildSummaryCard(
                'Inventory Value',
                '₹${totalInventoryValue.toStringAsFixed(2)}',
                Icons.inventory,
                Colors.purple,
              ),
              _buildSummaryCard(
                'Products',
                '${_inventoryData.length}',
                Icons.shopping_bag,
                Colors.teal,
              ),
              _buildSummaryCard(
                'Low Stock',
                '${_lowStockItems.length}',
                Icons.warning,
                Colors.red,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Quick Actions
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.shopping_cart, color: Colors.blue),
                  title: const Text('New Sale'),
                  subtitle: const Text('Create a new transaction'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.of(context).pushNamed('/billing');
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.add_box, color: Colors.green),
                  title: const Text('Add Product'),
                  subtitle: const Text('Add new product to inventory'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.of(context).pushNamed('/products');
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.inventory_2, color: Colors.orange),
                  title: const Text('Manage Inventory'),
                  subtitle: const Text('Update stock levels'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.of(context).pushNamed('/inventory');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}