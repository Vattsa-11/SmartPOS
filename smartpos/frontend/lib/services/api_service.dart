import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/customer.dart';
import 'auth_service.dart';

class ApiService {
  final AuthService _authService = AuthService();
  
  // Test backend connection
  Future<bool> testConnection() async {
    try {
      print('🔍 Testing backend connection to ${ApiConfig.baseUrl}...');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        print('✅ Backend connected successfully! Status: ${response.statusCode}');
        return true;
      } else {
        print('⚠️ Backend responded with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Backend connection failed: $e');
      print('❌ Make sure backend is running at ${ApiConfig.baseUrl}');
      return false;
    }
  }
  
  // Get user ID for query parameters
  Future<String?> _getUserId() async {
    final user = await _authService.getUser();
    final userId = user?.id;
    print('🔑 Getting user ID: $userId (user: ${user?.email})');
    return userId;
  }
  
  // Generic request wrapper
  Future<dynamic> _request(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? body,
    Map<String, String>? customHeaders,
    Map<String, dynamic>? queryParams,
  }) async {
    // Get user ID for authentication header
    final userId = await _getUserId();
    
    print('📋 Request params for $endpoint: $queryParams');
    
    // Build URL with query parameters
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final url = queryParams != null && queryParams.isNotEmpty
        ? uri.replace(queryParameters: queryParams.map((k, v) => MapEntry(k, v.toString())))
        : uri;
    
    print('🌐 Full URL: $url');
    
    final headers = {
      'Content-Type': 'application/json',
      if (userId != null) 'x-user-id': userId.toString(),  // Add user ID header
      ...await _authService.getAuthHeader(),
      if (customHeaders != null) ...customHeaders,
    };
    
    // Log request
    if (method != 'GET') {
      print('🌐 $method $endpoint ${body != null ? jsonEncode(body) : ''}');
    }
    
    http.Response response;
    
    try {
      switch (method) {
        case 'GET':
          response = await http.get(url, headers: headers);
          break;
        case 'POST':
          response = await http.post(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(url, headers: headers);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }
      
      // Handle 401 - Unauthorized
      if (response.statusCode == 401) {
        final data = jsonDecode(response.body);
        final detail = data['detail'] ?? '';
        
        // If credentials are invalid, logout
        if (detail.contains('validate credentials')) {
          print('Invalid or expired token. Logging out...');
          await _authService.logout();
          throw Exception('Session expired. Please login again.');
        }
        
        throw Exception(detail.isNotEmpty ? detail : 'Unauthorized');
      }
      
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : null;
      
      if (response.statusCode < 200 || response.statusCode >= 300) {
        print('❌ API Error Response (${response.statusCode}): $data');
        final errorMsg = (data is Map)
            ? (data['detail'] ?? data['message'] ?? 'Request failed')
            : 'Request failed';
        throw Exception(errorMsg);
      }
      
      return data;
    } catch (e) {
      print('API Error: $e');
      rethrow;
    }
  }
  
  // Auth APIs
  Future<Map<String, dynamic>> login(String email, String password) async {
    return await _request(
      ApiConfig.login,
      method: 'POST',
      body: {
        'email': email,
        'password': password,
      },
    );
  }
  
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    return await _request(
      ApiConfig.register,
      method: 'POST',
      body: userData,
    );
  }
  
  Future<User> getCurrentUser() async {
    try {
      final data = await _request(ApiConfig.me);
      return User.fromJson(data);
    } catch (e) {
      // Fallback: return cached user if profile endpoint is not available
      final cached = await _authService.getUser();
      if (cached != null) return cached;
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> updateUpiSettings(int userId, String upiId, String? upiQrUrl) async {
    return await _request(
      '/users/$userId/upi-settings',
      method: 'PUT',
      body: {
        'upi_id': upiId,
        if (upiQrUrl != null) 'upi_qr_url': upiQrUrl,
      },
    );
  }
  
  Future<Map<String, dynamic>> uploadUpiQr(int userId, String filePath) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/upload-qr');
    final request = http.MultipartRequest('POST', uri);
    
    // Add authorization header
    final token = await _authService.getToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    
    // Add file
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    
    // Add auth headers including user ID
    final authHeaders = await _authService.getAuthHeader();
    request.headers.addAll(authHeaders);
    request.headers['x-user-id'] = userId.toString();
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to upload QR: ${response.body}');
    }
  }
  
  // Web-compatible upload using bytes instead of file path
  Future<Map<String, dynamic>> uploadUpiQrBytes(int userId, List<int> bytes, String filename) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/upload-qr');
    final request = http.MultipartRequest('POST', uri);
    
    // Add file from bytes
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: filename,
    ));
    
    // Add user_id as form field
    request.fields['user_id'] = userId.toString();
    
    // Add auth headers including user ID
    final authHeaders = await _authService.getAuthHeader();
    request.headers.addAll(authHeaders);
    request.headers['x-user-id'] = userId.toString();
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to upload QR: ${response.body}');
    }
  }
  
  // Product APIs
  Future<List<Product>> getProducts() async {
    final data = await _request(ApiConfig.products);
    return (data as List).map((p) => Product.fromJson(p)).toList();
  }
  
  Future<Product> getProduct(int id) async {
    final data = await _request(ApiConfig.productById(id));
    return Product.fromJson(data);
  }
  
  Future<Product> createProduct(Product product) async {
    final data = await _request(
      ApiConfig.products,
      method: 'POST',
      body: product.toJson(),
    );
    return Product.fromJson(data);
  }
  
  Future<Product> updateProduct(int id, Product product) async {
    final data = await _request(
      ApiConfig.productById(id),
      method: 'PUT',
      body: product.toJson(),
    );
    return Product.fromJson(data);
  }
  
  Future<void> deleteProduct(int id) async {
    await _request(
      ApiConfig.productById(id),
      method: 'DELETE',
    );
  }
  
  // Inventory APIs
  Future<List<Product>> getInventory() async {
    final data = await _request(ApiConfig.inventory);
    return (data as List).map((p) => Product.fromJson(p)).toList();
  }
  
  Future<Product> updateInventory(int id, Map<String, dynamic> inventoryData) async {
    final data = await _request(
      ApiConfig.inventoryById(id),
      method: 'PUT',
      body: inventoryData,
    );
    return Product.fromJson(data);
  }
  
  // Sales APIs
  Future<List<Sale>> getSales() async {
    final data = await _request(ApiConfig.sales);
    return (data as List).map((s) => Sale.fromJson(s)).toList();
  }
  
  Future<Sale> getSale(int id) async {
    final data = await _request(ApiConfig.saleById(id));
    return Sale.fromJson(data);
  }
  
  Future<Sale> createSale(Sale sale) async {
    final data = await _request(
      ApiConfig.sales,
      method: 'POST',
      body: sale.toJson(),
    );
    return Sale.fromJson(data);
  }
  
  // Customer APIs
  Future<List<Customer>> getCustomers({int? userId, String? search}) async {
    final queryParams = <String, dynamic>{};
    if (userId != null) queryParams['user_id'] = userId;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    final data = await _request(ApiConfig.customers, queryParams: queryParams);
    return (data as List).map((c) => Customer.fromJson(c)).toList();
  }
  
  Future<Customer> getCustomer(int customerId, int userId) async {
    final data = await _request(
      '/customers/$customerId',
      queryParams: {'user_id': userId},
    );
    return Customer.fromJson(data);
  }
  
  Future<Customer> createCustomer({
    required int userId,
    required String name,
    required String phone,
    required String email,
    required String address,
    required String customerType,
    required double creditLimit,
  }) async {
    final data = await _request(
      ApiConfig.customers,
      method: 'POST',
      body: {
        'user_id': userId,
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'customer_type': customerType,
        'credit_limit': creditLimit,
      },
    );
    return Customer.fromJson(data);
  }
  
  Future<Customer> updateCustomer({
    required int customerId,
    required int userId,
    required String name,
    required String phone,
    required String email,
    required String address,
    required String customerType,
    required double creditLimit,
  }) async {
    final data = await _request(
      '/customers/$customerId',
      method: 'PUT',
      queryParams: {'user_id': userId},
      body: {
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'customer_type': customerType,
        'credit_limit': creditLimit,
      },
    );
    return Customer.fromJson(data);
  }
  
  Future<void> deleteCustomer({
    required int customerId,
    required int userId,
  }) async {
    await _request(
      '/customers/$customerId',
      method: 'DELETE',
      queryParams: {'user_id': userId},
    );
  }
  
  // Category APIs
  Future<List<Map<String, dynamic>>> getCategories() async {
    final data = await _request(ApiConfig.categories);
    return List<Map<String, dynamic>>.from(data);
  }
  
  Future<Map<String, dynamic>> createCategory(Map<String, dynamic> categoryData) async {
    return await _request(
      ApiConfig.categories,
      method: 'POST',
      body: categoryData,
    );
  }
  
  // Reports APIs
  Future<Map<String, dynamic>> generateAIInsights(Map<String, dynamic> reportData) async {
    return await _request(
      ApiConfig.aiInsights,
      method: 'POST',
      body: reportData,
    );
  }
}
