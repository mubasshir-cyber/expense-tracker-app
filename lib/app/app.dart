import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/notifications/local_notification_provider.dart';
import '../core/theme/app_theme.dart';
import 'providers.dart';
import 'router.dart';

/// Root application widget configuring routing, reactive theme mode, and notification handling.
class ExpenseTrackerApp extends ConsumerStatefulWidget {
  const ExpenseTrackerApp({super.key});

  @override
  ConsumerState<ExpenseTrackerApp> createState() => _ExpenseTrackerAppState();
}

class _ExpenseTrackerAppState extends ConsumerState<ExpenseTrackerApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifService = ref.read(localNotificationServiceProvider);
      final router = ref.read(routerProvider);
      notifService.initialize(
        onSelectRoute: (route) {
          router.push(route);
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
