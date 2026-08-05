import 'package:keyva/core/theme/app_responsive.dart';

extension ResponsiveNum on num {
  double get s => AppResponsive.s(this);

  double get w => AppResponsive.sw(this);

  double get h => AppResponsive.sh(this);

  double get sp => AppResponsive.sp(this);

  double get sw => AppResponsive.wp(this);

  double get sh => AppResponsive.hp(this);
}
