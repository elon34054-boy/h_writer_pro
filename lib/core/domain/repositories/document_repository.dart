/// Abstract repository for document file operations.
/// Domain-layer interface, no implementation details.

import 'document.dart';

/// Defines contract for document persistence operations.
/// 
/// Implementations handle specific file formats (XAN, DOCX, PDF, etc.)
/// without exposing format-specific logic to domain layer.
abstract class DocumentRepository {
  /// Load a document from file path.
  /// 
  /// Returns the loaded [Document], or throws exception on failure.
  Future<Document> loadDocument(String filePath);

  /// Save document to file path.
  /// 
  /// Creates file if it doesn't exist, overwrites if it does.
  Future<void> saveDocument(Document document, String filePath);

  /// Export document to format specified in [filePath] extension.
  /// 
  /// Supports multiple export formats based on file extension.
  Future<void> exportDocument(Document document, String filePath);

  /// Delete document file.
  Future<void> deleteDocument(String filePath);

  /// Check if file exists and is readable.
  Future<bool> fileExists(String filePath);

  /// Get last modified time of document file.
  Future<DateTime?> getLastModified(String filePath);

  /// Get supported file extensions (e.g., ['.xan', '.txt', '.docx']).
  List<String> get supportedExtensions;

  /// Validate document before saving.
  bool validateDocument(Document doc);
}

/// Result of document export operation.
class ExportResult {
  /// Path where document was exported.
  final String filePath;

  /// Bytes written.
  final int bytesWritten;

  /// Operation duration.
  final Duration duration;

  /// Whether export was successful.
  final bool success;

  /// Error message if export failed.
  final String? error;

  const ExportResult({
    required this.filePath,
    required this.bytesWritten,
    required this.duration,
    required this.success,
    this.error,
  });

  @override
  String toString() => 'ExportResult(path: $filePath, success: $success, bytes: $bytesWritten)';
}

/// Exception thrown by document operations.
class DocumentException implements Exception {
  /// Error message.
  final String message;

  /// Underlying cause.
  final dynamic cause;

  /// Stack trace.
  final StackTrace? stackTrace;

  DocumentException({
    required this.message,
    this.cause,
    this.stackTrace,
  });

  @override
  String toString() => 'DocumentException: $message${cause != null ? '\nCause: $cause' : ''}';
}
