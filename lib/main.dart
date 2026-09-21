import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/config/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (.env)
  await dotenv.load(fileName: '.env');

  // Initialize Supabase Client
  await SupabaseConfig.initialize();

  runApp(
    const ProviderScope(
      child: ExpenseTrackerApp(),
    ),
  );
}
