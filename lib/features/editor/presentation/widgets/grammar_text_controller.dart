import 'package:flutter/material.dart';

/// Represents a detected grammar, spelling, or tone error in text.
class GrammarError {
  final int start;
  final int end;
  final String originalText;
  final List<String> suggestions;
  final String explanation;
  final GrammarErrorType type;

  const GrammarError({
    required this.start,
    required this.end,
    required this.originalText,
    required this.suggestions,
    required this.explanation,
    this.type = GrammarErrorType.grammar,
  });
}

enum GrammarErrorType {
  grammar,
  spelling,
  clarity,
  tone,
}

/// A specialized [TextEditingController] that customizes [buildTextSpan]
/// to paint red/amber wavy squiggly underlines on detected error spans.
class GrammarTextEditingController extends TextEditingController {
  List<GrammarError> _errors = [];

  GrammarTextEditingController({
    super.text,
    List<GrammarError>? errors,
  }) {
    if (errors != null) {
      _errors = errors;
    }
  }


  /// Current list of active errors to highlight.
  List<GrammarError> get errors => List.unmodifiable(_errors);

  /// Update errors without triggering a notification (e.g. during text editing change callback)
  void setErrorsSilently(List<GrammarError> newErrors) {
    _errors = List.from(newErrors);
  }

  /// Update the active errors and rebuild the text rendering.
  set errors(List<GrammarError> newErrors) {
    _errors = List.from(newErrors);
    notifyListeners();
  }

  /// Clear all active highlights.
  void clearErrors() {
    _errors.clear();
    notifyListeners();
  }


  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (_errors.isEmpty || text.isEmpty) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }

    final spans = <InlineSpan>[];
    int currentOffset = 0;

    // Filter and sort errors by their starting character position
    final sortedErrors = _errors
        .where((e) => e.start >= 0 && e.end <= text.length && e.start < e.end)
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    for (final error in sortedErrors) {
      // Avoid overlapping conflicts
      if (error.start < currentOffset) {
        continue;
      }

      // Normal text before the error
      if (error.start > currentOffset) {
        spans.add(
          TextSpan(
            text: text.substring(currentOffset, error.start),
            style: style,
          ),
        );
      }

      // Error segment with wavy squiggly underline
      final errorColor = _getColorForType(error.type);
      final errorText = text.substring(error.start, error.end);

      spans.add(
        TextSpan(
          text: errorText,
          style: style?.copyWith(
            decoration: TextDecoration.underline,
            decorationColor: errorColor,
            decorationStyle: TextDecorationStyle.wavy,
            decorationThickness: 2.0,
          ) ?? TextStyle(
            decoration: TextDecoration.underline,
            decorationColor: errorColor,
            decorationStyle: TextDecorationStyle.wavy,
            decorationThickness: 2.0,
          ),
        ),
      );

      currentOffset = error.end;
    }

    // Remaining text after last error
    if (currentOffset < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(currentOffset),
          style: style,
        ),
      );
    }

    return TextSpan(style: style, children: spans);
  }

  Color _getColorForType(GrammarErrorType type) {
    switch (type) {
      case GrammarErrorType.grammar:
        return const Color(0xFFEF4444); // Red
      case GrammarErrorType.spelling:
        return const Color(0xFFF97316); // Orange
      case GrammarErrorType.clarity:
        return const Color(0xFF3B82F6); // Blue
      case GrammarErrorType.tone:
        return const Color(0xFF8B5CF6); // Purple
    }
  }
}
