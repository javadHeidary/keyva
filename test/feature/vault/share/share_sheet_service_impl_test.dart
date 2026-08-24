import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/feature/vault/share/share_sheet_service.dart';
import 'package:keyva/feature/vault/share/share_sheet_service_impl.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  test('maps success, dismissed, and unavailable without using clipboard', () async {
    late ShareParams captured;
    final service = ShareSheetServiceImpl(
      share: (params) async {
        captured = params;
        return const ShareResult('', ShareResultStatus.success);
      },
    );

    final shared = await service.shareText(text: 'payload', subject: 'Keyva');
    expect(shared, ShareSheetResult.shared);
    expect(captured.text, 'payload');
    expect(captured.subject, 'Keyva');

    final dismissed = ShareSheetServiceImpl(
      share: (_) async => const ShareResult('', ShareResultStatus.dismissed),
    );
    expect(
      await dismissed.shareText(text: 'payload'),
      ShareSheetResult.dismissed,
    );

    final unavailable = ShareSheetServiceImpl(
      share: (_) async => ShareResult.unavailable,
    );
    expect(
      await unavailable.shareText(text: 'payload'),
      ShareSheetResult.unavailable,
    );
  });

  test('returns unavailable when the platform share throws', () async {
    final service = ShareSheetServiceImpl(
      share: (_) async => throw Exception('platform'),
    );
    expect(
      await service.shareText(text: 'payload'),
      ShareSheetResult.unavailable,
    );
  });

  test('returns unavailable for empty text', () async {
    var called = false;
    final service = ShareSheetServiceImpl(
      share: (_) async {
        called = true;
        return const ShareResult('', ShareResultStatus.success);
      },
    );
    expect(await service.shareText(text: ''), ShareSheetResult.unavailable);
    expect(called, isFalse);
  });
}
