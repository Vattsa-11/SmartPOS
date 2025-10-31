import 'package:flutter/material.dart';

class Helpers {
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  static bool isLowStock(int currentStock, int minimumStock) {
    return currentStock <= minimumStock;
  }

  static double calculateDiscount(double price, double discountPercentage) {
    return price * (discountPercentage / 100);
  }

  static double calculateTax(double price, double taxPercentage) {
    return price * (taxPercentage / 100);
  }

  static double calculateTotal({
    required double basePrice,
    double taxPercentage = 0,
    double discountPercentage = 0,
  }) {
    final discount = calculateDiscount(basePrice, discountPercentage);
    final priceAfterDiscount = basePrice - discount;
    final tax = calculateTax(priceAfterDiscount, taxPercentage);
    return priceAfterDiscount + tax;
  }
}
