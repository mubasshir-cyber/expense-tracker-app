import 'package:supabase_flutter/supabase_flutter.dart';
import 'env.dart';

/// Centralized configuration and initialization for Supabase.
abstract final class SupabaseConfig {
  /// Initializes the Supabase client using environment variables.
  static Future<void> initialize() async {
    if (Env.supabaseUrl.isNotEmpty && Env.supabasePublishableKey.isNotEmpty) {
      await Supabase.initialize(
        url: Env.supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: Env.supabasePublishableKey,
      );
    }
  }

  /// Returns the current Supabase client instance.
  static SupabaseClient get client => Supabase.instance.client;
}
