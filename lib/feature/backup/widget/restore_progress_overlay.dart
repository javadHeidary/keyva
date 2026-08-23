import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/backup/model/restore_progress.dart';
import 'package:keyva/feature/backup/viewmodel/restore_viewmodel.dart';

const restoreProgressRouteName = 'restore-progress-overlay';

class RestoreProgressOverlayHandle {
  RestoreProgressOverlayHandle(this._route, this._navigator);

  final Route<void> _route;
  final NavigatorState _navigator;

  void dismiss() {
    if (_route.isActive) {
      _navigator.removeRoute(_route);
    }
  }
}

RestoreProgressOverlayHandle showRestoreProgressOverlay({
  required BuildContext context,
  required RestoreViewModel restore,
}) {
  final navigator = Navigator.of(context, rootNavigator: true);
  final colors = context.colors;
  final route = DialogRoute<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: colors.overlay,
    barrierLabel: restoreProgressRouteName,
    settings: const RouteSettings(name: restoreProgressRouteName),
    builder: (_) => RestoreProgressOverlay(restore: restore),
  );
  navigator.push(route);
  return RestoreProgressOverlayHandle(route, navigator);
}

Future<T> runRestoreWithProgressOverlay<T>({
  required BuildContext context,
  required RestoreViewModel restore,
  required Future<T> Function() action,
}) async {
  final handle = showRestoreProgressOverlay(context: context, restore: restore);
  try {
    return await action();
  } finally {
    handle.dismiss();
    restore.clearProgress();
  }
}

class RestoreProgressOverlay extends StatelessWidget {
  const RestoreProgressOverlay({super.key, required this.restore});

  final RestoreViewModel restore;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return PopScope(
      canPop: false,
      child: Material(
        key: const Key('restore-progress-overlay'),
        color: Colors.transparent,
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl.s),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 360.s),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(AppRadius.modal),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.xl.s,
                    AppSpacing.xxl.s,
                    AppSpacing.xl.s,
                    AppSpacing.xl.s,
                  ),
                  child: Obx(() {
                    final current =
                        restore.progress.value ?? RestoreProgress.decryptStarting();
                    return Directionality(
                      textDirection: TextDirection.rtl,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'در حال بازیابی',
                            textAlign: TextAlign.center,
                            style: AppTypography.headlineSmall.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                          SizedBox(height: AppSpacing.lg.h),
                          Text(
                            key: const Key('restore-progress-percent'),
                            '${current.percent}%',
                            textAlign: TextAlign.center,
                            style: AppTypography.withFaNum(
                              AppTypography.displaySmall.copyWith(
                                color: colors.primary,
                              ),
                            ),
                          ),
                          SizedBox(height: AppSpacing.lg.h),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.small),
                            child: LinearProgressIndicator(
                              key: const Key('restore-progress-bar'),
                              value: current.percent / 100,
                              minHeight: 8.s,
                            ),
                          ),
                          SizedBox(height: AppSpacing.md.h),
                          Text(
                            current.message,
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMedium.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                          SizedBox(height: AppSpacing.xl.h),
                          Text(
                            key: const Key('restore-progress-stay-open'),
                            RestoreProgressMessages.stayOpen,
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
