import '../models/product.dart';
import '../models/inventory.dart';
import 'supabase_config.dart';

class SupabaseProductService {
  final _client = SupabaseConfig.client;

  // Get all products for the current user
  Future<List<Product>> getProducts() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _client
          .from('products')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return response.map<Product>((json) => Product.fromJson(json)).toList();
    } catch (e) {
      print('Error getting products: $e');
      rethrow;
    }
  }

  // Add a new product
  Future<Product> addProduct(Product product) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final productData = {
        'user_id': userId,
        'name': product.name,
        'barcode': product.barcode,
        'price': product.price,
        'category': product.category,
      };

      print('Adding product: $productData');

      final response = await _client
          .from('products')
          .insert(productData)
          .select()
          .single();

      print('Product added successfully: $response');
      return Product.fromJson(response);
    } catch (e) {
      print('Error adding product: $e');
      if (e.toString().contains('duplicate key value violates unique constraint')) {
        throw Exception('A product with this barcode already exists');
      }
      rethrow;
    }
  }

  // Update a product
  Future<Product> updateProduct(int id, Product product) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final productData = {
        'name': product.name,
        'barcode': product.barcode,
        'price': product.price,
        'category': product.category,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _client
          .from('products')
          .update(productData)
          .eq('id', id)
          .eq('user_id', userId)
          .select()
          .single();

      return Product.fromJson(response);
    } catch (e) {
      print('Error updating product: $e');
      rethrow;
    }
  }

  // Delete a product
  Future<void> deleteProduct(int id) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _client
          .from('products')
          .delete()
          .eq('id', id)
          .eq('user_id', userId);

      print('Product deleted successfully');
    } catch (e) {
      print('Error deleting product: $e');
      rethrow;
    }
  }

  // Add inventory for a product
  Future<void> addInventory(int productId, int quantity, int reorderLevel, {DateTime? expiryDate}) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final inventoryData = {
        'product_id': productId,
        'user_id': userId,
        'quantity': quantity,
        'reorder_level': reorderLevel,
        if (expiryDate != null) 'expiry_date': expiryDate.toIso8601String().split('T')[0],
      };

      print('Adding inventory: $inventoryData');

      await _client
          .from('inventory')
          .insert(inventoryData);

      print('Inventory added successfully');
    } catch (e) {
      print('Error adding inventory: $e');
      rethrow;
    }
  }

  // Update inventory
  Future<void> updateInventory(int productId, int quantity, {int? reorderLevel}) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final updateData = {
        'quantity': quantity,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (reorderLevel != null) {
        updateData['reorder_level'] = reorderLevel;
      }

      await _client
          .from('inventory')
          .update(updateData)
          .eq('product_id', productId)
          .eq('user_id', userId);

      print('Inventory updated successfully');
    } catch (e) {
      print('Error updating inventory: $e');
      rethrow;
    }
  }

  // Get inventory items
  Future<List<Inventory>> getInventory() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _client
          .from('inventory')
          .select('''
            *,
            products:product_id (
              id,
              name,
              barcode,
              price,
              category
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return response.map<Inventory>((json) {
        // Transform the data to match our Inventory model
        final productData = json['products'] as Map<String, dynamic>;
        final inventoryJson = {
          'id': json['id'],
          'product_id': json['product_id'],
          'quantity': json['quantity'],
          'reorder_level': json['reorder_level'],
          'expiry_date': json['expiry_date'],
          'created_at': json['created_at'],
          'updated_at': json['updated_at'],
          'product': productData,
        };
        return Inventory.fromJson(inventoryJson);
      }).toList();
    } catch (e) {
      print('Error getting inventory: $e');
      rethrow;
    }
  }

  // Search products by barcode
  Future<Product?> searchProductByBarcode(String barcode) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _client
          .from('products')
          .select()
          .eq('user_id', userId)
          .eq('barcode', barcode)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return Product.fromJson(response);
    } catch (e) {
      print('Error searching product by barcode: $e');
      rethrow;
    }
  }
}