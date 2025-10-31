// API Configuration
class ApiConfig {
  static const String baseUrl = 'http://127.0.0.1:8001';
  static const bool useAuth = true; // Enforce auth for full app
  
  // Auth Endpoints
  static const String login = '/auth/json-login';
  static const String register = '/auth/register';
  static const String logout = '/api/logout';
  static const String me = '/users/me';
  
  // Product Endpoints (main API)
  static const String products = '/api/products';
  static String productById(int id) => '/api/products/$id';
  
  // Inventory Endpoints (main API)
  static const String inventory = '/api/inventory';
  static String inventoryById(int id) => '/api/inventory/$id';
  
  // Sales Endpoints
  static const String sales = '/api/sales';
  static String saleById(int id) => '/api/sales/$id';
  
  // Customer Endpoints
  static const String customers = '/api/customers';
  static String customerById(int id) => '/api/customers/$id';
  
  // Category Endpoints
  static const String categories = '/api/categories';
  static String categoryById(int id) => '/api/categories/$id';
  
  // Reports Endpoints
  static const String aiInsights = '/api/reports/ai-insights';
  
  static const int timeout = 30000; // 30 seconds
}
