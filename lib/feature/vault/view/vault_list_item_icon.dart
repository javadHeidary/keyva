import 'package:flutter/material.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/home/model/vault_models.dart';
import 'package:keyva/feature/type/bank_card/util/bank_card_util.dart';
import 'package:keyva/feature/type/login/widget/login_circle_icon.dart';
import 'package:keyva/feature/type/login/widget/login_favicon_widget.dart';
import 'package:keyva/feature/vault/model/bank_card_item.dart';
import 'package:keyva/feature/vault/model/login_item.dart';

class VaultListItemIcon extends StatelessWidget {
  const VaultListItemIcon({super.key, required this.item, this.source});

  final VaultListItem item;
  final Object? source;

  @override
  Widget build(BuildContext context) {
    final dimension = 40.s;
    final source = this.source;

    if (source is LoginItem) {
      return LoginFaviconWidget(website: source.website, size: dimension);
    }

    if (source is BankCardItem) {
      final bank = resolveBankInfoFromCard(
        extractCardDigits(source.cardNumber),
      );
      if (bank != null) {
        return Container(
          width: dimension,
          height: dimension,
          decoration: BoxDecoration(
            color: context.colors.input,
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          clipBehavior: Clip.antiAlias,
          child: bank.logoBuilder(width: dimension, height: dimension),
        );
      }
    }

    return LoginCircleIcon(
      size: dimension,
      icon: Icon(
        item.type.icon,
        size: AppSizes.iconMd.s,
        color: context.colors.textSecondary,
      ),
    );
  }
}
