import 'package:flutter/material.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
// import '../../core/theme/responsive_extensions.dart';

class ThemeDemoPage extends StatefulWidget {
  const ThemeDemoPage({super.key});

  @override
  State<ThemeDemoPage> createState() => _ThemeDemoPageState();
}

class _ThemeDemoPageState extends State<ThemeDemoPage> {
  bool _isDark = false;
  final _textController = TextEditingController();
  bool _switchValue = true;
  bool _checkboxValue = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _isDark ? AppTheme.dark : AppTheme.light,
      child: Builder(
        builder: (context) {
          final colors = context.colors;
          final shadows = context.shadows;

          return Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              backgroundColor: colors.pageBackground,
              appBar: AppBar(
                title: const Text('Theme Demo · Keyva'),
                actions: [
                  IconButton(
                    tooltip: _isDark ? 'حالت روشن' : 'حالت تاریک',
                    onPressed: () => setState(() => _isDark = !_isDark),
                    icon: Icon(
                      _isDark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                    ),
                  ),
                ],
              ),
              body: SafeArea(
                child: ListView(
                  padding: EdgeInsets.all(16.s),
                  children: [
                    // ==================================================
                    // 1. Typography
                    // ==================================================
                    _SectionTitle(title: 'Typography (Kalameh)'),
                    SizedBox(height: 12.s),

                    Text(
                      'Display Large',
                      style: AppTypography.displayLarge.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      'Display Medium',
                      style: AppTypography.displayMedium.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      'Headline Large',
                      style: AppTypography.headlineLarge.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      'Title Large',
                      style: AppTypography.titleLarge.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      'Body Large · متن اصلی بدنه',
                      style: AppTypography.bodyLarge.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      'Body Medium · متن ثانویه',
                      style: AppTypography.bodyMedium.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    Text(
                      'Label Small · راهنما',
                      style: AppTypography.labelSmall.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),

                    SizedBox(height: 24.s),

                    // ==================================================
                    // 2. Colors
                    // ==================================================
                    _SectionTitle(title: 'Colors'),
                    SizedBox(height: 12.s),

                    Wrap(
                      spacing: 12.s,
                      runSpacing: 12.s,
                      children: [
                        _ColorBox(label: 'Primary', color: colors.primary),
                        _ColorBox(label: 'Accent', color: colors.accent),
                        _ColorBox(label: 'Success', color: colors.success),
                        _ColorBox(label: 'Warning', color: colors.warning),
                        _ColorBox(label: 'Error', color: colors.error),
                        _ColorBox(
                          label: 'Card',
                          color: colors.card,
                          border: true,
                        ),
                        _ColorBox(
                          label: 'Input',
                          color: colors.input,
                          border: true,
                        ),
                        _ColorBox(
                          label: 'Border',
                          color: colors.border,
                          border: true,
                        ),
                      ],
                    ),

                    SizedBox(height: 24.s),

                    // ==================================================
                    // 3. Buttons
                    // ==================================================
                    _SectionTitle(title: 'Buttons'),
                    SizedBox(height: 12.s),

                    // Primary
                    SizedBox(
                      height: 52.s,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {},
                        child: const Text('دکمه اصلی (Primary)'),
                      ),
                    ),
                    SizedBox(height: 12.s),

                    // Outlined
                    SizedBox(
                      height: 52.s,
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {},
                        child: const Text('دکمه حاشیه‌دار (Outlined)'),
                      ),
                    ),
                    SizedBox(height: 12.s),

                    // Secondary
                    SizedBox(
                      height: 48.s,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.secondaryButton,
                          foregroundColor: colors.textPrimary,
                          elevation: 0,
                        ),
                        child: const Text('دکمه ثانویه (Secondary)'),
                      ),
                    ),
                    SizedBox(height: 12.s),

                    // Disabled
                    SizedBox(
                      height: 52.s,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: null,
                        child: const Text('دکمه غیرفعال'),
                      ),
                    ),
                    SizedBox(height: 12.s),

                    // Text Button
                    TextButton(
                      onPressed: () {},
                      child: const Text('دکمه متنی'),
                    ),

                    SizedBox(height: 24.s),

                    // ==================================================
                    // 4. Text Fields
                    // ==================================================
                    _SectionTitle(title: 'Text Fields'),
                    SizedBox(height: 12.s),

                    TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        labelText: 'عنوان ورودی',
                        hintText: 'متن راهنما...',
                        prefixIcon: Icon(Icons.lock_outline_rounded),
                      ),
                    ),
                    SizedBox(height: 12.s),

                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'ورودی با خطا',
                        errorText: 'این فیلد اجباری است',
                        prefixIcon: Icon(Icons.error_outline),
                      ),
                    ),

                    SizedBox(height: 24.s),

                    // ==================================================
                    // 5. Cards + Shadows
                    // ==================================================
                    _SectionTitle(title: 'Cards & Shadows'),
                    SizedBox(height: 12.s),

                    // Card معمولی
                    Container(
                      padding: EdgeInsets.all(16.s),
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(16.s),
                        boxShadow: shadows.card,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'کارت معمولی',
                            style: AppTypography.titleMedium.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 8.s),
                          Text(
                            'این کارت از رنگ card و سایهٔ card استفاده می‌کند.',
                            style: AppTypography.bodyMedium.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.s),

                    // Card Elevated
                    Container(
                      padding: EdgeInsets.all(16.s),
                      decoration: BoxDecoration(
                        color: colors.elevated,
                        borderRadius: BorderRadius.circular(16.s),
                        boxShadow: shadows.elevated,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'کارت Elevated',
                            style: AppTypography.titleMedium.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 8.s),
                          Text(
                            'سایهٔ قوی‌تر برای حالت‌های مهم‌تر.',
                            style: AppTypography.bodyMedium.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24.s),

                    // ==================================================
                    // 6. Controls
                    // ==================================================
                    _SectionTitle(title: 'Controls'),
                    SizedBox(height: 12.s),

                    Row(
                      children: [
                        Switch(
                          value: _switchValue,
                          onChanged: (v) => setState(() => _switchValue = v),
                        ),
                        SizedBox(width: 12.s),
                        Text(
                          'سوئیچ',
                          style: AppTypography.bodyMedium.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.s),

                    Row(
                      children: [
                        Checkbox(
                          value: _checkboxValue,
                          onChanged: (v) =>
                              setState(() => _checkboxValue = v ?? false),
                        ),
                        SizedBox(width: 8.s),
                        Text(
                          'چک‌باکس',
                          style: AppTypography.bodyMedium.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 24.s),

                    // ==================================================
                    // 7. Status Colors
                    // ==================================================
                    _SectionTitle(title: 'Status Colors'),
                    SizedBox(height: 12.s),

                    _StatusChip(label: 'موفقیت', color: colors.success),
                    SizedBox(height: 8.s),
                    _StatusChip(label: 'هشدار', color: colors.warning),
                    SizedBox(height: 8.s),
                    _StatusChip(label: 'خطا', color: colors.error),
                    SizedBox(height: 8.s),
                    _StatusChip(label: 'Accent', color: colors.accent),

                    SizedBox(height: 24.s),

                    // ==================================================
                    // 8. Responsive Info
                    // ==================================================
                    _SectionTitle(title: 'Responsive Info'),
                    SizedBox(height: 12.s),

                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.s),
                      decoration: BoxDecoration(
                        color: colors.input,
                        borderRadius: BorderRadius.circular(12.s),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'عرض صفحه: ${MediaQuery.sizeOf(context).width.toStringAsFixed(0)}',
                            style: AppTypography.bodyMedium.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                          Text(
                            'نمونه مقیاس (16.s): ${16.s.toStringAsFixed(1)}',
                            style: AppTypography.bodyMedium.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                          Text(
                            'نمونه فونت (16.sp): ${16.sp.toStringAsFixed(1)}',
                            style: AppTypography.bodyMedium.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 8.s),
                          Text(
                            'این متن با فونت ۱۶.sp نوشته شده',
                            style: AppTypography.bodyMedium.copyWith(
                              color: colors.textSecondary,
                              fontSize: 16.sp,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 48.s),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==================================================
// Helper Widgets
// ==================================================

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.titleLarge.copyWith(
        color: context.colors.textPrimary,
      ),
    );
  }
}

class _ColorBox extends StatelessWidget {
  final String label;
  final Color color;
  final bool border;

  const _ColorBox({
    required this.label,
    required this.color,
    this.border = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64.s,
          height: 64.s,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12.s),
            border: border
                ? Border.all(color: context.colors.border, width: 1)
                : null,
          ),
        ),
        SizedBox(height: 6.s),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.s, vertical: 8.s),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.s),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: AppTypography.labelMedium.copyWith(color: color),
      ),
    );
  }
}
