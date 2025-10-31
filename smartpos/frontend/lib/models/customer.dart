class Customer {
  final int id;
  final int userId;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String customerType;
  final double creditLimit;
  final double currentBalance;
  final double totalPurchases;
  final int purchaseCount;  // Add purchase count field
  final DateTime? lastPurchaseAt;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    required this.id,
    required this.userId,
    required this.name,
    this.phone,
    this.email,
    this.address,
    required this.customerType,
    required this.creditLimit,
    required this.currentBalance,
    required this.totalPurchases,
    this.purchaseCount = 0,  // Default to 0
    this.lastPurchaseAt,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      customerType: json['customer_type'] as String? ?? 'regular',
      creditLimit: _toDouble(json['credit_limit']),
      currentBalance: _toDouble(json['current_balance']),
      totalPurchases: _toDouble(json['total_purchases']),
      purchaseCount: json['purchase_count'] as int? ?? 0,  // Parse purchase count
      lastPurchaseAt: json['last_purchase_at'] != null
          ? DateTime.parse(json['last_purchase_at'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'customer_type': customerType,
      'credit_limit': creditLimit,
      'current_balance': currentBalance,
      'total_purchases': totalPurchases,
      'purchase_count': purchaseCount,  // Include purchase count
      'last_purchase_at': lastPurchaseAt?.toIso8601String(),
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
