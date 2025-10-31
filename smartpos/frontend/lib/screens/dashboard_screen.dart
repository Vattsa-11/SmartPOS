import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/products_provider.dart';
import '../providers/inventory_provider.dart';
import '../services/api_service.dart';
import '../models/sale.dart';
import '../utils/routes.dart';
import '../utils/formatters.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  int _totalProducts = 0;
  int _lowStockCount = 0;
  double _todaysSales = 0.0;
  int _totalCustomers = 0;
  List<Sale> _recentSales = [];

  @override
  void initState() {
    super.initState();
    // Don't auto-load, let the build check authentication first
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load data after authentication is confirmed
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated && authProvider.user?.id != null) {
      if (_isLoading) {
        // Use post-frame callback to avoid setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadDashboardData();
        });
      }
    }
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    
    // Check if user is authenticated
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null || authProvider.user!.id == null) {
      // User not authenticated, navigate to login
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final productsProvider = Provider.of<ProductsProvider>(context, listen: false);
      final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
      
      // Load products and inventory
      await Future.wait([
        productsProvider.fetchProducts(),
        inventoryProvider.fetchInventory(),
      ]);
      
      if (!mounted) return;
      
      // Get stats
      _totalProducts = productsProvider.products.length;
      _lowStockCount = inventoryProvider.lowStockProducts.length;
      
      // Get today's sales
      final sales = await _apiService.getSales();
      final today = DateTime.now();
      final todaysSales = sales.where((sale) {
        return sale.saleDate.year == today.year &&
               sale.saleDate.month == today.month &&
               sale.saleDate.day == today.day;
      });
      _todaysSales = todaysSales.fold(0.0, (sum, sale) => sum + sale.totalAmount);
      
      // Get recent sales (last 5)
      _recentSales = sales.take(5).toList();
      
      // Get total customers
      final customers = await _apiService.getCustomers();
      _totalCustomers = customers.length;
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  Future<void> _showCustomersListDialog() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = int.tryParse(authProvider.user?.id?.toString() ?? '0') ?? 0;
      final customers = await _apiService.getCustomers(userId: userId);
      
      if (!mounted) return;
      
      if (customers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No customers found')),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: const Color(0xFF2c3e50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Text(
                          '👥',
                          style: TextStyle(fontSize: 24),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Customers List',
                          style: TextStyle(
                            color: Color(0xFFecf0f1),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Color(0xFFe74c3c)),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFe74c3c).withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Total Customers: ${customers.length}',
                  style: const TextStyle(
                    color: Color(0xFF95a5a6),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Customer Table
                Flexible(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(
                          const Color(0xFF34495e),
                        ),
                        dataRowColor: MaterialStateProperty.resolveWith(
                          (states) => const Color(0xFF2c3e50),
                        ),
                        columns: const [
                          DataColumn(
                            label: Text(
                              'Customer',
                              style: TextStyle(
                                color: Color(0xFFecf0f1),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Phone',
                              style: TextStyle(
                                color: Color(0xFFecf0f1),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Last Purchase',
                              style: TextStyle(
                                color: Color(0xFFecf0f1),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Total Spent',
                              style: TextStyle(
                                color: Color(0xFFecf0f1),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Purchases',
                              style: TextStyle(
                                color: Color(0xFFecf0f1),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        rows: customers.map((customer) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  customer.name,
                                  style: const TextStyle(
                                    color: Color(0xFFecf0f1),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  customer.phone ?? 'N/A',
                                  style: const TextStyle(color: Color(0xFFecf0f1)),
                                ),
                              ),
                              DataCell(
                                Text(
                                  customer.lastPurchaseAt != null
                                      ? '${customer.lastPurchaseAt!.day}/${customer.lastPurchaseAt!.month}/${customer.lastPurchaseAt!.year}'
                                      : 'Never',
                                  style: const TextStyle(color: Color(0xFFecf0f1)),
                                ),
                              ),
                              DataCell(
                                Text(
                                  Formatters.formatCurrency(customer.totalPurchases),
                                  style: const TextStyle(
                                    color: Color(0xFF2ecc71),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3498db),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${customer.purchaseCount}', // Use actual purchase count
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load customers: $e')),
        );
      }
    }
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String emoji,
    required String title,
    required String description,
    required Function() onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToSection(String route) async {
    final result = await Navigator.pushNamed(context, route);
    // If result is true, refresh dashboard data
    if (result == true && mounted) {
      _loadDashboardData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return WillPopScope(
      onWillPop: () async => false, // Prevent back button
      child: Scaffold(
        appBar: AppBar(
          title: Text(user?.shopName ?? 'Dashboard'),
          automaticallyImplyLeading: false, // Remove back button
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadDashboardData,
              tooltip: 'Refresh',
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: 'Logout',
            ),
          ],
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadDashboardData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Welcome Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            children: [
                              const TextSpan(text: 'Welcome back, '),
                              TextSpan(
                                text: user?.ownerName ?? 'User',
                                style: const TextStyle(
                                  color: Colors.black,
                                ),
                              ),
                              const TextSpan(text: '! 👋'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.shopName ?? 'Your Shop',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Quick Stats
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.8,
                            children: [
                              _buildStatCard(
                                'TOTAL PRODUCTS',
                                _totalProducts.toString(),
                                const Color(0xFF3498DB),
                              ),
                              _buildStatCard(
                                'LOW STOCK ITEMS',
                                _lowStockCount.toString(),
                                Colors.orange,
                              ),
                              _buildStatCard(
                                'TODAY\'S SALES',
                                Formatters.formatCurrency(_todaysSales),
                                Colors.green,
                              ),
                              _buildStatCard(
                                'TOTAL CUSTOMERS',
                                _totalCustomers.toString(),
                                const Color(0xFF9B59B6),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  
                  // Quick Actions
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GridView.count(
                          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 1.1,
                          children: [
                            _buildActionCard(
                              emoji: '📦',
                              title: 'Add Product',
                              description: 'Add new products to inventory',
                              onTap: () => _navigateToSection(AppRoutes.addProduct),
                            ),
                            _buildActionCard(
                              emoji: '📋',
                              title: 'View Inventory',
                              description: 'Manage stock levels',
                              onTap: () => _navigateToSection(AppRoutes.inventory),
                            ),
                            _buildActionCard(
                              emoji: '🧾',
                              title: 'Billing',
                              description: 'Create new sale',
                              onTap: () => _navigateToSection(AppRoutes.billing),
                            ),
                            _buildActionCard(
                              emoji: '👥',
                              title: 'Customers',
                              description: 'View customer list',
                              onTap: () => _showCustomersListDialog(),
                            ),
                            _buildActionCard(
                              emoji: '📊',
                              title: 'Reports',
                              description: 'View analytics & reports',
                              onTap: () => _navigateToSection(AppRoutes.reports),
                            ),
                            _buildActionCard(
                              emoji: '⚙️',
                              title: 'Settings',
                              description: 'Configure system settings',
                              onTap: () => _navigateToSection(AppRoutes.settings),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Recent Activity
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recent Activity',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_recentSales.isEmpty)
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(
                                child: Text(
                                  'No recent activity',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          ..._recentSales.map((sale) => Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF27AE60),
                                child: const Icon(
                                  Icons.receipt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                sale.invoiceNumber ?? 'Invoice',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${sale.items.length} items • ${sale.paymentMethod}\n${Formatters.formatDateTime(sale.saleDate)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Text(
                                Formatters.formatCurrency(sale.totalAmount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF27AE60),
                                ),
                              ),
                            ),
                          )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
