/// Document exporters for various file formats.

import 'dart:convert';
import '../models/document_model.dart';
import '../../domain/entities/document.dart';

/// Exports documents to various file formats.
abstract class DocumentExporter {
  /// Export document to string content.
  Future<String> export(Document document);

  /// Get supported file extensions for this exporter.
  List<String> get extensions;
}

/// Exports to XAN (H Writer Pro native format).
/// JSON-based format optimized for preservation of all formatting.
class XANExporter implements DocumentExporter {
  /// XAN file format version.
  final String version = '1.0.0';

  @override
  List<String> get extensions => ['.xan'];

  @override
  Future<String> export(Document document) async {
    try {
      final model = DocumentModel.fromDomain(document);
      final content = {
        'version': version,
        'document': model.toJson(),
      };
      return jsonEncode(content);
    } catch (e) {
      throw ExporterException('Failed to export to XAN: $e');
    }
  }
}

/// Exports to plain text format.
class PlainTextExporter implements DocumentExporter {
  @override
  List<String> get extensions => ['.txt'];

  @override
  Future<String> export(Document document) async {
    try {
      return document.paragraphs
          .map((p) => p.text)
          .join('\n');
    } catch (e) {
      throw ExporterException('Failed to export to plain text: $e');
    }
  }
}

/// Exports to Markdown format.
class MarkdownExporter implements DocumentExporter {
  @override
  List<String> get extensions => ['.md', '.markdown'];

  @override
  Future<String> export(Document document) async {
    try {
      final buffer = StringBuffer();
      buffer.writeln('# ${document.title}\n');

      for (final para in document.paragraphs) {
        if (para.isEmpty) {
          buffer.writeln();
        } else {
          // Simple markdown: detect formatting from attributes
          final text = para.text;
          if (para.attributes['bold'] == true && para.attributes['fontSize'] == 24) {
            buffer.writeln('# $text');
          } else if (para.attributes['bold'] == true && para.attributes['fontSize'] == 20) {
            buffer.writeln('## $text');
          } else {
            buffer.writeln(text);
          }
        }
      }

      return buffer.toString();
    } catch (e) {
      throw ExporterException('Failed to export to Markdown: $e');
    }
  }
}

/// Exports to CSV format (for tabular data).
class CSVExporter implements DocumentExporter {
  @override
  List<String> get extensions => ['.csv'];

  @override
  Future<String> export(Document document) async {
    try {
      final buffer = StringBuffer();
      // Write header
      buffer.writeln('Paragraph,Text,Attributes');

      for (final para in document.paragraphs) {
        final text = para.text.replaceAll('"', '""'); // Escape quotes
        final attrs = para.attributes.toString().replaceAll('"', '""');
        buffer.writeln('"${para.id}","$text","$attrs"');
      }

      return buffer.toString();
    } catch (e) {
      throw ExporterException('Failed to export to CSV: $e');
    }
  }
}

/// Registry of available exporters.
class ExporterRegistry {
  static final Map<String, DocumentExporter> _exporters = {
    '.xan': XANExporter(),
    '.txt': PlainTextExporter(),
    '.md': MarkdownExporter(),
    '.markdown': MarkdownExporter(),
    '.csv': CSVExporter(),
  };

  /// Get exporter for file extension.
  static DocumentExporter? getExporter(String extension) {
    return _exporters[extension.toLowerCase()];
  }

  /// Register custom exporter.
  static void registerExporter(String extension, DocumentExporter exporter) {
    _exporters[extension.toLowerCase()] = exporter;
  }

  /// Get all supported extensions.
  static List<String> getSupportedExtensions() {
    return _exporters.keys.toList();
  }
}

/// Exception thrown during export.
class ExporterException implements Exception {
  final String message;

  ExporterException(this.message);

  @override
  String toString() => 'ExporterException: $message';
}
