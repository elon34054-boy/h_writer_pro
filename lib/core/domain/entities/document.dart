/// Document content model with paragraph structure.
/// Pure Dart 3.x, zero Flutter dependencies.

part 'text_attribute.dart';
part 'paragraph.dart';

/// Immutable representation of document content as a collection of paragraphs.
/// 
/// A Document is the container for all content, maintaining paragraphs
/// and metadata without any UI-specific concerns.
final class Document {
  /// Unique identifier for this document.
  final String id;

  /// Document title/name.
  final String title;

  /// Immutable list of paragraphs composing the document.
  final List<Paragraph> paragraphs;

  /// Document creation timestamp.
  final DateTime createdAt;

  /// Last modification timestamp.
  final DateTime modifiedAt;

  /// Optional document metadata (author, category, tags, etc.).
  final Map<String, dynamic> metadata;

  /// Cached total character count.
  final int _length;

  /// Creates a new immutable [Document].
  /// 
  /// [id] defaults to a UUID-like identifier.
  /// [paragraphs] becomes immutable internally.
  Document({
    String? id,
    required this.title,
    required List<Paragraph> paragraphs,
    DateTime? createdAt,
    DateTime? modifiedAt,
    Map<String, dynamic>? metadata,
  })  : id = id ?? 'doc_${DateTime.now().millisecondsSinceEpoch}',
        paragraphs = List.unmodifiable(paragraphs),
        createdAt = createdAt ?? DateTime.now(),
        modifiedAt = modifiedAt ?? DateTime.now(),
        metadata = Map.unmodifiable(metadata ?? {}),
        _length = _computeLength(paragraphs);

  Document._internal({
    required this.id,
    required this.title,
    required List<Paragraph> paragraphs,
    required this.createdAt,
    required this.modifiedAt,
    required Map<String, dynamic> metadata,
    required int length,
  })  : paragraphs = List.unmodifiable(paragraphs),
        metadata = Map.unmodifiable(metadata),
        _length = length;

  /// Total character count in the document.
  int get length => _length;

  /// Number of paragraphs.
  int get paragraphCount => paragraphs.length;

  /// Whether document is empty.
  bool get isEmpty => paragraphs.isEmpty || _length == 0;

  /// Creates a new Document with updated title.
  Document copyWithTitle(String newTitle) {
    return Document(
      id: id,
      title: newTitle,
      paragraphs: paragraphs,
      createdAt: createdAt,
      modifiedAt: DateTime.now(),
      metadata: metadata,
    );
  }

  /// Creates a new Document with updated paragraphs.
  Document copyWithParagraphs(List<Paragraph> newParagraphs) {
    return Document(
      id: id,
      title: title,
      paragraphs: newParagraphs,
      createdAt: createdAt,
      modifiedAt: DateTime.now(),
      metadata: metadata,
    );
  }

  /// Creates a new Document with updated metadata.
  Document copyWithMetadata(Map<String, dynamic> updates) {
    final newMetadata = {...metadata, ...updates};
    return Document(
      id: id,
      title: title,
      paragraphs: paragraphs,
      createdAt: createdAt,
      modifiedAt: DateTime.now(),
      metadata: newMetadata,
    );
  }

  /// Convert entire document to plain text (for export/display).
  String toPlainText() {
    return paragraphs.map((p) => p.text).join('\n');
  }

  /// Iterate all paragraphs with their indices.
  Iterable<(int, Paragraph)> iterateWithIndex() sync* {
    for (int i = 0; i < paragraphs.length; i++) {
      yield (i, paragraphs[i]);
    }
  }

  @override
  String toString() => 'Document(id: $id, title: "$title", paragraphs: $paragraphCount)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Document) return false;
    return id == other.id &&
        title == other.title &&
        _listsEqual(paragraphs, other.paragraphs) &&
        createdAt.isAtSameMomentAs(other.createdAt) &&
        modifiedAt.isAtSameMomentAs(other.modifiedAt) &&
        _mapsEqual(metadata, other.metadata);
  }

  @override
  int get hashCode => Object.hash(
        id,
        title,
        createdAt,
        modifiedAt,
        Object.hashAll(paragraphs),
        Object.hashAll(metadata.entries),
      );

  /// Compute total length from paragraphs.
  static int _computeLength(List<Paragraph> paragraphs) {
    int length = 0;
    for (final p in paragraphs) {
      length += p.length + 1; // +1 for paragraph separator
    }
    return length > 0 ? length - 1 : 0; // Don't count final separator
  }

  /// Helper for comparing lists of paragraphs.
  static bool _listsEqual(List<Paragraph> a, List<Paragraph> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Helper for comparing metadata maps.
  static bool _mapsEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}
