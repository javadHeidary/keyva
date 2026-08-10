import 'package:flutter/material.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';

enum _SettingsRowKind { nav, toggle, value }

class SettingsRow extends StatelessWidget {
  const SettingsRow._({
    required _SettingsRowKind kind,
    required this.title,
    required this.icon,
    this.subtitle,
    this.onTap,
    this.value,
    this.onChanged,
    this.trailingValue,
  }) : _kind = kind;

  final _SettingsRowKind _kind;
  final String title;
  final IconData icon;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool? value;
  final ValueChanged<bool>? onChanged;
  final String? trailingValue;

  factory SettingsRow.nav({
    required String title,
    required IconData icon,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return SettingsRow._(
      kind: _SettingsRowKind.nav,
      title: title,
      icon: icon,
      subtitle: subtitle,
      onTap: onTap,
    );
  }

  factory SettingsRow.toggle({
    required String title,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SettingsRow._(
      kind: _SettingsRowKind.toggle,
      title: title,
      icon: icon,
      value: value,
      onChanged: onChanged,
    );
  }

  factory SettingsRow.value({
    required String title,
    required IconData icon,
    required String trailingValue,
  }) {
    return SettingsRow._(
      kind: _SettingsRowKind.value,
      title: title,
      icon: icon,
      trailingValue: trailingValue,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final content = SizedBox(
      height: AppSizes.itemHeight.h,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg.s,
          vertical: AppSpacing.sm.s,
        ),
        child: Row(
          children: [
            _SettingsCircleIcon(
              icon: Icon(
                icon,
                size: AppSizes.iconMd.s,
                color: colors.textSecondary,
              ),
            ),
            SizedBox(width: AppSpacing.md.s),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    SizedBox(height: 2.s),
                    Text(
                      subtitle!,
                      style: AppTypography.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (_kind == _SettingsRowKind.nav) ...[
              Icon(
                Icons.chevron_right_rounded,
                size: AppSizes.iconLg.s,
                color: colors.textTertiary,
              ),
            ] else if (_kind == _SettingsRowKind.toggle) ...[
              Switch(value: value ?? false, onChanged: onChanged),
            ] else if (_kind == _SettingsRowKind.value) ...[
              Text(
                trailingValue ?? '',
                style: AppTypography.bodySmall.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (_kind == _SettingsRowKind.nav) {
      return Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, child: content),
      );
    }

    return content;
  }
}

class _SettingsCircleIcon extends StatelessWidget {
  const _SettingsCircleIcon({required this.icon});

  final Widget icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: 40.s,
      height: 40.s,
      decoration: BoxDecoration(
        color: colors.backgroundInput,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Center(child: icon),
    );
  }
}
