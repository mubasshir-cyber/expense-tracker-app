import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:expense_tracker/core/config/env.dart';

void main() {
  group('Env Config Tests', () {
    test('Reads Supabase environment variables from dotenv', () {
      dotenv.testLoad(fileInput: '''
SUPABASE_URL=https://test-project.supabase.co
SUPABASE_PUBLISHABLE_KEY=test-publishable-key-12345
''');

      expect(Env.supabaseUrl, equals('https://test-project.supabase.co'));
      expect(
        Env.supabasePublishableKey,
        equals('test-publishable-key-12345'),
      );
      expect(Env.supabaseAnonKey, equals('test-publishable-key-12345'));
    });
  });
}
