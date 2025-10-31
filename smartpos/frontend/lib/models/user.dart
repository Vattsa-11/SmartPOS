class User {
  final String? id;
  final String email;
  final String ownerName;
  final String phone;
  final String shopName;  // Direct field from backend
  final String? upiId;
  final String? upiQrUrl;

  User({
    this.id,
    required this.email,
    required this.ownerName,
    required this.phone,
    required this.shopName,
    this.upiId,
    this.upiQrUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString(),
      email: json['email'] ?? '',
      ownerName: json['owner_name'] ?? '',
      phone: json['phone'] ?? '',
      shopName: json['shop_name'] ?? '',
      upiId: json['upi_id'],
      upiQrUrl: json['upi_qr_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'owner_name': ownerName,
      'phone': phone,
      'shop_name': shopName,
      'upi_id': upiId,
      'upi_qr_url': upiQrUrl,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? ownerName,
    String? phone,
    String? shopName,
    String? upiId,
    String? upiQrUrl,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      shopName: shopName ?? this.shopName,
      upiId: upiId ?? this.upiId,
      upiQrUrl: upiQrUrl ?? this.upiQrUrl,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, ownerName: $ownerName, shop: $shopName)';
  }
}
