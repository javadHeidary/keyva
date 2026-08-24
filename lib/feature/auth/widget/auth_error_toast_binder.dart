import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/shared/widget/toast_widget.dart';

class AuthErrorToastBinder extends StatefulWidget {
  const AuthErrorToastBinder({
    super.key,
    required this.message,
    required this.child,
    this.errorTitle,
    this.successMessage,
    this.successTitle,
  });

  final RxString message;
  final String? errorTitle;
  final RxString? successMessage;
  final String? successTitle;
  final Widget child;

  @override
  State<AuthErrorToastBinder> createState() => _AuthErrorToastBinderState();
}

class _AuthErrorToastBinderState extends State<AuthErrorToastBinder> {
  Worker? _errorWorker;
  Worker? _successWorker;

  @override
  void initState() {
    super.initState();
    _listenError(widget.message);
    _listenSuccess(widget.successMessage);
  }

  @override
  void didUpdateWidget(covariant AuthErrorToastBinder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message != widget.message) {
      _errorWorker?.dispose();
      _listenError(widget.message);
    }
    if (oldWidget.successMessage != widget.successMessage) {
      _successWorker?.dispose();
      _listenSuccess(widget.successMessage);
    }
  }

  void _listenError(RxString message) {
    _errorWorker = ever<String>(message, (value) {
      if (value.isEmpty || !mounted) {
        return;
      }
      AppToast.error(
        context,
        title: widget.errorTitle ?? 'خطا',
        message: value,
      );
    });
  }

  void _listenSuccess(RxString? message) {
    if (message == null) {
      return;
    }
    _successWorker = ever<String>(message, (value) {
      if (value.isEmpty || !mounted) {
        return;
      }
      AppToast.success(
        context,
        title: widget.successTitle ?? 'عملیات موفق',
        message: value,
      );
    });
  }

  @override
  void dispose() {
    _errorWorker?.dispose();
    _successWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
