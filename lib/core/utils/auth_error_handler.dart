import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthErrorHandler {
  AuthErrorHandler._();

  /// Converts technical Supabase Auth errors and general exceptions into clean, user-friendly messages.
  static String getReadableErrorMessage(dynamic error) {
    // Log the raw technical error for developer debugging
    developer.log('Auth Error: $error', name: 'AuthErrorHandler');

    if (error is AuthException) {
      final code = error.code?.toLowerCase() ?? '';
      final message = error.message.toLowerCase();
      final statusCode = error.statusCode;

      // Rate limit / 429
      if (statusCode == '429' ||
          code.contains('over_email_send_rate_limit') ||
          code.contains('rate_limit') ||
          message.contains('rate limit')) {
        return 'Too many attempts. Supabase email sending limit reached. Please wait a few minutes before trying again.';
      }

      // User already exists / registered
      if (code.contains('user_already_exists') ||
          message.contains('already registered') ||
          message.contains('already exists')) {
        return 'An account with this email already exists. Please log in instead.';
      }

      // Invalid login credentials
      if (code.contains('invalid_credentials') ||
          message.contains('invalid login credentials') ||
          message.contains('invalid grant')) {
        return 'Incorrect email or password. Please try again.';
      }

      // Email unconfirmed
      if (code.contains('email_not_confirmed') ||
          message.contains('email not confirmed')) {
        return 'Please confirm your email address before signing in. Check your inbox or spam folder.';
      }

      // Weak password
      if (code.contains('weak_password') ||
          message.contains('password should be') ||
          message.contains('password is too short')) {
        return 'Password is too weak. Please use at least 8 characters with letters and numbers.';
      }

      // Invalid email address
      if (code.contains('validation_failed') ||
          message.contains('valid email')) {
        return 'Please enter a valid email address.';
      }

      // Signup disabled
      if (code.contains('signup_disabled') ||
          message.contains('signups not allowed')) {
        return 'Signups are currently disabled. Please contact support.';
      }

      // Return clean version of message without raw exception wrapper if meaningful
      if (error.message.isNotEmpty && !error.message.startsWith('{')) {
        return error.message;
      }
    }

    final errorStr = error.toString().toLowerCase();

    // Network / Socket / Timeout issues
    if (errorStr.contains('socketexception') ||
        errorStr.contains('network') ||
        errorStr.contains('connection refused') ||
        errorStr.contains('timed out')) {
      return 'Unable to connect to the server. Please check your internet connection.';
    }

    return 'An unexpected error occurred. Please try again later.';
  }
}
