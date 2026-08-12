import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/simple/get_view.dart';
import 'package:keyva/feature/category/viewmodel/category_form_viewmodel.dart';
import 'package:keyva/feature/category/widget/category_form_scaffold.dart';

class CategoryEditView extends GetView<CategoryFormViewModel> {
  const CategoryEditView({super.key});

  @override
  Widget build(BuildContext context) {
    return CategoryFormScaffold(controller: controller);
  }
}
