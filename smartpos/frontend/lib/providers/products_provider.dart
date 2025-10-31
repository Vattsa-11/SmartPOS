import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class ProductsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  
  List<Product> get products => _searchQuery.isEmpty
      ? _products
      : _products.where((p) =>
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (p.barcode?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (p.sku?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
        ).toList();
  
  List<Product> get lowStockProducts => _products
      .where((p) => (p.stock ?? 0) <= (p.minimumStock ?? 0))
      .toList();
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalProducts => _products.length;
  int get lowStockCount => lowStockProducts.length;
  
  // Fetch all products
  Future<void> fetchProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _products = await _apiService.getProducts();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Get single product
  Future<Product?> getProduct(int id) async {
    try {
      return await _apiService.getProduct(id);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }
  
  // Search by barcode
  Product? searchByBarcode(String barcode) {
    if (barcode.isEmpty) return null;
    try {
      return _products.firstWhere(
        (p) => p.barcode?.toLowerCase() == barcode.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }
  
  // Create product
  Future<bool> createProduct(Product product) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final newProduct = await _apiService.createProduct(product);
      _products.add(newProduct);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Update product
  Future<bool> updateProduct(int id, Product product) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final updatedProduct = await _apiService.updateProduct(id, product);
      final index = _products.indexWhere((p) => p.id == id);
      if (index != -1) {
        _products[index] = updatedProduct;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Delete product
  Future<bool> deleteProduct(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _apiService.deleteProduct(id);
      _products.removeWhere((p) => p.id == id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Update stock
  Future<bool> updateStock(int id, int newStock) async {
    try {
      final product = _products.firstWhere((p) => p.id == id);
      final updated = await _apiService.updateProduct(
        id,
        product.copyWith(stock: newStock),
      );
      final index = _products.indexWhere((p) => p.id == id);
      if (index != -1) {
        _products[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
  
  // Search
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
  
  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
