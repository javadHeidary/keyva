import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/feature/type/login/viewmodel/login_edit_viewmodel.dart';
import 'package:keyva/feature/type/login/widget/login_form_scaffold.dart';

class LoginEditView extends GetView<LoginEditViewModel> {
  const LoginEditView({super.key});

  @override
  Widget build(BuildContext context) {
    return LoginFormScaffold(controller: controller);
  }
}
