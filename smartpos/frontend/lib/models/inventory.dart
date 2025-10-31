class Inventory {
  final int? id;
  final int productId;
  final int quantity;
  final int reorderLevel;
  final DateTime? expiryDate;
  final dynamic product;

  Inventory({
    this.id,
    required this.productId,
    required this.quantity,
    required this.reorderLevel,
    this.expiryDate,
    this.product,
  });

  factory Inventory.fromJson(Map<String, dynamic> json) {
    return Inventory(
      id: json['id'],
      productId: json['product_id'],
      quantity: json['quantity'],
      reorderLevel: json['reorder_level'],
      expiryDate: json['expiry_date'] != null 
          ? DateTime.parse(json['expiry_date']) 
          : null,
      product: json['product'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'quantity': quantity,
      'reorder_level': reorderLevel,
      'expiry_date': expiryDate?.toIso8601String(),
    };
  }

  Inventory copyWith({
    int? id,
    int? productId,
    int? quantity,
    int? reorderLevel,
    DateTime? expiryDate,
    dynamic product,
  }) {
    return Inventory(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      expiryDate: expiryDate ?? this.expiryDate,
      product: product ?? this.product,
    );
  }

  bool get isLowStock => quantity <= reorderLevel;
}
