import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  static const String _tokenKey = 'smartpos_token';
  static const String _userKey = 'smartpos_user';
  
  // Get stored token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
  
  // Set token
  Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }
  
  // Remove token
  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
  
  // Get stored user
  Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_userKey);
    if (userStr == null) return null;
    
    try {
      final userJson = json.decode(userStr);
      return User.fromJson(userJson);
    } catch (e) {
      return null;
    }
  }
  
  // Set user
  Future<void> setUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = json.encode(user.toJson());
    await prefs.setString(_userKey, userStr);
  }
  
  // Remove user
  Future<void> removeUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }
  
  // Check if authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
  
  // Logout
  Future<void> logout() async {
    await removeToken();
    await removeUser();
  }
  
  // Get auth header
  Future<Map<String, String>> getAuthHeader() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return {};
    return {'Authorization': 'Bearer $token'};
  }
  
  // Get user ID header
  Future<Map<String, String>> getUserIdHeader() async {
    final user = await getUser();
    if (user == null) return {};
    return {'x-user-id': user.id.toString()};
  }

  // Legacy method for compatibility
  Future<void> clearToken() async {
    await removeToken();
  }
  
  // Legacy method for compatibility
  Future<void> saveToken(String token) async {
    await setToken(token);
  }
}
