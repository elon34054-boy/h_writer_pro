/// Document state manager with undo/redo support.
/// Maintains document history and enables efficient state navigation.

import 'document_delta.dart';
import 'document.dart';

/// Manages document state with full undo/redo history.
/// 
/// Tracks changes using Deltas (not raw content) for efficient memory usage
/// and supports rich state navigation.
class DocumentStateManager {
  /// Current document state.
  Document _currentDocument;

  /// Stack of applied changes (for undo).
  final List<_DocumentHistoryEntry> _undoStack = [];

  /// Stack of undone changes (for redo).
  final List<_DocumentHistoryEntry> _redoStack = [];

  /// Maximum history items to keep (prevents memory bloat).
  final int maxHistoryItems;

  /// Whether to auto-save snapshots at intervals.
  final bool autoSnapshot;

  /// Change listeners notified on state change.
  final List<void Function(Document)> _listeners = [];

  /// Creates a new [DocumentStateManager].
  DocumentStateManager({
    required Document initialDocument,
    this.maxHistoryItems = 1000,
    this.autoSnapshot = false,
  }) : _currentDocument = initialDocument;

  /// Current document state.
  Document get currentDocument => _currentDocument;

  /// Current undo history depth.
  int get undoDepth => _undoStack.length;

  /// Current redo history depth.
  int get redoDepth => _redoStack.length;

  /// Whether undo is available.
  bool get canUndo => _undoStack.isNotEmpty;

  /// Whether redo is available.
  bool get canRedo => _redoStack.isNotEmpty;

  /// Register listener for state changes.
  void addListener(void Function(Document) listener) {
    _listeners.add(listener);
  }

  /// Unregister listener.
  void removeListener(void Function(Document) listener) {
    _listeners.remove(listener);
  }

  /// Apply a change Delta to the document.
  /// 
  /// Updates current state and clears redo history.
  void applyChange(DocumentDelta delta) {
    if (delta.isEmpty) return;

    final previousText = _currentDocument.toPlainText();
    _undoStack.add(_DocumentHistoryEntry(
      delta: delta,
      previousText: previousText,
    ));
    _redoStack.clear();

    _currentDocument = _buildDocumentFromText(
      delta.applyToText(previousText),
      title: _currentDocument.title,
      documentId: _currentDocument.id,
      createdAt: _currentDocument.createdAt,
      metadata: _currentDocument.metadata,
    );

    if (_undoStack.length > maxHistoryItems) {
      _undoStack.removeAt(0);
    }

    _notifyListeners();
  }

  /// Update the entire document (replaces current state).
  void updateDocument(Document newDocument) {
    _currentDocument = newDocument;
    _redoStack.clear();
    _notifyListeners();
  }

  /// Undo last change.
  /// 
  /// Moves change from undo stack to redo stack.
  bool undo() {
    if (!canUndo) return false;

    final entry = _undoStack.removeLast();
    _redoStack.add(entry);
    _currentDocument = _buildDocumentFromText(
      entry.previousText,
      title: _currentDocument.title,
      documentId: _currentDocument.id,
      createdAt: _currentDocument.createdAt,
      metadata: _currentDocument.metadata,
    );
    _notifyListeners();
    return true;
  }

  /// Redo last undone change.
  /// 
  /// Moves change from redo stack to undo stack.
  bool redo() {
    if (!canRedo) return false;

    final entry = _redoStack.removeLast();
    _undoStack.add(entry);
    _currentDocument = _buildDocumentFromText(
      entry.delta.applyToText(_currentDocument.toPlainText()),
      title: _currentDocument.title,
      documentId: _currentDocument.id,
      createdAt: _currentDocument.createdAt,
      metadata: _currentDocument.metadata,
    );
    _notifyListeners();
    return true;
  }

  /// Undo multiple changes.
  int undoMultiple(int count) {
    int undone = 0;
    for (int i = 0; i < count && canUndo; i++) {
      undo();
      undone++;
    }
    return undone;
  }

  /// Redo multiple changes.
  int redoMultiple(int count) {
    int redone = 0;
    for (int i = 0; i < count && canRedo; i++) {
      redo();
      redone++;
    }
    return redone;
  }

  /// Clear all history (keep current state).
  void clearHistory() {
    _undoStack.clear();
    _redoStack.clear();
  }

  /// Get entire undo history as list.
  List<DocumentDelta> getUndoHistory() =>
      List.unmodifiable(_undoStack.map((entry) => entry.delta).toList());

  /// Get entire redo history as list.
  List<DocumentDelta> getRedoHistory() =>
      List.unmodifiable(_redoStack.map((entry) => entry.delta).toList());

  /// Create a snapshot of current state for later restoration.
  DocumentSnapshot createSnapshot() {
    return DocumentSnapshot(
      document: _currentDocument,
      undoStackSize: _undoStack.length,
      redoStackSize: _redoStack.length,
      timestamp: DateTime.now(),
    );
  }

  /// Restore from a snapshot.
  void restoreSnapshot(DocumentSnapshot snapshot) {
    _currentDocument = snapshot.document;
    _undoStack.clear();
    _redoStack.clear();
    _notifyListeners();
  }

  /// Check if document has unsaved changes.
  bool get hasUnsavedChanges => _undoStack.isNotEmpty;

  /// Notify all listeners of state change.
  void _notifyListeners() {
    for (final listener in _listeners) {
      listener(_currentDocument);
    }
  }

  Document _buildDocumentFromText(
    String content, {
    required String title,
    required String documentId,
    required DateTime createdAt,
    required Map<String, dynamic> metadata,
  }) {
    final paragraphs = content.split('\n').map((line) {
      return Paragraph.simple(text: line);
    }).toList();

    return Document(
      id: documentId,
      title: title,
      paragraphs: paragraphs,
      createdAt: createdAt,
      modifiedAt: DateTime.now(),
      metadata: metadata,
    );
  }

  /// Get summary of current state.
  String getSummary() {
    return 'DocumentState(document: ${_currentDocument.title}, '
        'undo: ${_undoStack.length}, redo: ${_redoStack.length})';
  }
}

/// Represents a history entry for undo/redo stacks.
class _DocumentHistoryEntry {
  final DocumentDelta delta;
  final String previousText;

  _DocumentHistoryEntry({
    required this.delta,
    required this.previousText,
  });
}

/// Snapshot of document state at a point in time.
class DocumentSnapshot {
  /// Document state at snapshot time.
  final Document document;

  /// Undo stack size at snapshot.
  final int undoStackSize;

  /// Redo stack size at snapshot.
  final int redoStackSize;

  /// When snapshot was created.
  final DateTime timestamp;

  const DocumentSnapshot({
    required this.document,
    required this.undoStackSize,
    required this.redoStackSize,
    required this.timestamp,
  });

  @override
  String toString() =>
      'DocumentSnapshot(title: ${document.title}, timestamp: $timestamp)';
}
