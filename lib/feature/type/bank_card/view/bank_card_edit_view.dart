import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/feature/type/bank_card/viewmodel/bank_card_edit_viewmodel.dart';
import 'package:keyva/feature/type/bank_card/widget/bank_card_form_scaffold.dart';

class BankCardEditView extends GetView<BankCardEditViewModel> {
  const BankCardEditView({super.key});

  @override
  Widget build(BuildContext context) {
    return BankCardFormScaffold(controller: controller);
  }
}
