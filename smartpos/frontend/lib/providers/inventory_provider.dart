import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class InventoryProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Product> _inventory = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  bool _showLowStockOnly = false;
  
  // Getters
  List<Product> get inventory => _inventory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  bool get showLowStockOnly => _showLowStockOnly;
  
  // Filtered inventory based on search and filters
  List<Product> get filteredInventory {
    var filtered = _inventory;
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((product) {
        final query = _searchQuery.toLowerCase();
        return product.name.toLowerCase().contains(query) ||
               (product.barcode?.toLowerCase().contains(query) ?? false) ||
               (product.sku?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
    
    // Apply low stock filter
    if (_showLowStockOnly) {
      filtered = filtered.where((product) {
        final stock = product.stock ?? 0;
        final minStock = product.minimumStock ?? 0;
        return stock <= minStock;
      }).toList();
    }
    
    return filtered;
  }
  
  // Get low stock products
  List<Product> get lowStockProducts {
    return _inventory.where((product) {
      final stock = product.stock ?? 0;
      final minStock = product.minimumStock ?? 0;
      return stock <= minStock;
    }).toList();
  }
  
  // Get total inventory value
  double get totalInventoryValue {
    return _inventory.fold(0.0, (sum, product) {
      final stock = product.stock ?? 0;
      final cost = product.costPrice ?? product.sellingPrice;
      return sum + (stock * cost);
    });
  }
  
  // Fetch inventory from API
  Future<void> fetchInventory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Use /products endpoint which includes inventory data
      final data = await _apiService.getProducts();
      _inventory = data;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _inventory = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Update stock for a product
  Future<bool> updateStock(int productId, int newStock) async {
    try {
      await _apiService.updateInventory(productId, {'stock': newStock});
      // Update local after successful API call
      final index = _inventory.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _inventory[index] = _inventory[index].copyWith(stock: newStock);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Update product details
  Future<bool> updateProduct(int productId, Product product, int stock, int minimumStock) async {
    try {
      // Update product details
      final updatedProduct = await _apiService.updateProduct(productId, product);
      
      // Update stock if provided
      if (stock >= 0) {
        await _apiService.updateInventory(productId, {
          'stock': stock,
          'minimum_stock': minimumStock,
        });
      }
      
      // Update local inventory
      final index = _inventory.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _inventory[index] = updatedProduct.copyWith(
          stock: stock,
          minimumStock: minimumStock,
        );
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Add new product with initial stock
  Future<bool> addProduct(Product product, int initialStock, int minimumStock) async {
    try {
      // Create product with initial stock
      final productData = product.toJson();
      productData['initial_stock'] = initialStock;
      productData['minimum_stock'] = minimumStock;
      
      final newProduct = await _apiService.createProduct(Product.fromJson(productData));
      
      // Add to local inventory
      _inventory.add(newProduct);
      notifyListeners();
      
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  // Adjust stock (add or subtract)
  Future<bool> adjustStock(int productId, int adjustment) async {
    final product = _inventory.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw Exception('Product not found'),
    );
    
    final currentStock = product.stock ?? 0;
    final newStock = currentStock + adjustment;
    
    if (newStock < 0) {
      _error = 'Stock cannot be negative';
      notifyListeners();
      return false;
    }
    
    return await updateStock(productId, newStock);
  }
  
  // Search by barcode (for scanner integration)
  Product? searchByBarcode(String barcode) {
    try {
      return _inventory.firstWhere(
        (product) => product.barcode == barcode,
      );
    } catch (e) {
      return null;
    }
  }
  
  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
  
  // Toggle low stock filter
  void toggleLowStockFilter() {
    _showLowStockOnly = !_showLowStockOnly;
    notifyListeners();
  }
  
  // Reset all filters
  void resetFilters() {
    _searchQuery = '';
    _showLowStockOnly = false;
    notifyListeners();
  }
  
  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}