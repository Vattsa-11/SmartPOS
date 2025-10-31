import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/user.dart';
import '../models/shop.dart';
import '../services/supabase_config.dart';

class AuthProvider extends ChangeNotifier {
  final _client = SupabaseConfig.client;
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Check if user is logged in
  bool get isLoggedIn => _client.auth.currentUser != null;

  // Register user
  Future<bool> register(User user, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('Starting registration for email: ${user.email}');
      
      // Check if this email already exists by trying to sign in with provided credentials
      try {
        final signInResponse = await _client.auth.signInWithPassword(
          email: user.email.toLowerCase().trim(),
          password: password,
        );
        
        // If sign in succeeds, user exists with this email and password
        if (signInResponse.user != null) {
          // Get user metadata to check owner name
          final userData = signInResponse.user!.userMetadata;
          final existingOwnerName = userData?['owner_name']?.toString() ?? '';
          
          // Check if ALL details match: email (already verified), password (already verified), and owner name
          if (existingOwnerName.toLowerCase() == user.ownerName.toLowerCase()) {
            // All details match - same owner trying to add another shop
            
            // Sign out the temporary session since we're not actually logging in
            await _client.auth.signOut();
            
            // Check if shop name already exists for this owner
            try {
              // Get existing shops for this user
              final existingShops = await _client
                  .from('shops')
                  .select('shop_name')
                  .eq('owner_id', signInResponse.user!.id);
              
              final shopExists = existingShops.any((shop) => 
                shop['shop_name'].toString().toLowerCase() == user.shopName.toLowerCase());
              
              if (shopExists) {
                _error = 'You already have a shop named "${user.shopName}".\n\n' +
                         'Please log in with your existing credentials to manage your shops, ' +
                         'or choose a different shop name.';
              } else {
                _error = 'You already have an account with this email.\n\n' +
                         'To add "${user.shopName}" as a new shop:\n' +
                         '1. Log in with your existing credentials\n' +
                         '2. Go to your dashboard\n' +
                         '3. Add the new shop from there\n\n' +
                         'Or use the "Create New Shop" option after logging in.';
              }
            } catch (shopCheckError) {
              // If we can't check shops, give general message
              _error = 'You already have an account with this email.\n\n' +
                       'Please log in with your existing credentials to add new shops.';
            }
            
            return false;
          } else {
            // Email and password match but different owner name
            // This suggests incorrect data entry
            await _client.auth.signOut(); // Clean up the temporary session
            
            _error = 'This email is already registered with a different owner name.\n\n' +
                     'Please check that you have entered the correct:\n' +
                     '• Owner Name\n' +
                     '• Email Address\n' +
                     '• Password\n\n' +
                     'If this is your account, make sure all details match exactly ' +
                     'what you used during your first registration.';
            return false;
          }
        }
      } catch (signInError) {
        // Sign in failed - this could mean:
        // 1. User doesn't exist (continue with registration)
        // 2. Wrong password (show error)
        // 3. Network/other error
        
        final errorMessage = signInError.toString().toLowerCase();
        
        if (errorMessage.contains('invalid login credentials') || 
            errorMessage.contains('invalid_credentials')) {
          // Email exists but password is wrong
          _error = 'This email is already registered.\n\n' +
                   'Please check that you have entered the correct:\n' +
                   '• Email Address\n' +
                   '• Password\n' +
                   '• Owner Name\n\n' +
                   'If this is your account, make sure all details match exactly. ' +
                   'If you forgot your password, please use the password reset option.';
          return false;
        } else if (errorMessage.contains('email not confirmed')) {
          // Email exists but not verified
          _error = 'An account with this email exists but is not verified.\n\n' +
                   'Please check your email for the verification link, ' +
                   'or try logging in to resend the verification email.';
          return false;
        }
        
        // For other errors, continue with new user registration
        print('Sign in failed (user likely does not exist): $signInError');
        print('Proceeding with new user registration');
      }
      
      // If we reach here, either:
      // 1. User doesn't exist - proceed with registration
      // 2. Other non-credential error - proceed with registration
      
      // Create new user in auth
      final AuthResponse res = await _client.auth.signUp(
        email: user.email.toLowerCase().trim(),
        password: password,
        data: {
          'phone': user.phone,
          'shop_name': user.shopName,
          'owner_name': user.ownerName,
          'full_name': user.ownerName, // Use owner name as full name (displayed in auth dashboard)
          'display_name': user.ownerName, // Use owner name as display name
          'username': user.ownerName, // Also set as username for consistency
        }
      );

      if (res.user == null) {
        throw Exception('Failed to create account');
      }

      // Don't try to create profile during registration
      // Profile will be created during first login after email verification
      print('Profile creation will happen during first login after email verification');

      print('User registered successfully, waiting for email verification');
      _error = 'Registration successful!\n\n' +
               'Please check your email to verify your account.\n' +
               'After verifying your email, you can log in with your email and password.';
      return false;

    } catch (e) {
      print('Registration error: $e');
      if (e.toString().contains('User already registered')) {
        _error = 'This email is already registered. Please check your details and try logging in instead.';
      } else if (e.toString().contains('Password should be at least 6 characters')) {
        _error = 'Password must be at least 6 characters';
      } else if (e.toString().contains('phone number already registered')) {
        _error = 'This phone number is already registered. Please use a different number.';
      } else {
        _error = 'Registration failed: ${e.toString()}';
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login user
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('Attempting login for email: ${email}');

      // Try to sign in
      final AuthResponse res = await _client.auth.signInWithPassword(
        email: email.toLowerCase().trim(),
        password: password,
      );

      if (res.user == null) {
        throw Exception('Invalid credentials');
      }

      // Check if email is confirmed
      if (res.user?.emailConfirmedAt == null) {
        print('Email not confirmed yet');
        _error = 'Please verify your email address before logging in.\n' +
                'Check your inbox for the verification link.';
        return false;
      }

      print('Login successful, getting/creating user profile');
      // Try to get or create profile
      try {
        await getUserProfile();
      } catch (profileError) {
        print('No profile found, creating one with metadata: ${res.user!.userMetadata}');
        // Create profile if it doesn't exist
        try {
          final metadata = res.user!.userMetadata ?? {};
          print('Creating profile with user metadata: $metadata');
          
          // Try new schema first (with owner_name column)
          try {
            final profileData = {
              'id': res.user!.id,
              'email': res.user!.email,
              'phone': metadata['phone']?.toString() ?? '',
              'owner_name': metadata['owner_name']?.toString() ?? 
                          metadata['display_name']?.toString() ?? '',
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            };
            
            print('Profile data to insert (new schema): $profileData');
            await _client.from('profiles').insert(profileData);
            print('Profile created successfully with new schema');
          } catch (newSchemaError) {
            print('New schema failed, trying old schema: $newSchemaError');
            
            // Fallback to old schema (with shop_name column)
            final profileDataOld = {
              'id': res.user!.id,
              'email': res.user!.email,
              'phone': metadata['phone']?.toString() ?? '',
              'shop_name': metadata['shop_name']?.toString() ?? '',
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            };
            
            print('Profile data to insert (old schema): $profileDataOld');
            await _client.from('profiles').insert(profileDataOld);
            print('Profile created successfully with old schema');
            
            // Don't try to create shops if using old schema
            await getUserProfile();
            print('Profile retrieved after creation (old schema)');
            return true;
          }
          
          print('Profile created successfully with new schema');
          
          // Create the first shop automatically from registration data
          final shopName = metadata['shop_name']?.toString();
          if (shopName != null && shopName.isNotEmpty) {
            try {
              print('Creating first shop: $shopName');
              final shopData = {
                'owner_id': res.user!.id,
                'shop_name': shopName,
                'is_active': true,
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              };
              
              final shopResult = await _client
                  .from('shops')
                  .insert(shopData)
                  .select()
                  .single();
              
              print('First shop created successfully: ${shopResult['id']}');
              
              // Set this as the current shop
              await _client
                  .from('user_sessions')
                  .upsert({
                    'user_id': res.user!.id,
                    'current_shop_id': shopResult['id'],
                    'updated_at': DateTime.now().toIso8601String(),
                  });
              
              print('Shop set as current shop');
            } catch (shopError) {
              print('Error creating first shop: $shopError');
              // Don't fail login if shop creation fails
            }
          }
          
          // Get the newly created profile
          await getUserProfile();
          print('Profile retrieved after creation');
        } catch (createError) {
          print('Error creating profile: $createError');
          print('Error details: ${createError.toString()}');
          _error = 'Error setting up user profile: ${createError.toString()}';
          return false;
        }
      }

      return true;
    } catch (e) {
      print('Login error: $e');
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('invalid login credentials')) {
        _error = 'Invalid email or password';
      } else if (errorStr.contains('email not confirmed')) {
        _error = 'Please verify your email before logging in.\n' +
                'Check your inbox for the verification link.';
      } else {
        _error = 'Login failed: $e';
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get user profile
  Future<void> getUserProfile() async {
    try {
      final authUser = _client.auth.currentUser;
      if (authUser == null) {
        print('No authenticated user found');
        throw Exception('Not authenticated');
      }

      print('Getting profile for user ID: ${authUser.id}');
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', authUser.id)
          .single();

      print('Profile data: $data');
      
      // Get current shop selection from user sessions
      String? currentShopId;
      String? currentShopName;
      try {
        final sessionData = await _client
            .from('user_sessions')
            .select('current_shop_id')
            .eq('user_id', authUser.id)
            .maybeSingle();
        
        if (sessionData != null && sessionData['current_shop_id'] != null) {
          currentShopId = sessionData['current_shop_id'];
          
          // Get shop name
          final shopData = await _client
              .from('shops')
              .select('shop_name')
              .eq('id', currentShopId)
              .maybeSingle();
          
          if (shopData != null) {
            currentShopName = shopData['shop_name'];
          }
        }
      } catch (sessionError) {
        print('Error getting session data: $sessionError');
        // Continue without current shop info
      }
      
      // First try profile data, then metadata, then empty string
      final ownerName = data['owner_name'] ?? authUser.userMetadata?['owner_name'] ?? '';
      final phone = data['phone'] ?? authUser.userMetadata?['phone'] ?? '';
      
      _currentUser = User(
        id: data['id'],
        email: data['email'] ?? authUser.email ?? '',
        phone: phone,
        ownerName: ownerName,
        currentShopId: currentShopId,
        currentShopName: currentShopName,
      );
      print('User profile loaded: ${_currentUser?.email}, current shop: $currentShopName');
      notifyListeners();
    } catch (e) {
      print('Get profile error: $e');
      throw e;
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      _isLoading = true;
      notifyListeners();
      await _client.auth.signOut();
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear any error messages
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Manual profile creation (for debugging)
  Future<bool> createProfileManually() async {
    try {
      final authUser = _client.auth.currentUser;
      if (authUser == null) {
        _error = 'No authenticated user found';
        return false;
      }

      print('Creating profile manually for user: ${authUser.id}');
      print('User metadata: ${authUser.userMetadata}');

      final metadata = authUser.userMetadata ?? {};
      final profileData = {
        'id': authUser.id,
        'email': authUser.email,
        'phone': metadata['phone']?.toString() ?? '',
        'shop_name': metadata['shop_name']?.toString() ?? '',
        'owner_name': metadata['owner_name']?.toString() ?? '',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      print('Profile data to create: $profileData');

      await _client.from('profiles').insert(profileData);
      print('Manual profile creation successful');

      // Get the profile
      await getUserProfile();
      return true;
    } catch (e) {
      print('Manual profile creation error: $e');
      _error = 'Failed to create profile: $e';
      notifyListeners();
      return false;
    }
  }

  // ===== Multi-Shop Management Methods =====

  // Get all shops for the current user
  Future<List<Shop>> getUserShops() async {
    try {
      final authUser = _client.auth.currentUser;
      if (authUser == null) {
        throw Exception('Not authenticated');
      }

      final data = await _client
          .from('shops')
          .select()
          .eq('owner_id', authUser.id)
          .eq('is_active', true)
          .order('created_at');

      return data.map<Shop>((json) => Shop.fromJson(json)).toList();
    } catch (e) {
      print('Error getting user shops: $e');
      throw Exception('Failed to load shops: $e');
    }
  }

  // Create a new shop
  Future<Shop> createShop({
    required String shopName,
    String? description,
    String? address,
  }) async {
    try {
      final authUser = _client.auth.currentUser;
      if (authUser == null) {
        throw Exception('Not authenticated');
      }

      final shopData = {
        'owner_id': authUser.id,
        'shop_name': shopName.trim(),
        'shop_description': description?.trim(),
        'address': address?.trim(),
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final data = await _client
          .from('shops')
          .insert(shopData)
          .select()
          .single();

      final newShop = Shop.fromJson(data);
      
      // If this is the user's first shop, automatically select it
      final userShops = await getUserShops();
      if (userShops.length == 1) {
        await selectCurrentShop(newShop);
      }

      return newShop;
    } catch (e) {
      print('Error creating shop: $e');
      throw Exception('Failed to create shop: $e');
    }
  }

  // Select current active shop
  Future<void> selectCurrentShop(Shop shop) async {
    try {
      final authUser = _client.auth.currentUser;
      if (authUser == null) {
        throw Exception('Not authenticated');
      }

      // Update user session with current shop
      await _client
          .from('user_sessions')
          .upsert({
            'user_id': authUser.id,
            'current_shop_id': shop.id,
            'updated_at': DateTime.now().toIso8601String(),
          });

      // Update current user with selected shop info
      _currentUser = _currentUser?.copyWith(
        currentShopId: shop.id,
        currentShopName: shop.shopName,
      );

      notifyListeners();
    } catch (e) {
      print('Error selecting shop: $e');
      throw Exception('Failed to select shop: $e');
    }
  }

  // Get current selected shop
  Future<Shop?> getCurrentShop() async {
    try {
      final authUser = _client.auth.currentUser;
      if (authUser == null || _currentUser?.currentShopId == null) {
        return null;
      }

      final data = await _client
          .from('shops')
          .select()
          .eq('id', _currentUser!.currentShopId!)
          .single();

      return Shop.fromJson(data);
    } catch (e) {
      print('Error getting current shop: $e');
      return null;
    }
  }

  // Check if user needs shop selection (has multiple shops but no current selection)
  Future<bool> needsShopSelection() async {
    try {
      final shops = await getUserShops();
      if (shops.isEmpty) {
        return true; // Need to create a shop
      }
      if (shops.length == 1) {
        // Auto-select the only shop
        await selectCurrentShop(shops.first);
        return false;
      }
      // Multiple shops - check if one is already selected
      return _currentUser?.currentShopId == null;
    } catch (e) {
      print('Error checking shop selection: $e');
      return true;
    }
  }

  // Sign out (alias for logout for consistency)
  Future<void> signOut() async {
    await logout();
  }

}
