import 'package:keyva/core/theme/app_responsive.dart';

extension ResponsiveNum on num {
  double get s => AppScreen.s(this);

  double get w => AppScreen.sw(this);

  double get h => AppScreen.sh(this);

  double get sp => AppScreen.sp(this);

  double get sw => AppScreen.wp(this);

  double get sh => AppScreen.hp(this);
}
