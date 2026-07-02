part of 'document.dart';

/// Immutable paragraph within a document.
/// 
/// A paragraph is a logical unit of text, potentially with multiple
/// formatted runs and paragraph-level attributes (alignment, indentation, etc.).
final class Paragraph {
  /// Unique identifier for this paragraph.
  final String id;

  /// Text runs composing this paragraph.
  final List<TextRun> runs;

  /// Paragraph-level attributes (alignment, indentation, spacing, etc.).
  final Map<String, dynamic> attributes;

  /// Cached plain text for fast access.
  final String _text;

  /// Creates a new immutable [Paragraph].
  /// 
  /// [id] defaults to UUID-like identifier if not provided.
  Paragraph({
    String? id,
    required List<TextRun> runs,
    Map<String, dynamic>? attributes,
  })  : id = id ?? 'para_${DateTime.now().millisecondsSinceEpoch}',
        runs = List.unmodifiable(runs),
        attributes = attributes ?? const {},
        _text = _computeText(runs);

  /// Creates an empty paragraph (for new lines).
  Paragraph.empty({String? id})
      : this(
          id: id,
          runs: const [],
        );

  /// Creates a simple paragraph with single-run text.
  Paragraph.simple({
    required String text,
    String? id,
    List<TextAttribute>? attributes,
  }) : this(
    id: id,
    runs: [
      TextRun(
        text: text,
        attributes: attributes ?? const [],
      ),
    ],
  );

  /// Plain text content (concatenation of all runs).
  String get text => _text;

  /// Total character count in this paragraph.
  int get length => _text.length;

  /// Number of text runs.
  int get runCount => runs.length;

  /// Whether paragraph is empty.
  bool get isEmpty => _text.isEmpty;

  /// Get paragraph-level attribute.
  dynamic getAttribute(String name) => attributes[name];

  /// Create a copy with modified text.
  Paragraph copyWithText(String newText) {
    return Paragraph.simple(
      text: newText,
      id: id,
    );
  }

  /// Create a copy with modified runs.
  Paragraph copyWithRuns(List<TextRun> newRuns) {
    return Paragraph(
      id: id,
      runs: newRuns,
      attributes: attributes,
    );
  }

  /// Create a copy with updated attributes.
  Paragraph copyWithAttributes(Map<String, dynamic> updates) {
    final newAttrs = {...attributes, ...updates};
    return Paragraph(
      id: id,
      runs: runs,
      attributes: newAttrs,
    );
  }

  /// Get all attributes applied to a specific character position.
  Set<TextAttribute> getAttributesAt(int position) {
    if (position < 0 || position >= _text.length) {
      return {};
    }

    int offset = 0;
    for (final run in runs) {
      if (position < offset + run.length) {
        return {...run.attributes};
      }
      offset += run.length;
    }
    return {};
  }

  /// Iterate runs with their positions.
  Iterable<(TextRun, int, int)> iterateRunsWithPositions() sync* {
    int startPos = 0;
    for (final run in runs) {
      yield (run, startPos, startPos + run.length);
      startPos += run.length;
    }
  }

  @override
  String toString() => 'Paragraph(id: $id, text: "${text.substring(0, (text.length > 20 ? 20 : text.length))}${text.length > 20 ? '...' : ''}", runs: $runCount)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Paragraph) return false;
    return id == other.id &&
        _text == other._text &&
        _listsEqual(runs, other.runs) &&
        _mapsEqual(attributes, other.attributes);
  }

  @override
  int get hashCode => Object.hash(id, _text, Object.hashAll(runs));

  /// Compute concatenated text from runs.
  static String _computeText(List<TextRun> runs) {
    final buffer = StringBuffer();
    for (final run in runs) {
      buffer.write(run.text);
    }
    return buffer.toString();
  }

  /// Helper for comparing lists.
  static bool _listsEqual(List<TextRun> a, List<TextRun> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Helper for comparing maps.
  static bool _mapsEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}
