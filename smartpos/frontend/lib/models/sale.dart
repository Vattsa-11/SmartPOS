class Sale {
  final int? id;
  final String invoiceNumber;
  final DateTime saleDate;
  final double totalAmount;
  final double taxAmount;
  final double discountAmount;
  final String paymentMethod;
  final String? customerName;
  final String? customerPhone;
  final List<SaleItem> items;
  final int? userId;
  final DateTime? createdAt;

  Sale({
    this.id,
    required this.invoiceNumber,
    required this.saleDate,
    required this.totalAmount,
    this.taxAmount = 0,
    this.discountAmount = 0,
    required this.paymentMethod,
    this.customerName,
    this.customerPhone,
    required this.items,
    this.userId,
    this.createdAt,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    // Safe integer conversion for id
    int? safeId;
    if (json['id'] != null) {
      if (json['id'] is int) {
        safeId = json['id'];
      } else {
        safeId = int.tryParse(json['id'].toString());
      }
    }

    // Safe integer conversion for user_id
    int? safeUserId;
    if (json['user_id'] != null) {
      if (json['user_id'] is int) {
        safeUserId = json['user_id'];
      } else {
        safeUserId = int.tryParse(json['user_id'].toString());
      }
    }

    return Sale(
      id: safeId,
      invoiceNumber: json['invoice_number']?.toString() ?? '',
      saleDate: json['sale_date'] != null 
          ? DateTime.parse(json['sale_date'])
          : DateTime.now(),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      taxAmount: (json['tax_amount'] ?? 0).toDouble(),
      discountAmount: (json['discount_amount'] ?? 0).toDouble(),
      paymentMethod: json['payment_method']?.toString() ?? 'cash',
      customerName: json['customer_name']?.toString(),
      customerPhone: json['customer_phone']?.toString(),
      items: json['items'] != null 
          ? (json['items'] as List).map((i) => SaleItem.fromJson(i)).toList()
          : [],
      userId: safeUserId,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'invoice_number': invoiceNumber,
      'sale_date': saleDate.toIso8601String(),
      'total_amount': totalAmount,
      'tax_amount': taxAmount,
      'discount_amount': discountAmount,
      'payment_method': paymentMethod,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'items': items.map((i) => i.toJson()).toList(),
      if (userId != null) 'user_id': userId,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}

class SaleItem {
  final int? id;
  final int productId;
  final String productName;
  final double quantity;
  final double price;
  final double total;

  SaleItem({
    this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.total,
  });

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    // Safe integer conversion
    int safeProductId = 0;
    if (json['product_id'] != null) {
      if (json['product_id'] is int) {
        safeProductId = json['product_id'];
      } else {
        safeProductId = int.tryParse(json['product_id'].toString()) ?? 0;
      }
    }

    return SaleItem(
      id: json['id'] is int ? json['id'] : (json['id'] != null ? int.tryParse(json['id'].toString()) : null),
      productId: safeProductId,
      productName: json['product_name']?.toString() ?? '',
      quantity: (json['quantity'] ?? 0).toDouble(),
      price: (json['price'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'price': price,
      'total': total,
    };
  }
}
