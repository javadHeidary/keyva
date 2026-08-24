enum ShareSheetResult { shared, dismissed, unavailable }

abstract interface class ShareSheetService {
  Future<ShareSheetResult> shareText({
    required String text,
    String? subject,
  });
}
