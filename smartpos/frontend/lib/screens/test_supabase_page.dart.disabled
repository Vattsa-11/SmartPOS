import 'package:flutter/material.dart';
import '../services/supabase_config.dart';

class TestSupabasePage extends StatelessWidget {
  const TestSupabasePage({Key? key}) : super(key: key);

  Future<void> _testConnection() async {
    try {
      final count = await SupabaseConfig.client
          .from('profiles')
          .select('*')
          .execute();
      
      print('Connected to Supabase!');
      print('Profiles data: $count');
    } catch (e) {
      print('Error connecting to Supabase: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Supabase Connection'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _testConnection,
          child: const Text('Test Connection'),
        ),
      ),
    );
  }
}
