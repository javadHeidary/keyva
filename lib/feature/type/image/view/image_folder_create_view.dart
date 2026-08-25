import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/feature/type/image/viewmodel/image_folder_create_viewmodel.dart';
import 'package:keyva/feature/type/image/widget/image_folder_form_scaffold.dart';

class ImageFolderCreateView extends GetView<ImageFolderCreateViewModel> {
  const ImageFolderCreateView({super.key});

  @override
  Widget build(BuildContext context) {
    return ImageFolderFormScaffold(controller: controller);
  }
}
