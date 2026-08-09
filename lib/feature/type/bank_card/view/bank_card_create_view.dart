import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/feature/type/bank_card/viewmodel/bank_card_create_viewmodel.dart';
import 'package:keyva/feature/type/bank_card/widget/bank_card_form_scaffold.dart';

class BankCardCreateView extends GetView<BankCardCreateViewModel> {
  const BankCardCreateView({super.key});

  @override
  Widget build(BuildContext context) {
    return BankCardFormScaffold(controller: controller);
  }
}
