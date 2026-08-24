import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/shared/widget/toast_widget.dart';

class AuthErrorToastBinder extends StatefulWidget {
  const AuthErrorToastBinder({
    super.key,
    required this.message,
    required this.child,
  });

  final RxString message;
  final Widget child;

  @override
  State<AuthErrorToastBinder> createState() => _AuthErrorToastBinderState();
}

class _AuthErrorToastBinderState extends State<AuthErrorToastBinder> {
  Worker? _worker;

  @override
  void initState() {
    super.initState();
    _listen(widget.message);
  }

  @override
  void didUpdateWidget(covariant AuthErrorToastBinder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message != widget.message) {
      _worker?.dispose();
      _listen(widget.message);
    }
  }

  void _listen(RxString message) {
    _worker = ever<String>(message, (value) {
      if (value.isEmpty || !mounted) {
        return;
      }
      AppToast.error(context, title: value);
    });
  }

  @override
  void dispose() {
    _worker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
