import 'package:flutter/material.dart';
import 'package:keyva/feature/shell/util/main_shell_layout.dart';

/// Reserves bottom space so tab content is not covered by the shell nav bar.
class MainShellTabInsets extends StatelessWidget {
  const MainShellTabInsets({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MainShellLayout.contentBottomGap(context),
      ),
      child: child,
    );
  }
}
