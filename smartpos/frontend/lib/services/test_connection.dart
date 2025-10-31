import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

Future<void> testSupabaseConnection() async {
  try {
    // Try to fetch a simple count from the profiles table
    final response = await SupabaseConfig.client
        .from('profiles')
        .select('*');
    print('Successfully connected to Supabase!');
    print('Response: $response');
    
    print('Successfully connected to Supabase!');
    print('Number of profiles: ${response.count}');
    return;
  } catch (e) {
    print('Error connecting to Supabase: $e');
    rethrow;
  }
}
