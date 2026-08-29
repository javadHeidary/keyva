import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:keyva/core/di/injection_container.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/vault/blob/encrypted_blob_store.dart';
import 'package:keyva/shared/icons/app_icons.dart';

class EncryptedVaultImage extends StatefulWidget {
  const EncryptedVaultImage({
    super.key,
    required this.blobId,
    this.fit = BoxFit.cover,
    this.store,
    this.onDecoded,
  });

  final String blobId;
  final BoxFit fit;
  final EncryptedBlobStore? store;
  final ValueChanged<bool>? onDecoded;

  @override
  State<EncryptedVaultImage> createState() => _EncryptedVaultImageState();
}

class _EncryptedVaultImageState extends State<EncryptedVaultImage> {
  late Future<Uint8List?> _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = _load();
  }

  @override
  void didUpdateWidget(covariant EncryptedVaultImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.blobId != widget.blobId || oldWidget.store != widget.store) {
      setState(() {
        _bytes = _load();
      });
    }
  }

  Future<Uint8List?> _load() async {
    final store = widget.store ??
        (getIt.isRegistered<EncryptedBlobStore>()
            ? getIt<EncryptedBlobStore>()
            : null);
    if (store == null) {
      _notifyDecoded(false);
      return null;
    }
    final result = await store.read(widget.blobId);
    if (result is Success<Uint8List>) {
      final bytes = result.data;
      _notifyDecoded(bytes.isNotEmpty);
      return bytes;
    }
    _notifyDecoded(false);
    return null;
  }

  void _notifyDecoded(bool success) {
    if (!mounted) return;
    widget.onDecoded?.call(success);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return FutureBuilder<Uint8List?>(
      future: _bytes,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (snapshot.connectionState != ConnectionState.done) {
          return ColoredBox(color: colors.input);
        }
        if (bytes == null || bytes.isEmpty) {
          return ColoredBox(
            color: colors.input,
            child: Icon(AppIcon.images, color: colors.textSecondary),
          );
        }
        return Image.memory(bytes, fit: widget.fit, gaplessPlayback: true);
      },
    );
  }
}

class EncryptedVaultImageThumb extends StatelessWidget {
  const EncryptedVaultImageThumb({
    super.key,
    required this.blobId,
    this.size,
    this.store,
  });

  final String blobId;
  final double? size;
  final EncryptedBlobStore? store;

  @override
  Widget build(BuildContext context) {
    final dimension = size ?? 40.s;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: SizedBox(
        width: dimension,
        height: dimension,
        child: EncryptedVaultImage(blobId: blobId, store: store),
      ),
    );
  }
}
