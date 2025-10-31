import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/products_provider.dart';
import '../providers/inventory_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../utils/routes.dart';
import '../utils/formatters.dart';

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

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      final productsProvider = Provider.of<ProductsProvider>(context, listen: false);
      final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
      
      // Load products and inventory
      await Future.wait([
        productsProvider.fetchProducts(),
        inventoryProvider.fetchInventory(),
      ]);
      
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
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  Widget _buildDashboardItem({
    required IconData icon,
    required String title,
    required Function() onTap,
    Color? color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color ?? Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToSection(String route) {
    Navigator.pushNamed(context, route);
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
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: 'Logout',
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome message with owner name
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Column(
                  children: [
                    Text(
                      'Welcome!',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    if (user?.ownerName != null && user!.ownerName.isNotEmpty)
                      Text(
                        user.ownerName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      )
                    else if (user?.shopName != null && user!.shopName.isNotEmpty)
                      Text(
                        user.shopName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      )
                    else
                      Text(
                        user?.email ?? 'User',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    // Show shop name as subtitle if different from owner name
                    if (user?.shopName != null && 
                        user!.shopName.isNotEmpty && 
                        user.shopName != user.ownerName)
                      Text(
                        user.shopName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
              // Dashboard grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.count(
                    crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildDashboardItem(
                        icon: Icons.add_shopping_cart,
                        title: 'Add/Edit Products',
                        onTap: () => _navigateToSection(AppRoutes.addProduct),
                        color: Colors.blue,
                      ),
                      _buildDashboardItem(
                        icon: Icons.inventory,
                        title: 'View Inventory',
                        onTap: () => _navigateToSection(AppRoutes.inventory),
                        color: Colors.green,
                      ),
                      _buildDashboardItem(
                        icon: Icons.receipt,
                        title: 'Billing',
                        onTap: () => _navigateToSection(AppRoutes.billing),
                        color: Colors.orange,
                      ),
                      _buildDashboardItem(
                        icon: Icons.people,
                        title: 'Customers',
                        onTap: () {},
                        color: Colors.purple,
                      ),
                      _buildDashboardItem(
                        icon: Icons.bar_chart,
                        title: 'Reports',
                        onTap: () => _navigateToSection(AppRoutes.reports),
                        color: Colors.red,
                      ),
                      _buildDashboardItem(
                        icon: Icons.settings,
                        title: 'Settings',
                        onTap: () => _navigateToSection(AppRoutes.settings),
                        color: Colors.blueGrey,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
