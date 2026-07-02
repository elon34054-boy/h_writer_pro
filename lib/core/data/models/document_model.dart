/// Data models for serialization/deserialization.
/// These bridge domain entities and file formats.

import '../entities/document.dart';

/// Serializable document model (JSON-compatible).
class DocumentModel {
  final String id;
  final String title;
  final List<ParagraphModel> paragraphs;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final Map<String, dynamic> metadata;

  const DocumentModel({
    required this.id,
    required this.title,
    required this.paragraphs,
    required this.createdAt,
    required this.modifiedAt,
    required this.metadata,
  });

  /// Convert domain Document to JSON model.
  factory DocumentModel.fromDomain(Document document) {
    return DocumentModel(
      id: document.id,
      title: document.title,
      paragraphs: document.paragraphs
          .map((p) => ParagraphModel.fromDomain(p))
          .toList(),
      createdAt: document.createdAt,
      modifiedAt: document.modifiedAt,
      metadata: document.metadata,
    );
  }

  /// Convert JSON model back to domain Document.
  Document toDomain() {
    return Document(
      id: id,
      title: title,
      paragraphs: paragraphs.map((p) => p.toDomain()).toList(),
      createdAt: createdAt,
      modifiedAt: modifiedAt,
      metadata: metadata,
    );
  }

  /// Convert to JSON-serializable map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'paragraphs': paragraphs.map((p) => p.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Create from JSON map.
  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as String,
      title: json['title'] as String,
      paragraphs: (json['paragraphs'] as List<dynamic>)
          .map((p) => ParagraphModel.fromJson(p as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      modifiedAt: DateTime.parse(json['modifiedAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  @override
  String toString() => 'DocumentModel(id: $id, title: "$title", paragraphs: ${paragraphs.length})';
}

/// Serializable paragraph model.
class ParagraphModel {
  final String id;
  final List<TextRunModel> runs;
  final Map<String, dynamic> attributes;

  const ParagraphModel({
    required this.id,
    required this.runs,
    required this.attributes,
  });

  /// Convert domain Paragraph to model.
  factory ParagraphModel.fromDomain(Paragraph paragraph) {
    return ParagraphModel(
      id: paragraph.id,
      runs: paragraph.runs
          .map((r) => TextRunModel.fromDomain(r))
          .toList(),
      attributes: paragraph.attributes,
    );
  }

  /// Convert model back to domain Paragraph.
  Paragraph toDomain() {
    return Paragraph(
      id: id,
      runs: runs.map((r) => r.toDomain()).toList(),
      attributes: attributes,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'runs': runs.map((r) => r.toJson()).toList(),
      'attributes': attributes,
    };
  }

  /// Create from JSON.
  factory ParagraphModel.fromJson(Map<String, dynamic> json) {
    return ParagraphModel(
      id: json['id'] as String,
      runs: (json['runs'] as List<dynamic>)
          .map((r) => TextRunModel.fromJson(r as Map<String, dynamic>))
          .toList(),
      attributes: json['attributes'] as Map<String, dynamic>? ?? {},
    );
  }
}

/// Serializable text run model.
class TextRunModel {
  final String text;
  final List<TextAttributeModel> attributes;

  const TextRunModel({
    required this.text,
    required this.attributes,
  });

  /// Convert domain TextRun to model.
  factory TextRunModel.fromDomain(TextRun run) {
    return TextRunModel(
      text: run.text,
      attributes: run.attributes
          .map((a) => TextAttributeModel.fromDomain(a))
          .toList(),
    );
  }

  /// Convert model back to domain TextRun.
  TextRun toDomain() {
    return TextRun(
      text: text,
      attributes: attributes.map((a) => a.toDomain()).toList(),
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'attributes': attributes.map((a) => a.toJson()).toList(),
    };
  }

  /// Create from JSON.
  factory TextRunModel.fromJson(Map<String, dynamic> json) {
    return TextRunModel(
      text: json['text'] as String,
      attributes: (json['attributes'] as List<dynamic>? ?? [])
          .map((a) => TextAttributeModel.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Serializable text attribute model.
class TextAttributeModel {
  final String name;
  final dynamic value;

  const TextAttributeModel({
    required this.name,
    required this.value,
  });

  /// Convert domain TextAttribute to model.
  factory TextAttributeModel.fromDomain(TextAttribute attr) {
    return TextAttributeModel(
      name: attr.name,
      value: attr.value,
    );
  }

  /// Convert model back to domain TextAttribute.
  TextAttribute toDomain() {
    return TextAttribute(name: name, value: value);
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
    };
  }

  /// Create from JSON.
  factory TextAttributeModel.fromJson(Map<String, dynamic> json) {
    return TextAttributeModel(
      name: json['name'] as String,
      value: json['value'],
    );
  }
}
