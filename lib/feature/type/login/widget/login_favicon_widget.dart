import 'package:flutter/material.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/home/model/vault_models.dart';
import 'package:keyva/feature/type/login/util/login_password_util.dart';
import 'package:keyva/shared/widget/app_cached_remote_image.dart';

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
    final fallback = _FallbackIcon(
      icon: iconData,
      dimension: dimension,
      color: colors.textSecondary,
    );

    return Container(
      width: dimension,
      height: dimension,
      decoration: BoxDecoration(
        color: colors.input,
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      clipBehavior: Clip.antiAlias,
      child: host != null
          ? AppCachedRemoteImage(
              key: const Key('login-favicon'),
              url: faviconUrlForHost(host),
              width: dimension,
              height: dimension,
              cacheKey: faviconCacheKeyForHost(host),
              errorWidget: fallback,
            )
          : fallback,
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
