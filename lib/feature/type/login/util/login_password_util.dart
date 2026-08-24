import 'dart:math';

import 'package:flutter/material.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';

double calculateLoginPasswordStrength(String password) {
  if (password.isEmpty) return 0;

  double score = 0;
  final length = password.length;

  if (length >= 8) score += 0.2;
  if (length >= 12) score += 0.1;
  if (length >= 16) score += 0.05;
  if (RegExp('[a-z]').hasMatch(password)) score += 0.15;
  if (RegExp('[A-Z]').hasMatch(password)) score += 0.15;
  if (RegExp('[0-9]').hasMatch(password)) score += 0.15;
  if (RegExp(r'[^a-zA-Z0-9]').hasMatch(password)) score += 0.15;

  return score.clamp(0.0, 1.0);
}

String loginPasswordStrengthLabel(double strength) {
  if (strength < 0.2) return 'خیلی ضعیف';
  if (strength < 0.4) return 'ضعیف';
  if (strength < 0.6) return 'متوسط';
  if (strength < 0.8) return 'قوی';
  return 'خیلی قوی';
}

Color loginPasswordStrengthColor(BuildContext context, double strength) {
  final colors = context.colors;
  if (strength < 0.4) return colors.error;
  if (strength < 0.6) return colors.warning;
  return colors.success;
}

String generateLoginPassword({int length = 16}) {
  const lower = 'abcdefghijklmnopqrstuvwxyz';
  const upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  const digits = '0123456789';
  const symbols = '!@#\$%^&*-_+=';
  const all = lower + upper + digits + symbols;

  final random = Random.secure();
  final codeUnits = List<int>.generate(length, (_) {
    return all.codeUnitAt(random.nextInt(all.length));
  });

  return String.fromCharCodes(codeUnits);
}

String? normalizeWebsiteUrl(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  final withScheme = trimmed.contains('://') ? trimmed : 'https://$trimmed';
  final uri = Uri.tryParse(withScheme);
  if (uri == null || !uri.hasAuthority) return null;
  return uri.toString();
}

String? websiteHostForFavicon(String? website) {
  if (website == null || website.trim().isEmpty) return null;
  final normalized = normalizeWebsiteUrl(website);
  if (normalized == null) return null;
  final uri = Uri.tryParse(normalized);
  return uri?.host.isNotEmpty == true ? uri!.host : null;
}

String faviconUrlForHost(String host) {
  return 'https://www.google.com/s2/favicons?domain=$host&sz=128';
}

String faviconCacheKeyForHost(String host) {
  return 'favicon:$host';
}

String formatLoginCreatedAt(DateTime dateTime) {
  final y = dateTime.year.toString().padLeft(4, '0');
  final m = dateTime.month.toString().padLeft(2, '0');
  final d = dateTime.day.toString().padLeft(2, '0');
  final h = dateTime.hour.toString().padLeft(2, '0');
  final min = dateTime.minute.toString().padLeft(2, '0');
  return '$y/$m/$d • $h:$min';
}
