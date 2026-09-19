import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized access to environment variables loaded via flutter_dotenv.
abstract final class Env {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';

  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
}
