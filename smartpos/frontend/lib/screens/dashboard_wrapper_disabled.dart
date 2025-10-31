import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/routes.dart';
import 'dashboard_screen.dart';

class DashboardWrapper extends StatefulWidget {
  const DashboardWrapper({Key? key}) : super(key: key);

  @override
  State<DashboardWrapper> createState() => _DashboardWrapperState();
}

class _DashboardWrapperState extends State<DashboardWrapper> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkShopSelection();
  }

  Future<void> _checkShopSelection() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Check if user needs shop selection
      final needsShopSelection = await authProvider.needsShopSelection();
      
      if (needsShopSelection) {
        // Get user's shops
        final shops = await authProvider.getUserShops();
        final user = authProvider.currentUser;
        
        if (shops.isEmpty) {
          // No shops - navigate to create shop
          if (mounted) {
            Navigator.of(context).pushReplacementNamed(AppRoutes.createShop);
          }
          return;
        } else if (shops.length == 1) {
          // Only one shop - auto select it
          await authProvider.selectCurrentShop(shops.first);
        } else {
          // Multiple shops - show selection screen
          if (mounted) {
            Navigator.of(context).pushReplacementNamed(
              AppRoutes.shopSelection,
              arguments: {
                'shops': shops,
                'user': user,
              },
            );
          }
          return;
        }
      }
      
      // All good - can show dashboard
      setState(() {
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Setting up your workspace...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  await authProvider.signOut();
                  if (mounted) {
                    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
                  }
                },
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      );
    }

    // Show the actual dashboard
    return const DashboardScreen();
  }
}