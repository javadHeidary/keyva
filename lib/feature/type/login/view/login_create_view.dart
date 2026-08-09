import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/feature/type/login/viewmodel/login_create_viewmodel.dart';
import 'package:keyva/feature/type/login/widget/login_form_scaffold.dart';

class LoginCreateView extends GetView<LoginCreateViewModel> {
  const LoginCreateView({super.key});

  @override
  Widget build(BuildContext context) {
    return LoginFormScaffold(controller: controller);
  }
}
