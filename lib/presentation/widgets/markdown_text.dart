import 'package:flutter/material.dart';

/// Renders simple markdown-like text with **bold** and *italic* support.
/// Converts `**text**` to bold and `*text*` to italic.
class MarkdownText extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;
  final bool selectable;

  const MarkdownText({
    super.key,
    required this.text,
    this.baseStyle,
    this.selectable = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = baseStyle ??
        theme.textTheme.bodySmall?.copyWith(
          height: 1.6,
          fontSize: 12,
          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
        );

    final spans = _parseMarkdown(text, style);

    if (selectable) {
      return SelectableText.rich(
        TextSpan(children: spans),
      );
    }
    return RichText(
      text: TextSpan(children: spans),
    );
  }

  List<TextSpan> _parseMarkdown(String input, TextStyle? style) {
    final spans = <TextSpan>[];

    // Clean up numbered lists: "1.  **Title:** text" → "1. Title: text" with bold
    // Process line by line for better control
    final lines = input.split('\n');
    for (int l = 0; l < lines.length; l++) {
      if (l > 0) spans.add(TextSpan(text: '\n', style: style));
      _parseLine(lines[l], style, spans);
    }

    return spans;
  }

  void _parseLine(String line, TextStyle? style, List<TextSpan> spans) {
    String clean = line;
    
    // Numbered lists
    final listMatch = RegExp(r'^(\d+\.\s+)(.*)').firstMatch(clean);
    if (listMatch != null) {
      spans.add(TextSpan(
        text: listMatch.group(1),
        style: style?.copyWith(fontWeight: FontWeight.w600),
      ));
      clean = listMatch.group(2) ?? '';
    }

    // Bullet points (matches *, -, or • followed by spaces)
    final bulletMatch = RegExp(r'^([\-\*•])\s+').firstMatch(clean);
    if (bulletMatch != null) {
      spans.add(TextSpan(
        text: '• ',
        style: style?.copyWith(fontWeight: FontWeight.w600),
      ));
      clean = clean.substring(bulletMatch.group(0)!.length);
    }

    // Parse bold and italic inline
    _parseInline(clean, style, spans);
  }

  void _parseInline(String text, TextStyle? style, List<TextSpan> spans) {
    // Clean up empty bold elements (like **** or ** **)
    String cleanText = text.replaceAll(RegExp(r'\*\*+\s*\*\*+'), '');

    int index = 0;
    while (index < cleanText.length) {
      // Check for bold double asterisk **
      if (index + 1 < cleanText.length && cleanText.substring(index, index + 2) == '**') {
        final nextIndex = cleanText.indexOf('**', index + 2);
        if (nextIndex != -1) {
          final content = cleanText.substring(index + 2, nextIndex);
          spans.add(TextSpan(
            text: content,
            style: style?.copyWith(fontWeight: FontWeight.w700),
          ));
          index = nextIndex + 2;
          continue;
        }
      }
      
      // Check for italic single asterisk *
      if (cleanText[index] == '*') {
        final nextIndex = cleanText.indexOf('*', index + 1);
        // Ensure it's a single asterisk, not a double asterisk
        if (nextIndex != -1 && (nextIndex + 1 >= cleanText.length || cleanText[nextIndex + 1] != '*')) {
          final content = cleanText.substring(index + 1, nextIndex);
          spans.add(TextSpan(
            text: content,
            style: style?.copyWith(fontStyle: FontStyle.italic),
          ));
          index = nextIndex + 1;
          continue;
        }
      }

      // Add normal character sequence up to the next special character
      int nextSpecial = cleanText.indexOf('*', index);
      if (nextSpecial == -1) {
        spans.add(TextSpan(text: cleanText.substring(index), style: style));
        break;
      } else {
        if (nextSpecial > index) {
          spans.add(TextSpan(text: cleanText.substring(index, nextSpecial), style: style));
        }
        index = nextSpecial;
      }
    }
  }
}
