import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/feature/type/note/viewmodel/note_edit_viewmodel.dart';
import 'package:keyva/feature/type/note/widget/note_form_scaffold.dart';

class NoteEditView extends GetView<NoteEditViewModel> {
  const NoteEditView({super.key});

  @override
  Widget build(BuildContext context) {
    return NoteFormScaffold(controller: controller);
  }
}
