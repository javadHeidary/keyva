import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/feature/onboarding/viewmodel/onboarding_viewmodel.dart';

Future<void> precacheOnboardingAssets(BuildContext context) async {
  await Future.wait(
    OnboardingController().slides.map(
      (slide) => SvgAssetLoader(slide.imagePath).loadBytes(context),
    ),
  );
  _warmOnboardingTypography();
}

void _warmOnboardingTypography() {
  final styles = [AppTypography.displaySmall, AppTypography.titleMedium];
  for (final style in styles) {
    final painter = TextPainter(
      text: TextSpan(text: 'گاوصندوق امن', style: style),
      textDirection: TextDirection.rtl,
    )..layout();
    painter.dispose();
  }
}
