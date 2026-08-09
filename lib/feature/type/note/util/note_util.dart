import 'package:keyva/feature/type/login/util/login_password_util.dart';

enum NoteLinkType { plain, url, email, phone }

class NoteTextSegment {
  const NoteTextSegment({required this.text, required this.type});

  final String text;
  final NoteLinkType type;
}

final _noteLinkPattern = RegExp(
  r'https?:\/\/[^\s]+|www\.[^\s]+|[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}|\+?[0-9][0-9\s\-()]{7,}[0-9]',
);

String formatNoteCreatedAt(DateTime dateTime) {
  final y = dateTime.year.toString().padLeft(4, '0');
  final m = dateTime.month.toString().padLeft(2, '0');
  final d = dateTime.day.toString().padLeft(2, '0');
  return '$y/$m/$d';
}

String previewNoteBody(String body, {int maxLength = 40}) {
  final line = body.split('\n').first.trim();
  if (line.isEmpty) return 'یادداشت';
  if (line.length <= maxLength) return line;
  return '${line.substring(0, maxLength)}…';
}

String? validateNoteTitleInput(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'عنوان الزامی است';
  }
  if (value.trim().length < 2) {
    return 'عنوان باید حداقل ۲ کاراکتر باشد';
  }
  return null;
}

String? validateNoteBodyInput(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'متن یادداشت الزامی است';
  }
  return null;
}

List<NoteTextSegment> parseNoteTextSegments(String text) {
  if (text.isEmpty) return const [];

  final segments = <NoteTextSegment>[];
  var index = 0;

  for (final match in _noteLinkPattern.allMatches(text)) {
    if (match.start > index) {
      segments.add(
        NoteTextSegment(
          text: text.substring(index, match.start),
          type: NoteLinkType.plain,
        ),
      );
    }
    final matched = match.group(0)!;
    segments.add(
      NoteTextSegment(text: matched, type: classifyNoteLink(matched)),
    );
    index = match.end;
  }

  if (index < text.length) {
    segments.add(
      NoteTextSegment(text: text.substring(index), type: NoteLinkType.plain),
    );
  }

  return segments;
}

NoteLinkType classifyNoteLink(String value) {
  if (value.contains('@') && _looksLikeEmail(value)) {
    return NoteLinkType.email;
  }
  if (value.startsWith('http://') ||
      value.startsWith('https://') ||
      value.startsWith('www.')) {
    return NoteLinkType.url;
  }
  if (RegExp(r'^\+?[0-9][0-9\s\-()]*[0-9]$').hasMatch(value)) {
    return NoteLinkType.phone;
  }
  return NoteLinkType.plain;
}

bool _looksLikeEmail(String value) {
  return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
      .hasMatch(value);
}

String? uriForNoteLink(NoteLinkType type, String raw) {
  switch (type) {
    case NoteLinkType.url:
      if (raw.startsWith('www.')) {
        return normalizeWebsiteUrl('https://$raw');
      }
      return normalizeWebsiteUrl(raw);
    case NoteLinkType.email:
      final email = raw.trim();
      if (!_looksLikeEmail(email)) return null;
      return 'mailto:$email';
    case NoteLinkType.phone:
      final digits = raw.replaceAll(RegExp(r'[^\d+]'), '');
      if (digits.isEmpty) return null;
      return 'tel:$digits';
    case NoteLinkType.plain:
      return null;
  }
}
