/// Concrete implementation of DocumentRepository.

import 'dart:io';
import '../parsers/document_parser.dart';
import '../exporters/document_exporter.dart';
import '../../domain/repositories/document_repository.dart';
import '../../domain/entities/document.dart';

/// File-based document repository implementation.
class FileDocumentRepository implements DocumentRepository {
  @override
  List<String> get supportedExtensions {
    final extensions = <String>{};
    extensions.addAll(ParserRegistry.getSupportedExtensions());
    extensions.addAll(ExporterRegistry.getSupportedExtensions());
    return extensions.toList();
  }

  @override
  Future<Document> loadDocument(String filePath) async {
    try {
      final file = File(filePath);
      
      if (!await file.exists()) {
        throw DocumentException(
          message: 'File not found: $filePath',
        );
      }

      final content = await file.readAsString();
      final extension = _getExtension(filePath);
      final parser = ParserRegistry.getParser(extension);

      if (parser == null) {
        throw DocumentException(
          message: 'Unsupported file format: $extension',
        );
      }

      return await parser.parse(content);
    } catch (e, stackTrace) {
      throw DocumentException(
        message: 'Failed to load document: ${e.toString()}',
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> saveDocument(Document document, String filePath) async {
    try {
      if (!validateDocument(document)) {
        throw DocumentException(
          message: 'Invalid document: validation failed',
        );
      }

      final extension = _getExtension(filePath);
      final exporter = ExporterRegistry.getExporter(extension);

      if (exporter == null) {
        throw DocumentException(
          message: 'Unsupported export format: $extension',
        );
      }

      final content = await exporter.export(document);
      final file = File(filePath);
      await file.writeAsString(content);
    } catch (e, stackTrace) {
      throw DocumentException(
        message: 'Failed to save document: ${e.toString()}',
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> exportDocument(Document document, String filePath) async {
    // exportDocument is similar to saveDocument for file-based repo
    return saveDocument(document, filePath);
  }

  @override
  Future<void> deleteDocument(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e, stackTrace) {
      throw DocumentException(
        message: 'Failed to delete document: ${e.toString()}',
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<bool> fileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  @override
  Future<DateTime?> getLastModified(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final stat = await file.stat();
        return stat.modified;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  bool validateDocument(Document doc) {
    // Basic validation
    if (doc.title.isEmpty) return false;
    if (doc.paragraphs.isEmpty) return false;
    return true;
  }

  /// Get file extension from path.
  String _getExtension(String filePath) {
    final lastDot = filePath.lastIndexOf('.');
    if (lastDot > 0) {
      return filePath.substring(lastDot).toLowerCase();
    }
    return '';
  }
}
