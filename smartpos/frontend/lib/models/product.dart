class Product {
  final int? id;
  final String name;
  final String? barcode;
  final String? sku;
  final double sellingPrice;
  final double? costPrice;
  final int? stock;
  final int? minimumStock;
  final String? unit;
  final double? discountPercentage;
  final double? taxPercentage;
  final String? description;
  final bool? isFeatured;
  final int? categoryId;
  final int? userId;
  final String? createdAt;
  final String? updatedAt;
  
  // Convenience getter for price (alias for sellingPrice for backward compatibility)
  double get price => sellingPrice;

  Product({
    this.id,
    required this.name,
    this.barcode,
    this.sku,
    required this.sellingPrice,
    this.costPrice,
    this.stock,
    this.minimumStock,
    this.unit = 'pcs',
    this.discountPercentage = 0.0,
    this.taxPercentage = 0.0,
    this.description,
    this.isFeatured = false,
    this.categoryId,
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] is String ? int.tryParse(json['id']) : json['id'],
      name: json['name'] ?? '',
      barcode: json['barcode'],
      sku: json['sku'],
      sellingPrice: _parseDouble(json['selling_price'] ?? json['price']),
      costPrice: _parseDouble(json['cost_price']),
      stock: _parseInt(json['stock'] ?? json['current_stock']),
      minimumStock: _parseInt(json['minimum_stock'] ?? json['reorder_level']),
      unit: json['unit'] ?? 'pcs',
      discountPercentage: _parseDouble(json['discount_percentage']),
      taxPercentage: _parseDouble(json['tax_percentage']),
      description: json['description'],
      isFeatured: json['is_featured'] ?? false,
      categoryId: json['category_id'] is String ? int.tryParse(json['category_id']) : json['category_id'],
      userId: json['user_id'] is String ? int.tryParse(json['user_id']) : json['user_id'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (barcode != null) 'barcode': barcode,
      if (sku != null) 'sku': sku,
      'selling_price': sellingPrice,
      'price': sellingPrice, // Backend requires price field (NOT NULL constraint)
      'cost_price': costPrice ?? 0.0, // Default to 0 if not set
      'initial_stock': stock ?? 0,  // Use initial_stock for product creation
      'minimum_stock': minimumStock ?? 0,
      'maximum_stock': 1000,  // Default maximum stock
      'unit': unit ?? 'pcs',
      'discount_percentage': discountPercentage ?? 0.0,
      'tax_percentage': taxPercentage ?? 0.0,
      if (description != null) 'description': description,
      'is_featured': isFeatured ?? false,
      if (categoryId != null) 'category_id': categoryId,
      if (userId != null) 'user_id': userId,  // Include user_id in request
    };
  }

  Product copyWith({
    int? id,
    String? name,
    String? barcode,
    String? sku,
    double? sellingPrice,
    double? costPrice,
    int? stock,
    int? minimumStock,
    String? unit,
    double? discountPercentage,
    double? taxPercentage,
    String? description,
    bool? isFeatured,
    int? categoryId,
    int? userId,
    String? createdAt,
    String? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      sku: sku ?? this.sku,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      costPrice: costPrice ?? this.costPrice,
      stock: stock ?? this.stock,
      minimumStock: minimumStock ?? this.minimumStock,
      unit: unit ?? this.unit,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      description: description ?? this.description,
      isFeatured: isFeatured ?? this.isFeatured,
      categoryId: categoryId ?? this.categoryId,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
