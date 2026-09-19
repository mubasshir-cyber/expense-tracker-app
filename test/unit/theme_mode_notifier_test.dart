import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/app/providers.dart';

void main() {
  group('ThemeModeNotifier Tests', () {
    test('Initial theme mode is ThemeMode.system', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialMode = container.read(themeModeProvider);
      expect(initialMode, equals(ThemeMode.system));
    });

    test('setThemeMode updates state explicitly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
      expect(container.read(themeModeProvider), equals(ThemeMode.dark));

      container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
      expect(container.read(themeModeProvider), equals(ThemeMode.light));
    });

    test('toggle switches between dark and light modes', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // System -> toggle becomes Dark
      container.read(themeModeProvider.notifier).toggle();
      expect(container.read(themeModeProvider), equals(ThemeMode.dark));

      // Dark -> toggle becomes Light
      container.read(themeModeProvider.notifier).toggle();
      expect(container.read(themeModeProvider), equals(ThemeMode.light));

      // Light -> toggle becomes Dark
      container.read(themeModeProvider.notifier).toggle();
      expect(container.read(themeModeProvider), equals(ThemeMode.dark));
    });
  });
}
