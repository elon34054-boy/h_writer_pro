@TestOn('vm')
import 'package:test/test.dart';
import 'package:h_writer_pro/core/domain/entities/document.dart';
import 'package:h_writer_pro/core/domain/entities/document_state_manager.dart';
import 'package:h_writer_pro/core/domain/entities/document_delta.dart';

void main() {
  group('DocumentStateManager Tests', () {
    late DocumentStateManager manager;
    late Document testDoc;

    setUp(() {
      testDoc = Document(
        title: 'Test Document',
        paragraphs: [Paragraph.simple(text: 'Initial content')],
      );
      manager = DocumentStateManager(initialDocument: testDoc);
    });

    group('Initialization', () {
      test('initializes with provided document', () {
        expect(manager.currentDocument, equals(testDoc));
      });

      test('starts with no undo/redo history', () {
        expect(manager.canUndo, isFalse);
        expect(manager.canRedo, isFalse);
        expect(manager.undoDepth, equals(0));
        expect(manager.redoDepth, equals(0));
      });

      test('document has no unsaved changes initially', () {
        expect(manager.hasUnsavedChanges, isFalse);
      });
    });

    group('Change Application', () {
      test('applyChange increments undo stack', () {
        final delta = DocumentDelta.insert('Test');
        manager.applyChange(delta);

        expect(manager.undoDepth, equals(1));
        expect(manager.canUndo, isTrue);
      });

      test('applyChange clears redo stack', () {
        final delta1 = DocumentDelta.insert('A');
        final delta2 = DocumentDelta.insert('B');

        manager.applyChange(delta1);
        manager.undo();
        expect(manager.canRedo, isTrue);

        manager.applyChange(delta2);
        expect(manager.canRedo, isFalse);
      });

      test('hasUnsavedChanges true after applying change', () {
        expect(manager.hasUnsavedChanges, isFalse);
        manager.applyChange(DocumentDelta.insert('Change'));
        expect(manager.hasUnsavedChanges, isTrue);
      });

      test('applyChange respects maxHistoryItems limit', () {
        final manager2 = DocumentStateManager(
          initialDocument: testDoc,
          maxHistoryItems: 5,
        );

        for (int i = 0; i < 10; i++) {
          manager2.applyChange(DocumentDelta.insert('$i'));
        }

        expect(manager2.undoDepth, equals(5));
      });
    });

    group('Undo/Redo Operations', () {
      test('undo removes last change from undo stack', () {
        manager.applyChange(DocumentDelta.insert('Test'));
        expect(manager.undoDepth, equals(1));

        final result = manager.undo();

        expect(result, isTrue);
        expect(manager.undoDepth, equals(0));
        expect(manager.redoDepth, equals(1));
      });

      test('undo fails when no changes to undo', () {
        final result = manager.undo();
        expect(result, isFalse);
      });

      test('redo restores undone change', () {
        manager.applyChange(DocumentDelta.insert('Test'));
        manager.undo();

        final result = manager.redo();

        expect(result, isTrue);
        expect(manager.undoDepth, equals(1));
        expect(manager.redoDepth, equals(0));
      });

      test('redo fails when no changes to redo', () {
        final result = manager.redo();
        expect(result, isFalse);
      });

      test('undo/redo cycle preserves changes', () {
        manager.applyChange(DocumentDelta.insert('Change1'));
        manager.applyChange(DocumentDelta.insert('Change2'));

        manager.undo();
        expect(manager.undoDepth, equals(1));
        manager.undo();
        expect(manager.undoDepth, equals(0));

        manager.redo();
        expect(manager.undoDepth, equals(1));
        manager.redo();
        expect(manager.undoDepth, equals(2));
      });
    });

    group('Batch Undo/Redo', () {
      test('undoMultiple undoes multiple changes', () {
        for (int i = 0; i < 5; i++) {
          manager.applyChange(DocumentDelta.insert('$i'));
        }

        final undone = manager.undoMultiple(3);

        expect(undone, equals(3));
        expect(manager.undoDepth, equals(2));
        expect(manager.redoDepth, equals(3));
      });

      test('redoMultiple redoes multiple changes', () {
        for (int i = 0; i < 5; i++) {
          manager.applyChange(DocumentDelta.insert('$i'));
        }

        manager.undoMultiple(5);
        final redone = manager.redoMultiple(3);

        expect(redone, equals(3));
        expect(manager.undoDepth, equals(3));
        expect(manager.redoDepth, equals(2));
      });

      test('undoMultiple stops at limit', () {
        for (int i = 0; i < 3; i++) {
          manager.applyChange(DocumentDelta.insert('$i'));
        }

        final undone = manager.undoMultiple(10);

        expect(undone, equals(3));
        expect(manager.undoDepth, equals(0));
      });
    });

    group('Document Update', () {
      test('updateDocument replaces current state', () {
        final newDoc = Document(
          id: testDoc.id,
          title: 'New Title',
          paragraphs: [Paragraph.simple(text: 'New content')],
        );

        manager.updateDocument(newDoc);

        expect(manager.currentDocument.title, equals('New Title'));
      });

      test('updateDocument clears redo stack', () {
        manager.applyChange(DocumentDelta.insert('Change'));
        manager.undo();
        expect(manager.canRedo, isTrue);

        final newDoc = Document(
          title: 'Different',
          paragraphs: [],
        );
        manager.updateDocument(newDoc);

        expect(manager.canRedo, isFalse);
      });
    });

    group('History Management', () {
      test('clearHistory removes all undo/redo history', () {
        manager.applyChange(DocumentDelta.insert('Change1'));
        manager.applyChange(DocumentDelta.insert('Change2'));
        manager.undo();

        manager.clearHistory();

        expect(manager.undoDepth, equals(0));
        expect(manager.redoDepth, equals(0));
      });

      test('getUndoHistory returns immutable list', () {
        manager.applyChange(DocumentDelta.insert('Change'));

        final history = manager.getUndoHistory();
        expect(history.length, equals(1));

        expect(() {
          history.add(DocumentDelta.insert('New'));
        }, throwsUnsupportedError);
      });

      test('getRedoHistory returns immutable list', () {
        manager.applyChange(DocumentDelta.insert('Change'));
        manager.undo();

        final history = manager.getRedoHistory();
        expect(history.length, equals(1));

        expect(() {
          history.add(DocumentDelta.insert('New'));
        }, throwsUnsupportedError);
      });
    });

    group('Snapshots', () {
      test('createSnapshot captures current state', () {
        manager.applyChange(DocumentDelta.insert('Change1'));
        manager.applyChange(DocumentDelta.insert('Change2'));

        final snapshot = manager.createSnapshot();

        expect(snapshot.document, equals(manager.currentDocument));
        expect(snapshot.undoStackSize, equals(2));
        expect(snapshot.redoStackSize, equals(0));
      });

      test('restoreSnapshot recovers saved state', () {
        manager.applyChange(DocumentDelta.insert('Change1'));
        final snapshot = manager.createSnapshot();

        manager.applyChange(DocumentDelta.insert('Change2'));
        manager.applyChange(DocumentDelta.insert('Change3'));
        expect(manager.undoDepth, equals(3));

        manager.restoreSnapshot(snapshot);

        expect(manager.undoDepth, equals(0));
        expect(manager.redoDepth, equals(0));
      });

      test('snapshot timestamp is set', () {
        final before = DateTime.now();
        final snapshot = manager.createSnapshot();
        final after = DateTime.now();

        expect(snapshot.timestamp.isAfter(before), isTrue);
        expect(snapshot.timestamp.isBefore(after) || 
               snapshot.timestamp.isAtSameMomentAs(after), isTrue);
      });
    });

    group('Listeners', () {
      test('listener called on change', () {
        var callCount = 0;
        manager.addListener((_) => callCount++);

        manager.applyChange(DocumentDelta.insert('Change'));

        expect(callCount, equals(1));
      });

      test('listener called on undo', () {
        manager.applyChange(DocumentDelta.insert('Change'));
        
        var callCount = 0;
        manager.addListener((_) => callCount++);

        manager.undo();

        expect(callCount, equals(1));
      });

      test('listener removed after unsubscribe', () {
        var callCount = 0;
        final listener = (_: Document) => callCount++;
        manager.addListener(listener);
        manager.removeListener(listener);

        manager.applyChange(DocumentDelta.insert('Change'));

        expect(callCount, equals(0));
      });

      test('multiple listeners all notified', () {
        var count1 = 0, count2 = 0;
        manager.addListener((_) => count1++);
        manager.addListener((_) => count2++);

        manager.applyChange(DocumentDelta.insert('Change'));

        expect(count1, equals(1));
        expect(count2, equals(1));
      });
    });

    group('State Summary', () {
      test('getSummary provides useful debug info', () {
        manager.applyChange(DocumentDelta.insert('Change'));
        manager.undo();

        final summary = manager.getSummary();
        expect(summary, contains('Test Document'));
        expect(summary, contains('undo: 0'));
        expect(summary, contains('redo: 1'));
      });
    });
  });
}
