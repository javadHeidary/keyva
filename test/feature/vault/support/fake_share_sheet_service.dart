import 'package:keyva/feature/vault/share/share_sheet_service.dart';

class FakeShareSheetService implements ShareSheetService {
  ShareSheetResult result = ShareSheetResult.shared;
  int shareCount = 0;
  String? lastText;
  String? lastSubject;

  @override
  Future<ShareSheetResult> shareText({
    required String text,
    String? subject,
  }) async {
    shareCount++;
    lastText = text;
    lastSubject = subject;
    return result;
  }
}
