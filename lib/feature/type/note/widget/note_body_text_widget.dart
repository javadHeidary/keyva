import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/type/note/util/note_util.dart';

class NoteBodyTextWidget extends StatefulWidget {
  const NoteBodyTextWidget({
    super.key,
    required this.text,
    this.onLinkTap,
  });

  final String text;
  final void Function(NoteLinkType type, String value)? onLinkTap;

  @override
  State<NoteBodyTextWidget> createState() => _NoteBodyTextWidgetState();
}

class _NoteBodyTextWidgetState extends State<NoteBodyTextWidget> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();

    final colors = context.colors;
    final segments = parseNoteTextSegments(widget.text);

    if (segments.isEmpty) {
      return Text(
        '—',
        style: AppTypography.bodyMedium.copyWith(color: colors.textPrimary),
      );
    }

    final spans = <TextSpan>[];
    for (final segment in segments) {
      if (segment.type == NoteLinkType.plain) {
        spans.add(
          TextSpan(
            text: segment.text,
            style: AppTypography.bodyMedium.copyWith(color: colors.textPrimary),
          ),
        );
        continue;
      }

      final recognizer = TapGestureRecognizer()
        ..onTap = () => widget.onLinkTap?.call(segment.type, segment.text);
      _recognizers.add(recognizer);

      spans.add(
        TextSpan(
          text: segment.text,
          style: AppTypography.bodyMedium.copyWith(
            color: colors.primary,
            decoration: TextDecoration.underline,
          ),
          recognizer: recognizer,
        ),
      );
    }

    return SelectableText.rich(
      TextSpan(children: spans),
      textDirection: TextDirection.rtl,
    );
  }
}
