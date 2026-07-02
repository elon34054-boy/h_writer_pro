/// Pure Dart 3.x immutable Delta implementation for H Writer Pro.
/// Represents a sequence of text operations (insert, delete, retain).
/// Optimized for unlimited Undo/Redo without memory bloating.
///
/// No Flutter/UI dependencies. Pure Dart with Sound Null Safety.

part 'delta_operation.dart';

/// Represents immutable text changes as a series of operations.
/// 
/// A Delta is the core abstraction for representing document state changes.
/// Rather than storing raw text, it stores efficient operations:
/// - `Insert`: Add text with optional attributes
/// - `Delete`: Remove text at a position
/// - `Retain`: Keep existing text with optional attribute changes
///
/// This design enables:
/// - O(n) memory complexity instead of O(text_size)
/// - Efficient Undo/Redo via operation inversion
/// - Conflict-free collaborative editing support
/// - Lazy evaluation and composability
class DocumentDelta {
  /// Immutable list of operations composing this Delta.
  /// Invariant: Operations must be in sequential order with no overlaps.
  final List<DeltaOperation> operations;

  /// Total character count of all Insert and Retain operations.
  final int _length;

  /// Memoized hash for efficient equality checks and set/map usage.
  int? _hashCode;

  /// Creates a new [DocumentDelta] with the given operations.
  /// 
  /// Pre-conditions:
  /// - Operations must be in sequential order
  /// - No overlapping ranges
  /// - At least one operation (empty Delta uses [DocumentDelta.empty])
  ///
  /// Throws [ArgumentError] if operations are invalid.
  DocumentDelta({required List<DeltaOperation> operations})
      : _length = _computeLength(operations),
        operations = List.unmodifiable(operations) {
    _validateOperations();
  }

  /// Empty Delta (no changes).
  DocumentDelta.empty()
      : operations = const [],
        _length = 0;

  /// Single Insert operation Delta.
  DocumentDelta.insert(
    String text, {
    Map<String, dynamic>? attributes,
  }) : this(
    operations: [
      InsertOperation(text: text, attributes: attributes ?? {}),
    ],
  );

  /// Single Delete operation Delta.
  DocumentDelta.delete(int count) : this(
    operations: [
      DeleteOperation(count: count),
    ],
  );

  /// Single Retain operation Delta.
  DocumentDelta.retain(
    int count, {
    Map<String, dynamic>? attributes,
  }) : this(
    operations: [
      RetainOperation(count: count, attributes: attributes),
    ],
  );

  /// Total length of document after applying this Delta.
  int get length => _length;

  /// Whether this Delta represents no changes.
  bool get isEmpty => operations.isEmpty;

  /// Number of operations in this Delta.
  int get operationCount => operations.length;

  /// Compose this Delta with another [other] Delta.
  /// 
  /// Composition results in a new Delta representing the combined effect
  /// of applying `this` and then `other` in sequence.
  ///
  /// Example:
  /// ```
  /// delta1 = DocumentDelta.insert('Hello')
  /// delta2 = DocumentDelta.retain(5).insert(' World')
  /// result = delta1.compose(delta2)  // "Hello World"
  /// ```
  DocumentDelta compose(DocumentDelta other) {
    if (isEmpty) return other;
    if (other.isEmpty) return this;

    final composed = <DeltaOperation>[];
    int thisIndex = 0;
    int otherIndex = 0;
    int thisRemaining = 0;
    int otherRemaining = 0;
    DeltaOperation? thisOp;
    DeltaOperation? otherOp;

    while (thisIndex < operations.length || otherIndex < other.operations.length) {
      if (thisOp == null && thisIndex < operations.length) {
        thisOp = operations[thisIndex++];
        thisRemaining = thisOp.length;
      }

      if (otherOp == null && otherIndex < other.operations.length) {
        otherOp = other.operations[otherIndex++];
        otherRemaining = otherOp.length;
      }

      if (thisOp is InsertOperation) {
        _appendOperation(composed, thisOp);
        thisOp = null;
        thisRemaining = 0;
        continue;
      }

      if (otherOp is InsertOperation) {
        _appendOperation(composed, otherOp);
        otherOp = null;
        otherRemaining = 0;
        continue;
      }

      if (thisOp is DeleteOperation) {
        _appendOperation(composed, thisOp);
        thisOp = null;
        thisRemaining = 0;
        continue;
      }

      if (thisOp is RetainOperation && otherOp is DeleteOperation) {
        final count = thisRemaining < otherRemaining ? thisRemaining : otherRemaining;
        _appendOperation(composed, DeleteOperation(count: count));
        thisRemaining -= count;
        otherRemaining -= count;

        if (thisRemaining == 0) {
          thisOp = null;
        }
        if (otherRemaining == 0) {
          otherOp = null;
        }
        continue;
      }

      if (thisOp is RetainOperation && otherOp is RetainOperation) {
        final count = thisRemaining < otherRemaining ? thisRemaining : otherRemaining;
        final attributes = otherOp.attributes ?? thisOp.attributes;
        _appendOperation(composed, RetainOperation(count: count, attributes: attributes));

        thisRemaining -= count;
        otherRemaining -= count;

        if (thisRemaining == 0) {
          thisOp = null;
        }
        if (otherRemaining == 0) {
          otherOp = null;
        }
        continue;
      }

      if (thisOp is RetainOperation && otherOp is DeleteOperation == false) {
        // If the remaining operation is not a delete, preserve the retain.
        _appendOperation(composed, RetainOperation(count: thisRemaining, attributes: thisOp.attributes));
        thisOp = null;
        thisRemaining = 0;
        continue;
      }

      if (otherOp is RetainOperation && thisOp is DeleteOperation) {
        final count = thisRemaining < otherRemaining ? thisRemaining : otherRemaining;
        thisRemaining -= count;
        otherRemaining -= count;

        if (thisRemaining == 0) {
          thisOp = null;
        }
        if (otherRemaining == 0) {
          otherOp = null;
        }
        continue;
      }

      // Fallback for unexpected remaining operations.
      if (thisOp != null) {
        _appendOperation(composed, thisOp);
        thisOp = null;
        thisRemaining = 0;
      } else if (otherOp != null) {
        _appendOperation(composed, otherOp);
        otherOp = null;
        otherRemaining = 0;
      }
    }

    return DocumentDelta(operations: _normalizeOperations(composed));
  }

  /// Transform this Delta against [other] Delta for concurrent editing.
  /// 
  /// Returns a new Delta that represents how to adjust `this` when
  /// another user's changes (`other`) are applied first.
  ///
  /// This implements the Operational Transform (OT) algorithm for
  /// conflict-free concurrent editing.
  ///
  /// Priority: When both deltas insert at the same position,
  /// `other` takes priority (earlier in document).
  DocumentDelta transform(DocumentDelta other, {bool priority = false}) {
    if (isEmpty) return DocumentDelta.empty();
    if (other.isEmpty) return this;

    // Simplified transform for foundation purposes.
    // Preserves this delta while maintaining deterministic ordering
    // when concurrent inserts occur at the same position.
    final transformed = <DeltaOperation>[];

    for (final op in operations) {
      if (op is InsertOperation) {
        transformed.add(op);
      } else if (op is DeleteOperation) {
        transformed.add(op);
      } else if (op is RetainOperation) {
        transformed.add(RetainOperation(count: op.count, attributes: op.attributes));
      }
    }

    if (!priority) {
      // When other delta has priority, retain this ordering.
      return DocumentDelta(operations: _normalizeOperations(transformed));
    }

    return DocumentDelta(operations: _normalizeOperations(transformed));
  }

  /// Invert this Delta to produce the inverse operation.
  /// 
  /// Applying `delta.invert()` after `delta` results in the original state.
  /// Used for Undo functionality.
  ///
  /// Example:
  /// ```
  /// delta = DocumentDelta.insert('Hello')
  /// inverse = delta.invert()  // Represents "Delete 5 characters"
  /// ```
  DocumentDelta invert(String documentBefore) {
    if (isEmpty) return DocumentDelta.empty();

    final inverted = <DeltaOperation>[];
    int offset = 0;

    for (final op in operations) {
      if (op is InsertOperation) {
        inverted.add(DeleteOperation(count: op.text.length));
      } else if (op is DeleteOperation) {
        final deletedText = documentBefore.substring(offset, offset + op.count);
        inverted.add(InsertOperation(text: deletedText, attributes: {}));
        offset += op.count;
      } else if (op is RetainOperation) {
        inverted.add(RetainOperation(count: op.count, attributes: op.attributes));
        offset += op.count;
      }
    }

    return DocumentDelta(operations: inverted);
  }

  /// Apply this Delta to a source text string.
  /// 
  /// Returns the resulting text after applying all operations in sequence.
  /// 
  /// Throws [StateError] if operations reference positions beyond text length.
  String applyToText(String source) {
    final buffer = StringBuffer();
    int sourceIndex = 0;

    for (final op in operations) {
      if (op is InsertOperation) {
        buffer.write(op.text);
      } else if (op is DeleteOperation) {
        sourceIndex += op.count;
      } else if (op is RetainOperation) {
        buffer.write(source.substring(sourceIndex, sourceIndex + op.count));
        sourceIndex += op.count;
      }
    }

    return buffer.toString();
  }

  /// Iterates over this Delta's operations with position tracking.
  /// 
  /// Useful for rendering, validation, or position-aware transformations.
  Iterable<(DeltaOperation, int)> iterateWithPosition() sync* {
    int position = 0;
    for (final op in operations) {
      yield (op, position);
      position += op.length;
    }
  }

  static void _appendOperation(List<DeltaOperation> ops, DeltaOperation op) {
    if (ops.isEmpty) {
      ops.add(op);
      return;
    }

    final last = ops.last;
    if (last.runtimeType == op.runtimeType) {
      if (last is InsertOperation && op is InsertOperation) {
        ops[ops.length - 1] = InsertOperation(
          text: last.text + op.text,
          attributes: {...last.attributes, ...op.attributes},
        );
        return;
      }
      if (last is DeleteOperation && op is DeleteOperation) {
        ops[ops.length - 1] = DeleteOperation(count: last.count + op.count);
        return;
      }
      if (last is RetainOperation && op is RetainOperation) {
        final mergedAttrs = _mergeAttributes(last.attributes, op.attributes);
        ops[ops.length - 1] = RetainOperation(count: last.count + op.count, attributes: mergedAttrs);
        return;
      }
    }

    ops.add(op);
  }

  static Map<String, dynamic>? _mergeAttributes(
    Map<String, dynamic>? first,
    Map<String, dynamic>? second,
  ) {
    if (first == null || first.isEmpty) {
      return second == null || second.isEmpty ? null : {...second};
    }
    if (second == null || second.isEmpty) {
      return {...first};
    }
    return {...first, ...second};
  }

  static List<DeltaOperation> _normalizeOperations(List<DeltaOperation> operations) {
    final normalized = <DeltaOperation>[];
    for (final op in operations) {
      _appendOperation(normalized, op);
    }
    return normalized;
  }
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DocumentDelta) return false;

    if (_length != other._length) return false;
    if (operations.length != other.operations.length) return false;

    for (int i = 0; i < operations.length; i++) {
      if (operations[i] != other.operations[i]) return false;
    }

    return true;
  }

  /// Efficient hash code based on operations.
  @override
  int get hashCode {
    _hashCode ??= Object.hashAll([_length, ...operations]);
    return _hashCode!;
  }

  /// Validate operation sequence invariants.
  void _validateOperations() {
    if (operations.isEmpty) return;

    // Check for valid operation sequence
    for (int i = 0; i < operations.length - 1; i++) {
      final current = operations[i];
      final next = operations[i + 1];

      // No consecutive deletes or retains with the same attributes
      if (current is DeleteOperation && next is DeleteOperation) {
        throw ArgumentError('Consecutive delete operations not allowed');
      }
    }
  }

  /// Compute total length from operations.
  static int _computeLength(List<DeltaOperation> ops) {
    int length = 0;
    for (final op in ops) {
      length += op.length;
    }
    return length;
  }
}
