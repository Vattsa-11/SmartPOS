import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:html' as html;
import '../providers/cart_provider.dart';
import '../providers/products_provider.dart';
import '../providers/auth_provider.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/sale.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../utils/helpers.dart';
import '../config/api_config.dart';
import '../widgets/barcode_scanner_widget.dart';

class BillingManagementScreen extends StatefulWidget {
  const BillingManagementScreen({super.key});

  @override
  State<BillingManagementScreen> createState() => _BillingManagementScreenState();
}

class _BillingManagementScreenState extends State<BillingManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductsProvider>(context, listen: false).fetchProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _barcodeController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing / POS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<ProductsProvider>(context, listen: false).fetchProducts();
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;
          
          if (isWide) {
            // Two-panel layout for wide screens
            return Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildProductSearch(),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  flex: 2,
                  child: _buildCart(),
                ),
              ],
            );
          } else {
            // Single panel with tabs for narrow screens
            return DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Products', icon: Icon(Icons.shopping_bag)),
                      Tab(text: 'Cart', icon: Icon(Icons.shopping_cart)),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildProductSearch(),
                        _buildCart(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildProductSearch() {
    return Consumer<ProductsProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            // Search Controls
            Container(
              color: AppColors.bgCard,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Manual Barcode Input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _barcodeController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Enter barcode or scan...',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            prefixIcon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
                            suffixIcon: _barcodeController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _barcodeController.clear();
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.grey[800],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onSubmitted: (barcode) {
                            _searchByBarcode(barcode);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Scan Button
                      ElevatedButton.icon(
                        onPressed: _openBarcodeScanner,
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Scan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Product Name Search
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search products by name...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                provider.setSearchQuery('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      provider.setSearchQuery(value);
                    },
                  ),
                ],
              ),
            ),
            
            // Product List
            Expanded(
              child: _buildProductList(provider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductList(ProductsProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Error: ${provider.error}',
              style: const TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => provider.fetchProducts(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final products = provider.products;

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'No products found',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(Product product) {
    final stock = product.stock ?? 0;
    final isLowStock = stock <= (product.minimumStock ?? 0);
    final isOutOfStock = stock == 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isOutOfStock ? AppColors.error : AppColors.primary,
          child: Icon(
            isOutOfStock ? Icons.not_interested : Icons.shopping_bag,
            color: Colors.white,
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.barcode != null)
              Text('Barcode: ${product.barcode}'),
            Text(
              'Stock: $stock ${product.unit ?? 'pcs'}',
              style: TextStyle(
                color: isLowStock ? AppColors.error : AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              Formatters.formatCurrency(product.sellingPrice),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            if (isOutOfStock)
              const Text(
                'Out of Stock',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        onTap: isOutOfStock
            ? null
            : () {
                _addToCart(product);
              },
      ),
    );
  }

  Widget _buildCart() {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 600;
        
        return Stack(
          children: [
            Column(
              children: [
                // Cart Header
                Container(
                  color: AppColors.primary,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_cart, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Cart (${cart.itemCount} items)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (cart.items.isNotEmpty)
                        TextButton.icon(
                          onPressed: () async {
                            final confirm = await Helpers.showConfirmDialog(
                              context,
                              title: 'Clear Cart',
                              message: 'Are you sure you want to clear the cart?',
                            );
                            if (confirm) {
                              cart.clearCart();
                            }
                          },
                          icon: const Icon(Icons.delete, color: Colors.white),
                          label: const Text(
                            'Clear',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Cart Items
                Expanded(
                  child: cart.items.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_cart_outlined,
                                size: 80,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Cart is empty',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add products to continue',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 16,
                            bottom: isMobile ? 120 : 16, // Extra space for bottom sheet
                          ),
                          itemCount: cart.items.length,
                          itemBuilder: (context, index) {
                            final item = cart.items[index];
                            return _buildCartItem(item, cart);
                          },
                        ),
                ),
              ],
            ),
            
            // Draggable Bottom Sheet for mobile
            if (cart.items.isNotEmpty && isMobile)
              Positioned.fill(
                child: _buildDraggableCheckoutSheet(context, cart),
              ),
            
            // Fixed summary for desktop
            if (cart.items.isNotEmpty && !isMobile)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildCartSummary(context, cart),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCartItem(CartItem item, CartProvider cart) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: Colors.grey[800],
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 8 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.product.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 13 : 15,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: AppColors.error),
                      onPressed: () {
                        cart.removeItem(item.product.id!);
                      },
                      iconSize: isMobile ? 18 : 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                
                SizedBox(height: isMobile ? 4 : 8),
                
                Text(
                  '${Formatters.formatCurrency(item.product.sellingPrice)}/${item.product.unit ?? 'pcs'}',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: isMobile ? 11 : 13,
                  ),
                ),
                
                SizedBox(height: isMobile ? 4 : 8),
                
                // Quantity Controls
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Qty:',
                      style: TextStyle(
                        fontSize: isMobile ? 11 : 13,
                        color: Colors.grey[300],
                      ),
                    ),
                    
                    // Check if product is weight-based
                    if (item.isWeightBased) ...[
                      // Show weight with unit for weight-based products
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 8 : 12,
                          vertical: isMobile ? 2 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary, // Changed from accent to primary for better contrast
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${item.quantity.toStringAsFixed(2)} ${item.product.unit}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 12 : 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      // Edit button for weight
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.grey[300]),
                        onPressed: () {
                          _showWeightEditDialog(item, cart);
                        },
                        iconSize: isMobile ? 18 : 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ] else ...[
                      // Show +/- buttons for count-based products
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline, color: Colors.grey[300]),
                        onPressed: () {
                          cart.updateQuantity(item.product.id!, item.quantity - 1);
                        },
                        iconSize: isMobile ? 18 : 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 8 : 12,
                          vertical: isMobile ? 2 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary, // Changed from accent to primary for better contrast
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${item.quantity.toInt()}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 12 : 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add_circle_outline, color: Colors.grey[300]),
                        onPressed: () {
                          final maxStock = item.product.stock ?? 0;
                          if (item.quantity < maxStock) {
                            cart.updateQuantity(item.product.id!, item.quantity + 1);
                          } else {
                            Helpers.showSnackBar(
                              context,
                              'Maximum stock reached',
                              isError: true,
                            );
                          }
                        },
                        iconSize: isMobile ? 18 : 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                    
                    // Discount Control
                    TextButton.icon(
                      onPressed: () {
                        _showDiscountDialog(item, cart);
                      },
                      icon: Icon(
                        Icons.discount,
                        size: isMobile ? 14 : 16,
                        color: Colors.grey[300],
                      ),
                      label: Text(
                        item.discount > 0 ? '${item.discount.toStringAsFixed(0)}% OFF' : 'Disc',
                        style: TextStyle(
                          fontSize: isMobile ? 10 : 12,
                          color: Colors.grey[300],
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 4 : 8,
                          vertical: isMobile ? 2 : 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                
                Divider(color: Colors.grey[600], height: isMobile ? 8 : 16),
                
                // Item Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total:',
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 14,
                        color: Colors.grey[400],
                      ),
                    ),
                    Text(
                      Formatters.formatCurrency(item.totalPrice),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 14 : 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDraggableCheckoutSheet(BuildContext context, CartProvider cart) {
    return DraggableScrollableSheet(
      initialChildSize: 0.15, // Start at 15% of screen height
      minChildSize: 0.15, // Minimum 15%
      maxChildSize: 0.85, // Maximum 85% when fully expanded
      snap: true,
      snapSizes: const [0.15, 0.5, 0.85], // Snap points
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag Handle
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Total Preview (visible when minimized)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: ${Formatters.formatCurrency(cart.total)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_up, color: Colors.grey[400]),
                  ],
                ),
              ),
              
              const Divider(height: 1, color: Colors.grey),
              
              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Customer Information (Optional)
                      Text(
                        'Customer Information (Optional)',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: Colors.grey[300],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _customerNameController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Customer Name',
                          labelStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
                          hintText: 'Enter customer name',
                          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
                          prefixIcon: const Icon(Icons.person_outline, color: Colors.grey, size: 20),
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey[800],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _customerPhoneController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        decoration: InputDecoration(
                          labelText: 'Customer Phone',
                          labelStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
                          hintText: 'Enter 10-digit phone',
                          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
                          prefixIcon: const Icon(Icons.phone_outlined, color: Colors.grey, size: 20),
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey[800],
                          counterText: '',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          isDense: true,
                        ),
                      ),
                      
                      const Divider(height: 20, color: Colors.grey),
                      
                      // Payment Method
                      Row(
                        children: [
                          Text(
                            'Payment:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: Colors.grey[300],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(
                                  value: 'Cash',
                                  label: Text('Cash', style: TextStyle(fontSize: 11)),
                                  icon: Icon(Icons.money, size: 16),
                                ),
                                ButtonSegment(
                                  value: 'UPI',
                                  label: Text('UPI', style: TextStyle(fontSize: 11)),
                                  icon: Icon(Icons.qr_code, size: 16),
                                ),
                              ],
                              selected: {cart.paymentMethod},
                              onSelectionChanged: (Set<String> selected) {
                                cart.setPaymentMethod(selected.first);
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      // Show QR Code for UPI payment
                      if (cart.paymentMethod == 'UPI') ...[
                        const SizedBox(height: 12),
                        Consumer<AuthProvider>(
                          builder: (context, authProvider, _) {
                            final user = authProvider.user;
                            if (user?.upiQrUrl != null && user!.upiQrUrl!.isNotEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey[900],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[700]!),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Scan to Pay',
                                      style: TextStyle(
                                        color: Colors.grey[300],
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        '${ApiConfig.baseUrl}${user.upiQrUrl}',
                                        height: 150,
                                        width: 150,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            height: 150,
                                            width: 150,
                                            color: Colors.grey[800],
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.error_outline, color: Colors.grey[500], size: 36),
                                                const SizedBox(height: 6),
                                                Text(
                                                  'QR not available',
                                                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    if (user.upiId != null && user.upiId!.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        user.upiId!,
                                        style: TextStyle(color: Colors.grey[400], fontSize: 11),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            } else {
                              return Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey[900],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange[700]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.orange[300], size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Upload UPI QR code in Settings',
                                        style: TextStyle(color: Colors.orange[300], fontSize: 11),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                        ),
                      ],
                      
                      const Divider(height: 20),
                      
                      // Summary Rows
                      _buildSummaryRow('Subtotal', cart.subtotal),
                      if (cart.totalDiscount > 0)
                        _buildSummaryRow('Discount', -cart.totalDiscount, color: AppColors.success),
                      if (cart.totalTax > 0)
                        _buildSummaryRow('Tax', cart.totalTax),
                      
                      const Divider(height: 12),
                      
                      _buildSummaryRow(
                        'Total',
                        cart.total,
                        isTotal: true,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Checkout Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: cart.isLoading ? null : () => _checkout(cart),
                          icon: cart.isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.payment, size: 20),
                          label: Text(
                            cart.isLoading ? 'Processing...' : 'Checkout',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCartSummary(BuildContext context, CartProvider cart) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final maxHeight = isMobile ? screenHeight * 0.4 : double.infinity;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxHeight,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Customer Information (Optional)
              Text(
                'Customer Information (Optional)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Colors.grey[300],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
            controller: _customerNameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Customer Name',
              labelStyle: TextStyle(color: Colors.grey[400]),
              hintText: 'Enter customer name',
              hintStyle: TextStyle(color: Colors.grey[500]),
              prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[800],
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _customerPhoneController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.phone,
            maxLength: 10,
            decoration: InputDecoration(
              labelText: 'Customer Phone',
              labelStyle: TextStyle(color: Colors.grey[400]),
              hintText: 'Enter 10-digit phone',
              hintStyle: TextStyle(color: Colors.grey[500]),
              prefixIcon: const Icon(Icons.phone_outlined, color: Colors.grey),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[800],
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          
          const Divider(height: 24, color: Colors.grey),
          
          // Payment Method
          Row(
            children: [
              const Text('Payment:', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(width: 12),
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'Cash', label: Text('Cash'), icon: Icon(Icons.money)),
                    ButtonSegment(value: 'UPI', label: Text('UPI'), icon: Icon(Icons.qr_code)),
                  ],
                  selected: {cart.paymentMethod},
                  onSelectionChanged: (Set<String> selected) {
                    cart.setPaymentMethod(selected.first);
                  },
                ),
              ),
            ],
          ),
          
          // Show QR Code for UPI payment
          if (cart.paymentMethod == 'UPI') ...[
            const SizedBox(height: 16),
            Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                final user = authProvider.user;
                if (user?.upiQrUrl != null && user!.upiQrUrl!.isNotEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[700]!),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Scan to Pay',
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            '${ApiConfig.baseUrl}${user.upiQrUrl}',
                            height: 200,
                            width: 200,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                width: 200,
                                color: Colors.grey[800],
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error_outline, color: Colors.grey[500], size: 48),
                                    const SizedBox(height: 8),
                                    Text('QR not available', style: TextStyle(color: Colors.grey[500])),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        if (user.upiId != null && user.upiId!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            user.upiId!,
                            style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  );
                } else {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[700]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange[300]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Upload UPI QR code in Settings',
                            style: TextStyle(color: Colors.orange[300], fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ],
          
          const Divider(height: 24),
          
          // Summary Rows
          _buildSummaryRow('Subtotal', cart.subtotal),
          if (cart.totalDiscount > 0)
            _buildSummaryRow('Discount', -cart.totalDiscount, color: AppColors.success),
          if (cart.totalTax > 0)
            _buildSummaryRow('Tax', cart.totalTax),
          
          const Divider(),
          
          _buildSummaryRow(
            'Total',
            cart.total,
            isTotal: true,
          ),
          
          const SizedBox(height: 16),
          
          // Checkout Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: cart.isLoading ? null : () => _checkout(cart),
              icon: cart.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.payment),
              label: Text(
                cart.isLoading ? 'Processing...' : 'Checkout',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.white,
            ),
          ),
          Text(
            Formatters.formatCurrency(amount),
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: color ?? (isTotal ? AppColors.accent : Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _addToCart(Product product) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    cart.addItem(product);
    Helpers.showSnackBar(context, '${product.name} added to cart');
  }

  void _searchByBarcode(String barcode) {
    if (barcode.isEmpty) return;
    
    final provider = Provider.of<ProductsProvider>(context, listen: false);
    final product = provider.searchByBarcode(barcode);
    
    if (product != null) {
      _addToCart(product);
      _barcodeController.clear();
    } else {
      Helpers.showSnackBar(
        context,
        'Product not found with barcode: $barcode',
        isError: true,
      );
    }
  }

  void _openBarcodeScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScannerWidget(
          onBarcodeDetected: (barcode) {
            _barcodeController.text = barcode;
            _searchByBarcode(barcode);
          },
        ),
      ),
    );
  }

  void _showDiscountDialog(CartItem item, CartProvider cart) {
    final TextEditingController discountController = TextEditingController(
      text: item.discount > 0 ? item.discount.toStringAsFixed(0) : '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Discount - ${item.product.name}'),
        content: TextField(
          controller: discountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Discount Percentage (%)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.discount),
            suffixText: '%',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final discount = double.tryParse(discountController.text) ?? 0;
              if (discount < 0 || discount > 100) {
                Helpers.showSnackBar(
                  context,
                  'Discount must be between 0 and 100',
                  isError: true,
                );
                return;
              }
              
              cart.updateDiscount(item.product.id!, discount);
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showWeightEditDialog(CartItem item, CartProvider cart) {
    final TextEditingController weightController = TextEditingController(
      text: item.quantity.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Weight - ${item.product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Price: ₹${item.product.price.toStringAsFixed(2)} per ${item.product.unit}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Weight (${item.product.unit})',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.scale),
                hintText: 'e.g., 2.5',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final weight = double.tryParse(weightController.text) ?? 0;
              if (weight <= 0) {
                Helpers.showSnackBar(
                  context,
                  'Please enter a valid weight',
                  isError: true,
                );
                return;
              }
              
              cart.updateQuantity(item.product.id!, weight);
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkout(CartProvider cart) async {
    // Get customer details from text fields
    final customerName = _customerNameController.text.trim();
    final customerPhone = _customerPhoneController.text.trim();
    
    final sale = await cart.checkout(
      customerName: customerName.isNotEmpty ? customerName : null,
      customerPhone: customerPhone.isNotEmpty ? customerPhone : null,
    );
    
    if (sale != null && mounted) {
      // Clear customer fields
      _customerNameController.clear();
      _customerPhoneController.clear();
      
      Helpers.showSnackBar(context, 'Sale completed successfully!');
      
      // Show invoice dialog
      _showInvoiceDialog(sale, cart);
    } else if (cart.error != null && mounted) {
      Helpers.showSnackBar(context, cart.error!, isError: true);
    }
  }

  void _showInvoiceDialog(dynamic sale, CartProvider cart) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.receipt_long, color: AppColors.success),
            SizedBox(width: 8),
            Text('Invoice'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Invoice #${sale.invoiceNumber ?? 'N/A'}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('Date: ${Formatters.formatDateTime(sale.saleDate ?? DateTime.now())}'),
              const Divider(height: 24),
              
              // Payment Method & UPI QR
              if (cart.paymentMethod == 'UPI') ...[
                const Text(
                  'Scan QR Code to Pay',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                // Show user's uploaded QR image if available
                if (user?.upiQrUrl != null && user!.upiQrUrl!.isNotEmpty)
                  Center(
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          '${ApiConfig.baseUrl}${user.upiQrUrl}',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildFallbackQR(user, sale);
                          },
                        ),
                      ),
                    ),
                  )
                // Fallback: Generate QR from UPI ID if available
                else if (user?.upiId != null && user!.upiId!.isNotEmpty)
                  _buildFallbackQR(user, sale)
                // Last resort: Show message to configure UPI
                else
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.qr_code_2, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          'UPI QR not configured',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Please upload QR in Settings',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
              ],
              
              Text('Payment Method: ${cart.paymentMethod}'),
              const Divider(height: 24),
              
              Text(
                'Total Amount: ${Formatters.formatCurrency(sale.totalAmount ?? 0)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              cart.clearLastSale();
              // Pop back to dashboard with refresh flag
              Navigator.pop(context, true); // true means refresh dashboard
            },
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              _printInvoice(sale, user);
            },
            icon: const Icon(Icons.print),
            label: const Text('Print'),
          ),
        ],
      ),
    );
  }
  
  void _printInvoice(Sale sale, user) {
    final invoiceHtml = '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <style>
        @media print {
          body { margin: 0; padding: 20px; }
        }
        body {
          font-family: 'Courier New', monospace;
          max-width: 300px;
          margin: 0 auto;
        }
        .header {
          text-align: center;
          border-bottom: 2px dashed #000;
          padding-bottom: 10px;
          margin-bottom: 10px;
        }
        .shop-name { font-size: 18px; font-weight: bold; }
        .info { font-size: 12px; }
        .invoice-details { margin: 10px 0; font-size: 12px; }
        .items {
          border-top: 1px dashed #000;
          border-bottom: 1px dashed #000;
          padding: 10px 0;
          margin: 10px 0;
        }
        .item-row {
          display: flex;
          justify-content: space-between;
          margin: 5px 0;
          font-size: 12px;
        }
        .totals {
          margin-top: 10px;
          font-size: 12px;
        }
        .total-row {
          display: flex;
          justify-content: space-between;
          margin: 3px 0;
        }
        .grand-total {
          font-size: 16px;
          font-weight: bold;
          border-top: 2px solid #000;
          padding-top: 5px;
          margin-top: 5px;
        }
        .footer {
          text-align: center;
          margin-top: 20px;
          padding-top: 10px;
          border-top: 2px dashed #000;
          font-size: 12px;
        }
      </style>
    </head>
    <body>
      <div class="header">
        <div class="shop-name">${user?.shopName ?? 'SmartPOS'}</div>
        <div class="info">${user?.ownerName ?? ''}</div>
        <div class="info">${user?.phone ?? ''}</div>
      </div>
      
      <div class="invoice-details">
        <div>Invoice: ${sale.invoiceNumber ?? 'N/A'}</div>
        <div>Date: ${DateTime.now().toString().substring(0, 19)}</div>
        <div>Customer: ${sale.customerName ?? 'Walk-in'}</div>
        ${sale.customerPhone != null ? '<div>Phone: ${sale.customerPhone}</div>' : ''}
        <div>Payment: ${sale.paymentMethod ?? 'Cash'}</div>
      </div>
      
      <div class="items">
        <div style="font-weight: bold; margin-bottom: 5px;">ITEMS</div>
        ${sale.items?.map((item) => '''
        <div class="item-row">
          <div style="flex: 2;">${item.productName}</div>
          <div>${item.quantity} x ${Formatters.formatCurrency(item.unitPrice ?? 0)}</div>
          <div>${Formatters.formatCurrency(item.totalPrice ?? 0)}</div>
        </div>
        ''').join('') ?? ''}
      </div>
      
      <div class="totals">
        <div class="total-row">
          <div>Subtotal:</div>
          <div>${Formatters.formatCurrency(sale.subtotal ?? 0)}</div>
        </div>
        ${(sale.discountAmount ?? 0) > 0 ? '''
        <div class="total-row">
          <div>Discount:</div>
          <div>-${Formatters.formatCurrency(sale.discountAmount ?? 0)}</div>
        </div>
        ''' : ''}
        ${(sale.taxAmount ?? 0) > 0 ? '''
        <div class="total-row">
          <div>Tax:</div>
          <div>${Formatters.formatCurrency(sale.taxAmount ?? 0)}</div>
        </div>
        ''' : ''}
        <div class="total-row grand-total">
          <div>TOTAL:</div>
          <div>${Formatters.formatCurrency(sale.totalAmount ?? 0)}</div>
        </div>
      </div>
      
      <div class="footer">
        Thank you for your business!<br>
        Visit Again
      </div>
      
      <script>
        window.onload = function() {
          window.print();
          setTimeout(function() {
            window.close();
          }, 100);
        };
      </script>
    </body>
    </html>
    ''';
    
    // Open print window with the invoice
    final blob = html.Blob([invoiceHtml], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
    html.Url.revokeObjectUrl(url);
  }
  
  Widget _buildFallbackQR(user, sale) {
    final upiString = 'upi://pay?pa=${user.upiId}&pn=${user.shopName}&am=${sale.totalAmount?.toStringAsFixed(2)}&cu=INR';
    return Center(
      child: QrImageView(
        data: upiString,
        version: QrVersions.auto,
        size: 200.0,
      ),
    );
  }
}
