import 'cart_item.dart';

enum PaymentType { cash, upi, credit }

class Transaction {
  final int? id;
  final int? customerId;
  final String? customerName;
  final int? userId;
  final List<CartItem> items;
  final double subtotal;
  final double discount;
  final double totalAmount;
  final PaymentType paymentType;
  final bool isPaid;
  final String? createdAt;

  Transaction({
    this.id,
    this.customerId,
    this.customerName,
    this.userId,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.totalAmount,
    required this.paymentType,
    this.isPaid = true,
    this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      customerId: json['customer_id'],
      customerName: json['customer_name'],
      userId: json['user_id'],
      items: (json['items'] as List<dynamic>)
          .map((item) => CartItem(
                product: item['product'],
                quantity: item['quantity'],
                discount: item['discount'].toDouble(),
              ))
          .toList(),
      subtotal: json['subtotal'].toDouble(),
      discount: json['discount'].toDouble(),
      totalAmount: json['total_amount'].toDouble(),
      paymentType: PaymentType.values.firstWhere(
          (e) => e.toString() == 'PaymentType.${json['payment_type'].toLowerCase()}',
          orElse: () => PaymentType.cash),
      isPaid: json['is_paid'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'total_amount': totalAmount,
      'payment_type': paymentType.toString().split('.').last,
      'is_paid': isPaid,
    };
  }
}
