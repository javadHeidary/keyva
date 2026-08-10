import 'package:flutter/material.dart';

enum ThemePreference {
  light,
  dark,
  system;

  String get label => switch (this) {
    ThemePreference.light => 'روشن',
    ThemePreference.dark => 'تاریک',
    ThemePreference.system => 'پیش‌فرض سیستم',
  };

  ThemeMode get themeMode => switch (this) {
    ThemePreference.light => ThemeMode.light,
    ThemePreference.dark => ThemeMode.dark,
    ThemePreference.system => ThemeMode.system,
  };
}
