import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/customer.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';

class CartProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<CartItem> _items = [];
  PaymentType _paymentType = PaymentType.cash;
  Customer? _selectedCustomer;
  bool _isLoading = false;
  String? _error;
  
  // Getters
  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.length;
  PaymentType get paymentType => _paymentType;
  Customer? get selectedCustomer => _selectedCustomer;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Total calculations
  double get subtotal => _items.fold(0, (sum, item) => sum + (item.product.price * item.quantity));
  double get discount => _items.fold(0, (sum, item) => sum + ((item.product.price * item.quantity) * (item.discount / 100)));
  double get total => subtotal - discount;
  
  // Set payment type
  void setPaymentType(PaymentType type) {
    _paymentType = type;
    notifyListeners();
  }
  
  // Set selected customer
  void setCustomer(Customer? customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }
  
  // Add item to cart
  void addItem(Product product, {int quantity = 1}) {
    final existingIndex = _items.indexWhere((item) => item.product.id == product.id);
    
    if (existingIndex >= 0) {
      // Increase quantity if product already exists in cart
      _items[existingIndex].quantity += quantity;
    } else {
      // Add new item to cart
      _items.add(CartItem(
        product: product,
        quantity: quantity,
      ));
    }
    
    notifyListeners();
  }
  
  // Update item quantity
  void updateItemQuantity(int productId, int quantity) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    
    if (index >= 0) {
      if (quantity <= 0) {
        // Remove item if quantity is zero or negative
        _items.removeAt(index);
      } else {
        // Update quantity
        _items[index].quantity = quantity;
      }
      
      notifyListeners();
    }
  }
  
  // Update item discount
  void updateItemDiscount(int productId, double discount) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    
    if (index >= 0) {
      // Ensure discount is between 0 and 100
      _items[index].discount = discount.clamp(0, 100);
      notifyListeners();
    }
  }
  
  // Remove item from cart
  void removeItem(int productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }
  
  // Clear cart
  void clearCart() {
    _items = [];
    _selectedCustomer = null;
    _paymentType = PaymentType.cash;
    notifyListeners();
  }
  
  // Create transaction (checkout)
  Future<Transaction?> checkout() async {
    if (_items.isEmpty) {
      _error = 'Cart is empty';
      notifyListeners();
      return null;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final transaction = Transaction(
        customerId: _selectedCustomer?.id,
        customerName: _selectedCustomer?.name,
        items: List.from(_items),
        subtotal: subtotal,
        discount: discount,
        totalAmount: total,
        paymentType: _paymentType,
        isPaid: _paymentType != PaymentType.credit,
      );
      
      // In a real app, you would call an API here
      final result = await _apiService.createTransaction(transaction.toJson());
      
      // Clear the cart after successful checkout
      clearCart();
      
      _isLoading = false;
      notifyListeners();
      
      // Return the created transaction
      return Transaction(
        id: result['id'],
        customerId: result['customer_id'],
        customerName: result['customer_name'],
        items: transaction.items,
        subtotal: transaction.subtotal,
        discount: transaction.discount,
        totalAmount: transaction.totalAmount,
        paymentType: transaction.paymentType,
        isPaid: transaction.isPaid,
        createdAt: result['created_at'] ?? DateTime.now().toIso8601String(),
      );
    } catch (e) {
      _error = 'Failed to create transaction: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
