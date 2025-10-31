class Shop {
  final String id;
  final String ownerId;
  final String shopName;
  final String? shopDescription;
  final String? address;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Shop({
    required this.id,
    required this.ownerId,
    required this.shopName,
    this.shopDescription,
    this.address,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      shopName: json['shop_name'] as String,
      shopDescription: json['shop_description'] as String?,
      address: json['address'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'shop_name': shopName,
      'shop_description': shopDescription,
      'address': address,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Shop copyWith({
    String? id,
    String? ownerId,
    String? shopName,
    String? shopDescription,
    String? address,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Shop(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      shopName: shopName ?? this.shopName,
      shopDescription: shopDescription ?? this.shopDescription,
      address: address ?? this.address,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Shop(id: $id, shopName: $shopName, ownerId: $ownerId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Shop && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}