import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Supabase URL
  static const String SUPABASE_URL = 'https://qmfoudfrqlbikzneopkv.supabase.co';
  
  // Supabase anon key
  static const String SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFtZm91ZGZycWxiaWt6bmVvcGt2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcyNTYyNTMsImV4cCI6MjA3MjgzMjI1M30.VJL6-4uy8qLplVYwTLY-zqTsp9L7yEBQ60gOiO8-SJ0';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SUPABASE_URL,
      anonKey: SUPABASE_ANON_KEY,
    );
  }
}
