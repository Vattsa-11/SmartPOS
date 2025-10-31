import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/shop.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';

class ShopSelectionScreen extends StatefulWidget {
  final List<Shop> availableShops;
  final User user;

  const ShopSelectionScreen({
    Key? key,
    required this.availableShops,
    required this.user,
  }) : super(key: key);

  @override
  State<ShopSelectionScreen> createState() => _ShopSelectionScreenState();
}

class _ShopSelectionScreenState extends State<ShopSelectionScreen> {
  Shop? selectedShop;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Pre-select the first shop if available
    if (widget.availableShops.isNotEmpty) {
      selectedShop = widget.availableShops.first;
    }
  }

  Future<void> _selectShop() async {
    if (selectedShop == null) {
      setState(() {
        _errorMessage = 'Please select a shop to continue';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.selectCurrentShop(selectedShop!);
      
      // Navigate to dashboard after successful shop selection
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to select shop: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createNewShop() async {
    // Navigate to a screen to create a new shop
    final result = await Navigator.of(context).pushNamed('/create-shop');
    if (result != null && result is Shop) {
      setState(() {
        widget.availableShops.add(result);
        selectedShop = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Shop'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    'Welcome, ${widget.user.ownerName}!',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You have multiple shops. Please select which shop you\'d like to manage.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Shop selection
            Text(
              'Available Shops (${widget.availableShops.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Shop list
            Expanded(
              child: widget.availableShops.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.store_outlined,
                            size: 64,
                            color: Theme.of(context).disabledColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No shops found',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your first shop to get started',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: widget.availableShops.length,
                      itemBuilder: (context, index) {
                        final shop = widget.availableShops[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: RadioListTile<Shop>(
                            title: Text(
                              shop.shopName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (shop.shopDescription?.isNotEmpty == true)
                                  Text(shop.shopDescription!),
                                if (shop.address?.isNotEmpty == true)
                                  Text(
                                    'Address: ${shop.address}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                Text(
                                  'Created: ${_formatDate(shop.createdAt)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            value: shop,
                            groupValue: selectedShop,
                            onChanged: (Shop? value) {
                              setState(() {
                                selectedShop = value;
                                _errorMessage = null;
                              });
                            },
                            secondary: shop.isActive
                                ? const Icon(Icons.store, color: Colors.green)
                                : const Icon(Icons.store_outlined, color: Colors.grey),
                          ),
                        );
                      },
                    ),
            ),

            // Error message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _createNewShop,
                    icon: const Icon(Icons.add),
                    label: const Text('Create New Shop'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _selectShop,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_forward),
                    label: Text(_isLoading ? 'Loading...' : 'Continue'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}