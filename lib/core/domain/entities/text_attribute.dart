part of 'document.dart';

/// Immutable text formatting attributes.
/// 
/// Represents formatting applied to text runs (bold, italic, font size, etc.).
final class TextAttribute {
  /// Attribute name (e.g., 'bold', 'italic', 'fontSize', 'color').
  final String name;

  /// Attribute value (e.g., true, false, 12, '#FF0000').
  final dynamic value;

  const TextAttribute({
    required this.name,
    required this.value,
  });

  /// Common attribute constructors for convenience.
  
  const TextAttribute.bold([bool enabled = true])
      : name = 'bold',
        value = enabled;

  const TextAttribute.italic([bool enabled = true])
      : name = 'italic',
        value = enabled;

  const TextAttribute.underline([bool enabled = true])
      : name = 'underline',
        value = enabled;

  const TextAttribute.strikethrough([bool enabled = true])
      : name = 'strikethrough',
        value = enabled;

  const TextAttribute.fontSize(int size)
      : name = 'fontSize',
        value = size;

  const TextAttribute.fontFamily(String family)
      : name = 'fontFamily',
        value = family;

  const TextAttribute.color(String hex)
      : name = 'color',
        value = hex;

  const TextAttribute.backgroundColor(String hex)
      : name = 'backgroundColor',
        value = hex;

  const TextAttribute.alignment(String align)
      : name = 'alignment',
        value = align;

  @override
  String toString() => '$name: $value';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TextAttribute) return false;
    return name == other.name && value == other.value;
  }

  @override
  int get hashCode => Object.hash(name, value);
}

/// Immutable text run with formatting.
final class TextRun {
  /// The actual text content.
  final String text;

  /// Formatting attributes applied to this run.
  final List<TextAttribute> attributes;

  const TextRun({
    required this.text,
    this.attributes = const [],
  });

  /// Length of this run in characters.
  int get length => text.length;

  @override
  String toString() => 'TextRun("$text", attrs: ${attributes.length})';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TextRun) return false;
    return text == other.text && _listsEqual(attributes, other.attributes);
  }

  @override
  int get hashCode => Object.hash(text, Object.hashAll(attributes));

  static bool _listsEqual(List<TextAttribute> a, List<TextAttribute> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
