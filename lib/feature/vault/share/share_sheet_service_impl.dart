import 'package:keyva/feature/vault/share/share_sheet_service.dart';
import 'package:share_plus/share_plus.dart';

class ShareSheetServiceImpl implements ShareSheetService {
  ShareSheetServiceImpl({
    Future<ShareResult> Function(ShareParams params)? share,
  }) : _share = share ?? _defaultShare;

  final Future<ShareResult> Function(ShareParams params) _share;

  static Future<ShareResult> _defaultShare(ShareParams params) {
    return SharePlus.instance.share(params);
  }

  @override
  Future<ShareSheetResult> shareText({
    required String text,
    String? subject,
  }) async {
    if (text.isEmpty) {
      return ShareSheetResult.unavailable;
    }

    try {
      final result = await _share(
        ShareParams(text: text, subject: subject, title: subject),
      );
      return switch (result.status) {
        ShareResultStatus.success => ShareSheetResult.shared,
        ShareResultStatus.dismissed => ShareSheetResult.dismissed,
        ShareResultStatus.unavailable => ShareSheetResult.unavailable,
      };
    } catch (_) {
      return ShareSheetResult.unavailable;
    }
  }
}
