import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as AppUser;
import '../services/supabase_config.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _client = SupabaseConfig.client;
  AppUser.User? _currentUser;
  bool _isLoading = false;
  String? _error;

  // Getters
  AppUser.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    // Listen to auth state changes
    _client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      
      print('**** onAuthStateChange: $event');
      print(session?.toJson() ?? 'No session');
      
      if (event == AuthChangeEvent.signedIn && session?.user != null) {
        _handleAuthSuccess(session!.user);
      } else if (event == AuthChangeEvent.signedOut) {
        _handleSignOut();
      }
    });

    // Check if user is already logged in
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    final session = _client.auth.currentSession;
    if (session?.user != null) {
      await _handleAuthSuccess(session!.user);
    }
  }

  Future<void> _handleAuthSuccess(User authUser) async {
    try {
      print('Getting profile for user ID: ${authUser.id}');
      
      // Get user profile from Supabase
      final response = await _client
          .from('profiles')
          .select('*')
          .eq('id', authUser.id)
          .single();
      
      _currentUser = AppUser.User(
        id: authUser.id,
        email: response['email'],
        ownerName: response['owner_name'] ?? '',
        phone: response['phone'] ?? '',
      );
      
      _isLoading = false;
      _error = null;
      notifyListeners();
      
    } catch (e) {
      print('Get profile error: $e');
      
      // If profile doesn't exist, create it
      if (e.toString().contains('0 rows') || e.toString().contains('PGRST116')) {
        await _createUserProfile(authUser);
      } else {
        _error = 'Error loading profile: $e';
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _createUserProfile(User authUser) async {
    try {
      final metadata = authUser.userMetadata ?? {};
      print('Creating profile with user metadata: $metadata');
      
      final profileData = {
        'id': authUser.id,
        'email': authUser.email ?? '',
        'owner_name': metadata['owner_name']?.toString() ?? 
                     metadata['display_name']?.toString() ?? 
                     metadata['full_name']?.toString() ?? '',
        'phone': metadata['phone']?.toString() ?? '',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      print('Profile data to insert: $profileData');
      await _client.from('profiles').insert(profileData);
      print('Profile created successfully');
      
      // Set current user
      _currentUser = AppUser.User(
        id: authUser.id,
        email: authUser.email ?? '',
        ownerName: profileData['owner_name'] as String,
        phone: profileData['phone'] as String,
      );
      
      _isLoading = false;
      _error = null;
      notifyListeners();
      
    } catch (createError) {
      print('Error creating profile: $createError');
      _error = 'Error creating profile: $createError';
      _isLoading = false;
      notifyListeners();
    }
  }

  void _handleSignOut() {
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  // Register new user
  Future<bool> register(AppUser.User user, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('Attempting registration for email: ${user.email}');
      
      // Create new user in auth
      final AuthResponse res = await _client.auth.signUp(
        email: user.email.toLowerCase().trim(),
        password: password,
        data: {
          'owner_name': user.ownerName,
          'full_name': user.ownerName, // Standard field for display
          'display_name': user.ownerName,
          'username': user.ownerName,
          'phone': user.phone,
        }
      );

      if (res.user == null) {
        throw Exception('Failed to create account');
      }

      print('User registered successfully, waiting for email verification');
      
      _isLoading = false;
      notifyListeners();
      return true;
      
    } catch (e) {
      print('Registration error: $e');
      _error = 'Registration failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Login user
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('Attempting login for email: $email');
      
      final AuthResponse res = await _client.auth.signInWithPassword(
        email: email.toLowerCase().trim(),
        password: password,
      );

      if (res.user == null) {
        throw Exception('Login failed');
      }

      print('Login successful, getting user profile');
      // Profile will be loaded by the auth state change listener
      
      return true;
      
    } catch (e) {
      print('Login error: $e');
      _error = 'Login failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      await _client.auth.signOut();
      _currentUser = null;
      _error = null;
      notifyListeners();
    } catch (e) {
      print('Logout error: $e');
      _error = 'Logout failed: ${e.toString()}';
      notifyListeners();
    }
  }

  // Update user profile
  Future<bool> updateProfile(String ownerName, String phone) async {
    if (_currentUser == null) return false;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updateData = {
        'owner_name': ownerName,
        'phone': phone,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _client
          .from('profiles')
          .update(updateData)
          .eq('id', _currentUser!.id);

      // Update local user data
      _currentUser = AppUser.User(
        id: _currentUser!.id,
        email: _currentUser!.email,
        ownerName: ownerName,
        phone: phone,
      );

      _isLoading = false;
      notifyListeners();
      return true;
      
    } catch (e) {
      print('Update profile error: $e');
      _error = 'Failed to update profile: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _client.auth.resetPasswordForEmail(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Reset password error: $e');
      _error = 'Failed to send reset email: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}