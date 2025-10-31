import '../models/product.dart';

class CartItem {
  final Product product;
  double quantity; // Changed to double to support weight-based products (e.g., 2.5 kg)
  double discount; // Percentage discount (0-100)

  CartItem({
    required this.product,
    this.quantity = 1.0,
    this.discount = 0.0,
  });

  double get unitPrice => product.sellingPrice;
  
  double get totalPrice => (product.sellingPrice * quantity) * (1 - discount / 100);

  // Helper to check if product is weight-based
  bool get isWeightBased {
    final unit = product.unit?.toLowerCase() ?? 'pcs';
    return unit == 'kg' || unit == 'g' || unit == 'ltr' || unit == 'ml';
  }

  CartItem copyWith({
    Product? product,
    double? quantity,
    double? discount,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      discount: discount ?? this.discount,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'product_id': product.id,
      'product_name': product.name,
      'quantity': quantity,
      'unit_price': unitPrice,
      'discount': discount,
      'total_price': totalPrice,
    };
  }
}