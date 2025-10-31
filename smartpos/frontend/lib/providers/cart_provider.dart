import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/customer.dart';
import '../models/sale.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class CartProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  final List<CartItem> _items = [];
  Customer? _customer;
  String _paymentMethod = 'Cash'; // Cash or UPI
  bool _isLoading = false;
  String? _error;
  Sale? _lastSale; // Store last completed sale for invoice
  
  // Getters
  List<CartItem> get items => _items;
  Customer? get customer => _customer;
  String get paymentMethod => _paymentMethod;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Sale? get lastSale => _lastSale;
  
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity.toInt());
  
  double get subtotal {
    return _items.fold(0.0, (sum, item) {
      return sum + (item.product.sellingPrice * item.quantity);
    });
  }
  
  double get totalDiscount {
    return _items.fold(0.0, (sum, item) {
      final itemTotal = item.product.sellingPrice * item.quantity;
      return sum + (itemTotal * item.discount / 100);
    });
  }
  
  double get totalTax {
    return _items.fold(0.0, (sum, item) {
      final itemTotal = item.product.sellingPrice * item.quantity;
      final discountedTotal = itemTotal * (1 - item.discount / 100);
      final taxPercent = item.product.taxPercentage ?? 0;
      return sum + (discountedTotal * taxPercent / 100);
    });
  }
  
  double get total {
    return subtotal - totalDiscount + totalTax;
  }
  
  // Add item to cart
  void addItem(Product product, {double quantity = 1.0}) {
    final existingIndex = _items.indexWhere((item) => item.product.id == product.id);
    
    if (existingIndex >= 0) {
      // Update quantity if item exists
      _items[existingIndex].quantity += quantity;
    } else {
      // Add new item
      _items.add(CartItem(product: product, quantity: quantity));
    }
    
    _error = null;
    notifyListeners();
  }
  
  // Remove item from cart
  void removeItem(int productId) {
    _items.removeWhere((item) => item.product.id == productId);
    _error = null;
    notifyListeners();
  }
  
  // Update item quantity
  void updateQuantity(int productId, double quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      _items[index].quantity = quantity;
      notifyListeners();
    }
  }
  
  // Update item discount
  void updateDiscount(int productId, double discount) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      _items[index].discount = discount.clamp(0, 100); // Ensure 0-100 range
      notifyListeners();
    }
  }
  
  // Set customer
  void setCustomer(Customer? customer) {
    _customer = customer;
    notifyListeners();
  }
  
  // Set payment method
  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }
  
  // Clear cart
  void clearCart() {
    _items.clear();
    _customer = null;
    _paymentMethod = 'Cash';
    _error = null;
    _lastSale = null;
    notifyListeners();
  }
  
  // Checkout - create sale
  Future<Sale?> checkout({String? customerName, String? customerPhone}) async {
    if (_items.isEmpty) {
      _error = 'Cart is empty';
      notifyListeners();
      return null;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Prepare sale data matching Sale model
      final sale = Sale(
        invoiceNumber: 'INV-${DateTime.now().millisecondsSinceEpoch}',
        saleDate: DateTime.now(),
        totalAmount: total,
        taxAmount: totalTax,
        discountAmount: totalDiscount,
        paymentMethod: _paymentMethod,
        customerName: customerName ?? _customer?.name ?? 'Walk-in Customer',
        customerPhone: customerPhone ?? _customer?.phone,
        items: _items.map((item) {
          return SaleItem(
            productId: item.product.id!,
            productName: item.product.name,
            quantity: item.quantity.toDouble(),
            price: item.product.sellingPrice,
            total: item.totalPrice,
          );
        }).toList(),
      );
      
      // Create sale via API
      final createdSale = await _apiService.createSale(sale);
      _lastSale = createdSale;
      _error = null;
      
      // Clear cart after successful checkout
      clearCart();
      
      return createdSale;
    } catch (e) {
      _error = e.toString();
      _lastSale = null;
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  // Clear last sale
  void clearLastSale() {
    _lastSale = null;
    notifyListeners();
  }
}