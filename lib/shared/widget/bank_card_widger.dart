import 'package:flutter/material.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';

class BankCardWidget extends StatelessWidget {
  const BankCardWidget({
    super.key,
    required this.bankName,
    required this.cardType,
    required this.cardNumber,
    required this.expiryDate,
    required this.cvv,
    this.backgroundColor,
    this.textColor,
    this.accentColor,
    this.leftLogo,
    this.rightLogo,
    this.onTap,
  });

  final String bankName;
  final String cardType;
  final String cardNumber;
  final String expiryDate;
  final String cvv;

  final Color? backgroundColor;
  final Color? textColor;
  final Color? accentColor;

  final Widget? leftLogo;
  final Widget? rightLogo;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final bg = backgroundColor ?? const Color(0xFF0D0D0D);
    final txt = textColor ?? const Color(0xFFF5E6C8);
    final accent = accentColor ?? const Color(0xFFD4AF37);

    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1.586,
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.large.s),
            border: Border.all(
              color: colors.border.withValues(alpha: 0.6),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg.s,
              AppSpacing.md.s + 2.s,
              AppSpacing.lg.s,
              AppSpacing.md.s,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLogoSlot(
                        logo: leftLogo,
                        width: 36.s,
                        height: 28.s,
                        icon: Icons.credit_card_rounded,
                        iconColor: txt,
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              bankName,
                              textAlign: TextAlign.center,
                              style: AppTypography.titleSmall.copyWith(
                                color: txt,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                            SizedBox(height: 2.s),
                            Text(
                              cardType,
                              textAlign: TextAlign.center,
                              style: AppTypography.labelSmall.copyWith(
                                color: txt.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildLogoSlot(
                        logo: rightLogo,
                        width: 36.s,
                        height: 32.s,
                        icon: Icons.account_balance_rounded,
                        iconColor: txt,
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
                Text(
                  _formatCardNumber(cardNumber),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 18.s,
                    fontWeight: FontWeight.w600,
                    color: accent,
                    letterSpacing: 2.2,
                    height: 1.2,
                  ),
                ),
                const Spacer(flex: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'تاریخ انقضا: $expiryDate',
                      style: AppTypography.labelSmall.copyWith(
                        color: txt.withValues(alpha: 0.9),
                      ),
                    ),
                    Text(
                      'CVV2: $cvv',
                      style: AppTypography.labelSmall.copyWith(
                        color: txt.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.sm.s),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSlot({
    required Widget? logo,
    required double width,
    required double height,
    required IconData icon,
    required Color iconColor,
  }) {
    if (logo != null) {
      return SizedBox(width: width, height: height, child: logo);
    }
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.ssm.s),
        ),
        child: Center(
          child: Icon(
            icon,
            size: AppSizes.iconMd.s,
            color: iconColor.withValues(alpha: 0.92),
          ),
        ),
      ),
    );
  }

  String _formatCardNumber(String number) {
    final cleaned = number.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < cleaned.length; i++) {
      buffer.write(cleaned[i]);
      if ((i + 1) % 4 == 0 && i != cleaned.length - 1) {
        buffer.write('  ');
      }
    }
    return buffer.toString();
  }
}
