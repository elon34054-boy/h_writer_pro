/// Document parsers for various file formats.

import 'dart:convert';
import '../models/document_model.dart';
import '../../domain/entities/document.dart';

/// Parses documents from file content.
abstract class DocumentParser {
  /// Parse raw file content into a Document.
  /// 
  /// Throws [ParserException] on invalid format.
  Future<Document> parse(String content);

  /// Get supported file extensions for this parser.
  List<String> get extensions;
}

/// Parses XAN (H Writer Pro native format) documents.
/// Uses JSON-based format for human readability and ease of parsing.
class XANParser implements DocumentParser {
  @override
  List<String> get extensions => ['.xan'];

  @override
  Future<Document> parse(String content) async {
    try {
      final json = jsonDecode(content) as Map<String, dynamic>;
      
      // Validate XAN format
      if (json['version'] == null) {
        throw ParserException('Missing XAN version');
      }
      
      final model = DocumentModel.fromJson(json['document'] as Map<String, dynamic>);
      return model.toDomain();
    } catch (e) {
      throw ParserException('Failed to parse XAN file: $e');
    }
  }
}

/// Parses plain text files.
class PlainTextParser implements DocumentParser {
  @override
  List<String> get extensions => ['.txt'];

  @override
  Future<Document> parse(String content) async {
    try {
      // Split by newlines and create paragraphs
      final lines = content.split('\n');
      final paragraphs = lines
          .map((line) => Paragraph.simple(text: line))
          .toList();

      return Document(
        title: 'Imported Text',
        paragraphs: paragraphs.isEmpty ? [Paragraph.empty()] : paragraphs,
      );
    } catch (e) {
      throw ParserException('Failed to parse plain text: $e');
    }
  }
}

/// Parses Markdown files.
class MarkdownParser implements DocumentParser {
  @override
  List<String> get extensions => ['.md', '.markdown'];

  @override
  Future<Document> parse(String content) async {
    try {
      final lines = content.split('\n');
      final paragraphs = <Paragraph>[];

      for (final line in lines) {
        if (line.startsWith('# ')) {
          // Heading level 1
          paragraphs.add(Paragraph.simple(
            text: line.replaceFirst('# ', ''),
            attributes: {'bold': true, 'fontSize': 24},
          ));
        } else if (line.startsWith('## ')) {
          // Heading level 2
          paragraphs.add(Paragraph.simple(
            text: line.replaceFirst('## ', ''),
            attributes: {'bold': true, 'fontSize': 20},
          ));
        } else if (line.isNotEmpty) {
          paragraphs.add(Paragraph.simple(text: line));
        } else {
          paragraphs.add(Paragraph.empty());
        }
      }

      return Document(
        title: 'Imported Markdown',
        paragraphs: paragraphs.isEmpty ? [Paragraph.empty()] : paragraphs,
      );
    } catch (e) {
      throw ParserException('Failed to parse Markdown: $e');
    }
  }
}

/// Registry of available parsers.
class ParserRegistry {
  static final Map<String, DocumentParser> _parsers = {
    '.xan': XANParser(),
    '.txt': PlainTextParser(),
    '.md': MarkdownParser(),
    '.markdown': MarkdownParser(),
  };

  /// Get parser for file extension.
  static DocumentParser? getParser(String extension) {
    return _parsers[extension.toLowerCase()];
  }

  /// Register custom parser.
  static void registerParser(String extension, DocumentParser parser) {
    _parsers[extension.toLowerCase()] = parser;
  }

  /// Get all supported extensions.
  static List<String> getSupportedExtensions() {
    return _parsers.keys.toList();
  }
}

/// Exception thrown during parsing.
class ParserException implements Exception {
  final String message;

  ParserException(this.message);

  @override
  String toString() => 'ParserException: $message';
}
