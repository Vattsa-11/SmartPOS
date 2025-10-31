import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  
  User? _user;
  bool _isLoading = false;
  String? _error;
  
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  
  // Load user on app start
  Future<void> loadUser() async {
    _user = await _authService.getUser();
    notifyListeners();
  }
  
  // Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _apiService.login(email, password);
      
      // Save token (or dummy token in no-auth mode)
      await _authService.setToken(response['access_token'] ?? 'dummy-token');
      
      // Save user
      _user = User.fromJson(response['user']);
      await _authService.setUser(_user!);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Register
  Future<bool> register(Map<String, dynamic> userData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _apiService.register(userData);
      
      // Save token
      await _authService.setToken(response['access_token']);
      
      // Save user
      _user = User.fromJson(response['user']);
      await _authService.setUser(_user!);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Logout
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }
  
  // Refresh user data from API
  Future<void> refreshUser() async {
    try {
      final userData = await _apiService.getCurrentUser();
      _user = userData;
      await _authService.setUser(_user!);
      notifyListeners();
    } catch (e) {
      print('Error refreshing user: $e');
    }
  }
  
  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
