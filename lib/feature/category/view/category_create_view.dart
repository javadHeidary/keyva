import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/feature/category/viewmodel/category_form_viewmodel.dart';
import 'package:keyva/feature/category/widget/category_form_scaffold.dart';

class CategoryCreateView extends GetView<CategoryFormViewModel> {
  const CategoryCreateView({super.key});

  @override
  Widget build(BuildContext context) {
    return CategoryFormScaffold(controller: controller);
  }
}

class CategoryEditView extends GetView<CategoryFormViewModel> {
  const CategoryEditView({super.key});

  @override
  Widget build(BuildContext context) {
    return CategoryFormScaffold(controller: controller);
  }
}
