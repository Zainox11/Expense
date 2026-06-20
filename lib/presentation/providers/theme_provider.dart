import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';

/// Theme mode provider (dark/light)
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

/// Theme notifier
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark);

  void toggleTheme() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  void setTheme(ThemeMode mode) {
    state = mode;
  }

  bool get isDarkMode => state == ThemeMode.dark;
}

/// Current theme data provider
final themeDataProvider = Provider<ThemeData>((ref) {
  final mode = ref.watch(themeModeProvider);
  return mode == ThemeMode.dark ? AppTheme.darkTheme : AppTheme.lightTheme;
});

/// Currency symbol provider
final currencySymbolProvider = StateProvider<String>((ref) => '\$');

/// Biometric enabled provider
final biometricEnabledProvider = StateProvider<bool>((ref) => false);

/// Notifications enabled provider
final notificationsEnabledProvider = StateProvider<bool>((ref) => true);
