import 'package:flutter/material.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/home/model/vault_models.dart';
import 'package:keyva/feature/type/login/util/login_password_util.dart';

class LoginFaviconWidget extends StatelessWidget {
  const LoginFaviconWidget({
    super.key,
    this.website,
    this.size,
    this.fallbackIcon,
  });

  final String? website;
  final double? size;
  final IconData? fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimension = size ?? 40.s;
    final host = websiteHostForFavicon(website);
    final iconData = fallbackIcon ?? VaultItemType.login.icon;

    return Container(
      width: dimension,
      height: dimension,
      decoration: BoxDecoration(
        color: colors.input,
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      clipBehavior: Clip.antiAlias,
      child: host != null
          ? Image.network(
              'https://www.google.com/s2/favicons?domain=$host&sz=128',
              width: dimension,
              height: dimension,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _FallbackIcon(
                icon: iconData,
                dimension: dimension,
                color: colors.textSecondary,
              ),
            )
          : _FallbackIcon(
              icon: iconData,
              dimension: dimension,
              color: colors.textSecondary,
            ),
    );
  }
}

class _FallbackIcon extends StatelessWidget {
  const _FallbackIcon({
    required this.icon,
    required this.dimension,
    required this.color,
  });

  final IconData icon;
  final double dimension;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(icon, size: dimension * 0.5, color: color),
    );
  }
}

class LoginHeaderAvatar extends StatelessWidget {
  const LoginHeaderAvatar({super.key, required this.website});

  final String? website;

  @override
  Widget build(BuildContext context) {
    return LoginFaviconWidget(website: website, size: 72.s);
  }
}
