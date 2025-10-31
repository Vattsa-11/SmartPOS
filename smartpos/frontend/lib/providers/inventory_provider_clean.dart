import 'package:flutter/material.dart';
import '../models/inventory.dart';
import '../models/product.dart';
// TODO: Replace with API service when backend is ready
// import '../services/api_service.dart';

class InventoryProvider extends ChangeNotifier {
  // TODO: Replace SupabaseProductService with ApiService
  // final ApiService _apiService = ApiService();
  
  List<Inventory> _inventoryItems = [];
  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;
  
  // Filter properties
  String _searchQuery = '';
  String _filterCategory = 'All';
  bool _showLowStockOnly = false;
  bool _showExpiringOnly = false;
  
  // Getters
  List<Inventory> get inventoryItems => _inventoryItems;
  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Filter getters
  String get searchQuery => _searchQuery;
  String get filterCategory => _filterCategory;
  bool get showLowStockOnly => _showLowStockOnly;
  bool get showExpiringOnly => _showExpiringOnly;
  
  // Filtered inventory based on current filters
  List<Inventory> get filteredInventory {
    if (_inventoryItems.isEmpty) {
      return [];
    }
    
    return _inventoryItems.where((item) {
      // Create a product from the product data
      final product = item.product is Product 
          ? item.product as Product
          : Product.fromJson(item.product);
      
      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!product.name.toLowerCase().contains(query) && 
            !product.barcode.toLowerCase().contains(query) &&
            !product.category.toLowerCase().contains(query)) {
          return false;
        }
      }
      
      // Apply category filter
      if (_filterCategory != 'All' && product.category != _filterCategory) {
        return false;
      }
      
      // Apply low stock filter
      if (_showLowStockOnly && !item.isLowStock) {
        return false;
      }
      
      // Apply expiring filter
      if (_showExpiringOnly && 
          (item.expiryDate == null || 
           item.expiryDate!.isAfter(DateTime.now().add(const Duration(days: 30))))) {
        return false;
      }
      
      return true;
    }).toList();
  }
  
  // Get available categories from products
  List<String> get categories {
    final Set<String> categories = {'All'};
    
    for (var item in _inventoryItems) {
      if (item.product != null) {
        final product = item.product is Product 
            ? item.product as Product
            : Product.fromJson(item.product);
        categories.add(product.category);
      }
    }
    
    return categories.toList();
  }
  
  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
  
  // Set filter category
  void setFilterCategory(String category) {
    _filterCategory = category;
    notifyListeners();
  }
  
  // Toggle low stock filter
  void toggleLowStockFilter() {
    _showLowStockOnly = !_showLowStockOnly;
    notifyListeners();
  }
  
  // Toggle expiring filter
  void toggleExpiringFilter() {
    _showExpiringOnly = !_showExpiringOnly;
    notifyListeners();
  }
  
  // Reset all filters
  void resetFilters() {
    _searchQuery = '';
    _filterCategory = 'All';
    _showLowStockOnly = false;
    _showExpiringOnly = false;
    notifyListeners();
  }
  
  // Load inventory data
  Future<void> fetchInventory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // TODO: Replace with API call
      // _inventoryItems = await _apiService.getInventory();
      
      // Temporary: Return empty list until backend is ready
      _inventoryItems = [];
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load inventory: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Load products
  Future<void> fetchProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // TODO: Replace with API call
      // _products = await _apiService.getProducts();
      
      // Temporary: Return empty list until backend is ready
      _products = [];
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load products: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Add a product with initial inventory
  Future<void> addProduct(Product product, int quantity, int reorderLevel, {String? expiryDate}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // TODO: Replace with API calls
      // final newProduct = await _apiService.addProduct(product);
      // await _apiService.addInventory(newProduct.id!, quantity, reorderLevel, expiryDate: expiry);
      
      // Temporary implementation
      print('TODO: Add product via API: ${product.name}');
      
      // Refresh data
      await fetchProducts();
      await fetchInventory();
    } catch (e) {
      _error = 'Failed to add product: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Update a product and its inventory
  Future<void> updateProduct(int id, Product product, int quantity, int reorderLevel, {String? expiryDate}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // TODO: Replace with API calls
      // await _apiService.updateProduct(id, product);
      // await _apiService.updateInventory(id, quantity, reorderLevel: reorderLevel);
      
      // Temporary implementation
      print('TODO: Update product via API: ${product.name}');
      
      // Refresh data
      await fetchProducts();
      await fetchInventory();
    } catch (e) {
      _error = 'Failed to update product: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Delete a product
  Future<void> deleteProduct(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // TODO: Replace with API call
      // await _apiService.deleteProduct(id);
      
      // Temporary implementation
      print('TODO: Delete product via API: $id');
      
      // Update local state temporarily
      _products.removeWhere((p) => p.id == id);
      _inventoryItems.removeWhere((item) => item.productId == id);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete product: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Update inventory item quantity
  Future<void> updateStock(int productId, int newQuantity) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // TODO: Replace with API call
      // await _apiService.updateInventory(productId, newQuantity);
      
      // Temporary implementation
      print('TODO: Update stock via API: Product $productId, Quantity $newQuantity');
      
      // Update local state temporarily
      final index = _inventoryItems.indexWhere((item) => item.productId == productId);
      if (index >= 0) {
        // TODO: Fix this when we have proper copyWith method
        // _inventoryItems[index] = _inventoryItems[index].copyWith(quantity: newQuantity);
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update stock: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}