
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/products_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/cart_provider.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'utils/routes.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/api_service.dart';
import 'config/api_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Test backend connection
  final apiService = ApiService();
  print('═══════════════════════════════════════════════');
  print('SmartPOS Frontend Starting...');
  print('Backend URL: ${ApiConfig.baseUrl}');
  print('═══════════════════════════════════════════════');
  
  final isConnected = await apiService.testConnection();
  
  if (isConnected) {
    print('═══════════════════════════════════════════════');
    print('✅ Backend is ONLINE and CONNECTED');
    print('═══════════════════════════════════════════════');
  } else {
    print('═══════════════════════════════════════════════');
    print('❌ WARNING: Backend is NOT REACHABLE');
    print('   Please ensure backend is running at:');
    print('   ${ApiConfig.baseUrl}');
    print('   Note: App will still run. Some features may be limited.');
    print('═══════════════════════════════════════════════');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductsProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: 'SmartPOS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.getThemeData(),
        locale: const Locale('en'),
        supportedLocales: const [
          Locale('en', ''),
          Locale('hi', ''),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const SplashScreen(),
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Load user from storage
    await authProvider.loadUser();
    
    // Wait a moment for smooth UX
    await Future.delayed(const Duration(seconds: 1));
    
    if (!mounted) return;
    
    // Navigate based on authentication status
    if (authProvider.isAuthenticated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.bgDark, AppColors.bgSurface],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.shopping_bag,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'SmartPOS',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Point of Sale System',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
