part of 'document_delta.dart';

/// Base class for all Delta operations.
/// Represents an atomic change to the document.
sealed class DeltaOperation {
  const DeltaOperation();

  /// Length of this operation in characters.
  int get length;
}

/// Insert operation: Add text with optional formatting attributes.
/// 
/// Represents the insertion of new text at a specific position.
/// Attributes define formatting (bold, italic, color, etc.).
final class InsertOperation extends DeltaOperation {
  /// The text being inserted.
  final String text;

  /// Optional formatting attributes (bold, italic, color, font size, etc.).
  /// Empty map means no formatting.
  final Map<String, dynamic> attributes;

  const InsertOperation({
    required this.text,
    this.attributes = const {},
  });

  @override
  int get length => text.length;

  @override
  String toString() => 'Insert("$text"${attributes.isNotEmpty ? ", attrs: $attributes" : ""})';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! InsertOperation) return false;
    return text == other.text && _mapsEqual(attributes, other.attributes);
  }

  @override
  int get hashCode => Object.hash(text, Object.hashAll(attributes.entries));
}

/// Delete operation: Remove text from the document.
/// 
/// Represents deletion of [count] characters at a position.
/// Does not include the deleted content (use invert() to recover).
final class DeleteOperation extends DeltaOperation {
  /// Number of characters to delete.
  final int count;

  const DeleteOperation({required this.count})
      : assert(count > 0, 'Delete count must be positive');

  @override
  int get length => 0; // Delete operations don't contribute to document length

  @override
  String toString() => 'Delete($count)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DeleteOperation) return false;
    return count == other.count;
  }

  @override
  int get hashCode => count.hashCode;
}

/// Retain operation: Keep existing text, optionally applying new attributes.
/// 
/// Represents skipping over [count] characters without modification,
/// or applying attributes to existing text.
final class RetainOperation extends DeltaOperation {
  /// Number of characters to retain.
  final int count;

  /// Optional attributes to apply to the retained text.
  /// Null means no attribute changes.
  final Map<String, dynamic>? attributes;

  const RetainOperation({
    required this.count,
    this.attributes,
  }) : assert(count > 0, 'Retain count must be positive');

  @override
  int get length => count;

  @override
  String toString() =>
      'Retain($count${attributes != null && attributes!.isNotEmpty ? ", attrs: $attributes" : ""})';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RetainOperation) return false;
    return count == other.count && _mapsEqual(attributes, other.attributes);
  }

  @override
  int get hashCode => Object.hash(count, attributes == null ? 0 : Object.hashAll(attributes!.entries));
}

/// Helper function for comparing maps with dynamic values.
bool _mapsEqual(Map<String, dynamic>? a, Map<String, dynamic>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return a == b;
  if (a.length != b.length) return false;

  for (final key in a.keys) {
    if (!b.containsKey(key)) return false;
    final aValue = a[key];
    final bValue = b[key];

    if (aValue is Map && bValue is Map) {
      if (!_mapsEqual(aValue as Map<String, dynamic>, bValue as Map<String, dynamic>)) {
        return false;
      }
    } else if (aValue is List && bValue is List) {
      if (aValue.length != bValue.length) return false;
      for (int i = 0; i < aValue.length; i++) {
        if (aValue[i] != bValue[i]) return false;
      }
    } else if (aValue != bValue) {
      return false;
    }
  }

  return true;
}
