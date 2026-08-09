import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/feature/type/note/viewmodel/note_create_viewmodel.dart';
import 'package:keyva/feature/type/note/widget/note_form_scaffold.dart';

class NoteCreateView extends GetView<NoteCreateViewModel> {
  const NoteCreateView({super.key});

  @override
  Widget build(BuildContext context) {
    return NoteFormScaffold(controller: controller);
  }
}
