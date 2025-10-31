import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../models/customer.dart';
import '../models/cart_item.dart';
import '../models/transaction.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({Key? key}) : super(key: key);

  @override
  _BillingScreenState createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final ApiService _apiService = ApiService();
  final _barcodeController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  List<Customer> _customers = [];
  Customer? _selectedCustomer;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final customersData = await _apiService.getCustomers();
      setState(() {
        _customers = customersData.map<Customer>((data) {
          if (data is Map<String, dynamic>) {
            return Customer.fromJson(data);
          } else {
            return data as Customer;
          }
        }).toList();
        
        if (_customers.isNotEmpty) {
          _selectedCustomer = _customers[0];
        }
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load customers: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _scanBarcode() async {
    final barcode = _barcodeController.text.trim();
    if (barcode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a barcode')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final product = await _apiService.searchProductByBarcode(barcode);
      Provider.of<CartProvider>(context, listen: false).addItem(product);
      _barcodeController.clear();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product not found: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showItemEditDialog(BuildContext context, CartItem item, int index) {
    final _itemQuantityController = TextEditingController(text: item.quantity.toString());
    final _itemDiscountController = TextEditingController(text: item.discount.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit ${item.product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _itemQuantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _itemDiscountController,
              decoration: const InputDecoration(
                labelText: 'Discount (%)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 8),
            Text(
              'Unit Price: ₹${item.product.price.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Consumer<CartProvider>(
              builder: (context, cart, child) {
                final qty = int.tryParse(_itemQuantityController.text) ?? item.quantity;
                final discount = double.tryParse(_itemDiscountController.text) ?? item.discount;
                final total = (item.product.price * qty) * (1 - discount / 100);
                
                return Text(
                  'Total: ₹${total.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              try {
                final quantity = int.parse(_itemQuantityController.text);
                final discount = double.parse(_itemDiscountController.text);
                
                if (quantity <= 0) {
                  // Remove item if quantity is zero or negative
                  Provider.of<CartProvider>(context, listen: false)
                      .removeItem(item.product.id!);
                } else {
                  // Update quantity and discount
                  Provider.of<CartProvider>(context, listen: false)
                      .updateItemQuantity(item.product.id!, quantity);
                  Provider.of<CartProvider>(context, listen: false)
                      .updateItemDiscount(item.product.id!, discount);
                }
                Navigator.of(ctx).pop();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Invalid input: ${e.toString()}')),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateBill() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    
    if (cartProvider.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty')),
      );
      return;
    }
    
    // Set customer if selected
    if (_selectedCustomer != null) {
      cartProvider.setCustomer(_selectedCustomer);
    }
    
    try {
      final transaction = await cartProvider.checkout();
      
      if (transaction != null) {
        _showBillSuccessDialog(transaction);
      } else if (cartProvider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${cartProvider.error}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate bill: ${e.toString()}')),
      );
    }
  }

  void _showBillSuccessDialog(Transaction transaction) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bill Generated Successfully'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bill ID: ${transaction.id ?? "N/A"}'),
            const SizedBox(height: 4),
            Text('Total Amount: ₹${transaction.totalAmount.toStringAsFixed(2)}'),
            const SizedBox(height: 4),
            Text('Payment Type: ${transaction.paymentType.toString().split('.').last}'),
            const SizedBox(height: 4),
            Text('Customer: ${transaction.customerName ?? "Walk-in customer"}'),
            const SizedBox(height: 4),
            Text('Items: ${transaction.items.length}'),
            const SizedBox(height: 4),
            Text('Status: ${transaction.isPaid ? "Paid" : "Unpaid"}'),
            const SizedBox(height: 4),
            Text('Date: ${transaction.createdAt ?? DateTime.now().toString().split('.')[0]}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              // Simulate sending bill via SMS/WhatsApp
              print('SENDING BILL TO CUSTOMER:');
              print('Bill ID: ${transaction.id}');
              print('Customer: ${transaction.customerName ?? "Walk-in customer"}');
              print('Amount: ₹${transaction.totalAmount.toStringAsFixed(2)}');
              print('Items:');
              for (var item in transaction.items) {
                print('- ${item.product.name} x ${item.quantity} = ₹${item.totalPrice.toStringAsFixed(2)}');
              }
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bill sent to customer (simulated)')),
              );
              Navigator.of(ctx).pop();
            },
            child: const Text('Send Bill'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing'),
      ),
      body: _isLoading && _customers.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Barcode scanner section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _barcodeController,
                          decoration: const InputDecoration(
                            labelText: 'Enter Barcode',
                            border: OutlineInputBorder(),
                            hintText: 'Scan or enter product barcode',
                          ),
                          onSubmitted: (_) => _scanBarcode(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _scanBarcode,
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Scan'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Cart items
                Expanded(
                  child: Consumer<CartProvider>(
                    builder: (context, cart, child) {
                      if (cart.items.isEmpty) {
                        return const Center(
                          child: Text('Cart is empty. Scan products to add.'),
                        );
                      }
                      
                      return ListView.builder(
                        itemCount: cart.items.length,
                        itemBuilder: (context, index) {
                          final item = cart.items[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              title: Text(item.product.name),
                              subtitle: Text(
                                'Qty: ${item.quantity} x ₹${item.product.price.toStringAsFixed(2)} = ₹${item.totalPrice.toStringAsFixed(2)}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (item.discount > 0)
                                    Chip(
                                      label: Text('-${item.discount.toStringAsFixed(0)}%'),
                                      backgroundColor: Colors.red.shade100,
                                      labelStyle: TextStyle(color: Colors.red.shade800),
                                    ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _showItemEditDialog(context, item, index),
                                    tooltip: 'Edit',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      cart.removeItem(item.product.id!);
                                    },
                                    tooltip: 'Remove',
                                  ),
                                ],
                              ),
                              onTap: () => _showItemEditDialog(context, item, index),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                
                // Bill details and checkout section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Consumer<CartProvider>(
                    builder: (context, cart, child) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Bill summary
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Bill Summary',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Total: ₹${cart.total.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
                          // Subtotal and discount
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Subtotal:'),
                              Text('₹${cart.subtotal.toStringAsFixed(2)}'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Discount:'),
                              Text('- ₹${cart.discount.toStringAsFixed(2)}'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Customer and payment selection
                          Row(
                            children: [
                              // Customer dropdown
                              Expanded(
                                child: DropdownButtonFormField<Customer>(
                                  decoration: const InputDecoration(
                                    labelText: 'Customer',
                                    border: OutlineInputBorder(),
                                  ),
                                  value: _selectedCustomer,
                                  items: _customers.map((customer) {
                                    return DropdownMenuItem<Customer>(
                                      value: customer,
                                      child: Text(customer.name),
                                    );
                                  }).toList(),
                                  onChanged: (customer) {
                                    setState(() {
                                      _selectedCustomer = customer;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              
                              // Payment method dropdown
                              Expanded(
                                child: DropdownButtonFormField<PaymentType>(
                                  decoration: const InputDecoration(
                                    labelText: 'Payment Method',
                                    border: OutlineInputBorder(),
                                  ),
                                  value: cart.paymentType,
                                  items: PaymentType.values.map((type) {
                                    return DropdownMenuItem<PaymentType>(
                                      value: type,
                                      child: Text(type.toString().split('.').last),
                                    );
                                  }).toList(),
                                  onChanged: (type) {
                                    if (type != null) {
                                      cart.setPaymentType(type);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Checkout button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: cart.itemCount > 0 ? _generateBill : null,
                              child: Text(
                                'Generate Bill (${cart.itemCount} items)',
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
