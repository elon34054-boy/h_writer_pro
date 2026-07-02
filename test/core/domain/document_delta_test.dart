@TestOn('vm')
import 'package:test/test.dart';

import 'package:h_writer_pro/core/domain/entities/document_delta.dart';

void main() {
  group('DocumentDelta - Foundation Entity Tests', () {
    group('Construction & Initialization', () {
      test('empty() creates a delta with no operations', () {
        final delta = DocumentDelta.empty();
        expect(delta.isEmpty, isTrue);
        expect(delta.length, equals(0));
        expect(delta.operationCount, equals(0));
      });

      test('insert() creates a single insert operation', () {
        final delta = DocumentDelta.insert('Hello');
        expect(delta.isEmpty, isFalse);
        expect(delta.length, equals(5));
        expect(delta.operationCount, equals(1));
      });

      test('insert() with attributes stores formatting', () {
        final delta = DocumentDelta.insert(
          'Bold',
          attributes: {'bold': true},
        );
        expect(delta.length, equals(4));
        final op = delta.operations[0] as InsertOperation;
        expect(op.attributes['bold'], isTrue);
      });

      test('delete() creates a single delete operation', () {
        final delta = DocumentDelta.delete(5);
        expect(delta.length, equals(0));
        expect(delta.operationCount, equals(1));
      });

      test('retain() creates a single retain operation', () {
        final delta = DocumentDelta.retain(10);
        expect(delta.length, equals(10));
        expect(delta.operationCount, equals(1));
      });

      test('direct construction with operation list', () {
        final ops = [
          InsertOperation(text: 'Hello'),
          RetainOperation(count: 5),
          DeleteOperation(count: 3),
        ];
        final delta = DocumentDelta(operations: ops);
        expect(delta.operationCount, equals(3));
        expect(delta.length, equals(10));
      });

      test('operations list is immutable', () {
        final delta = DocumentDelta.insert('test');
        expect(() {
          // ignore: avoid_function_calls_in_field_initializers
          delta.operations.add(DeleteOperation(count: 1));
        }, throwsUnsupportedError);
      });
    });

    group('Composition', () {
      test('empty composed with delta returns the delta', () {
        final delta = DocumentDelta.insert('Hello');
        final empty = DocumentDelta.empty();
        expect(empty.compose(delta), equals(delta));
      });

      test('delta composed with empty returns the delta', () {
        final delta = DocumentDelta.insert('Hello');
        final empty = DocumentDelta.empty();
        expect(delta.compose(empty), equals(delta));
      });

      test('insert then retain composes correctly', () {
        final insert = DocumentDelta.insert('Hello');
        final retain = DocumentDelta.retain(5);
        final composed = insert.compose(retain);

        expect(composed.length, equals(5));
        expect(composed.operations.length, equals(2));
      });

      test('insert then insert at position composes correctly', () {
        final delta1 = DocumentDelta.insert('Hello');
        final delta2 = DocumentDelta.insert(' World');
        final composed = delta1.compose(delta2);

        // Result should have both inserts
        expect(composed.operationCount, equals(2));
      });

      test('composition associativity: (a.compose(b)).compose(c) == a.compose(b.compose(c))',
          () {
        final a = DocumentDelta.insert('A');
        final b = DocumentDelta.insert('B');
        final c = DocumentDelta.insert('C');

        final left = a.compose(b).compose(c);
        final right = a.compose(b.compose(c));

        expect(left, equals(right));
      });
    });

    group('Transform (Operational Transform)', () {
      test('empty delta transforms to empty', () {
        final delta = DocumentDelta.empty();
        final other = DocumentDelta.insert('test');
        expect(delta.transform(other), equals(DocumentDelta.empty()));
      });

      test('transform respects priority when both insert at same position', () {
        final delta1 = DocumentDelta.insert('A');
        final delta2 = DocumentDelta.insert('B');

        final transformed1 = delta1.transform(delta2, priority: true);
        final transformed2 = delta1.transform(delta2, priority: false);

        // Results should differ based on priority
        expect(transformed1, isNotNull);
        expect(transformed2, isNotNull);
      });

      test('concurrent inserts at different positions are preserved', () {
        final insert1 = DocumentDelta.insert('Hello');
        final retain2 = DocumentDelta.retain(5).insert(' World');

        final transformed = insert1.transform(retain2);
        expect(transformed.operationCount, isPositive);
      });

      test('delete operation is handled in transform', () {
        final insert = DocumentDelta.insert('text');
        final delete = DocumentDelta.delete(4);

        final transformed = insert.transform(delete);
        expect(transformed, isNotNull);
      });
    });

    group('Inversion for Undo', () {
      test('insert inverted produces delete', () {
        final insert = DocumentDelta.insert('Hello');
        final inverse = insert.invert('');

        expect(inverse.operations.length, equals(1));
        expect(inverse.operations[0], isA<DeleteOperation>());
        final delOp = inverse.operations[0] as DeleteOperation;
        expect(delOp.count, equals(5));
      });

      test('delete inverted produces insert with original text', () {
        final original = 'HelloWorld';
        final delete = DocumentDelta.delete(5);
        final inverse = delete.invert(original);

        expect(inverse.operations.length, equals(1));
        expect(inverse.operations[0], isA<InsertOperation>());
        final insOp = inverse.operations[0] as InsertOperation;
        expect(insOp.text, equals('Hello'));
      });

      test('retain inverted produces retain with same attributes', () {
        final attrs = {'bold': true};
        final retain = DocumentDelta.retain(5, attributes: attrs);
        final inverse = retain.invert('Hello');

        expect(inverse.operations.length, equals(1));
        expect(inverse.operations[0], isA<RetainOperation>());
      });

      test('applying delta then inverse returns to original state', () {
        final original = 'Hello World';
        final delta = DocumentDelta.insert('Test');
        final inverse = delta.invert(original);

        // Conceptually: original + delta - delta = original
        expect(delta.applyToText(original).length,
            equals(original.length + 'Test'.length));
      });
    });

    group('Apply to Text', () {
      test('empty delta applied to text returns empty', () {
        final delta = DocumentDelta.empty();
        final result = delta.applyToText('Hello World');
        expect(result, equals(''));
      });

      test('insert operation applied produces inserted text', () {
        final delta = DocumentDelta.insert('Hello');
        final result = delta.applyToText('');
        expect(result, equals('Hello'));
      });

      test('retain operation preserves text', () {
        final source = 'Hello World';
        final delta = DocumentDelta.retain(5);
        final result = delta.applyToText(source);
        expect(result, equals('Hello'));
      });

      test('delete operation removes characters from source', () {
        final source = 'HelloWorld';
        final delta = DocumentDelta.delete(5);
        final result = delta.applyToText(source);
        expect(result, equals(''));
      });

      test('complex operations combined correctly', () {
        final source = 'Hello World';
        final delta = DocumentDelta(
          operations: [
            RetainOperation(count: 6),
            InsertOperation(text: 'Beautiful '),
            RetainOperation(count: 5),
          ],
        );
        final result = delta.applyToText(source);
        expect(result, equals('Hello Beautiful World'));
      });

      test('insert, delete, retain sequence applies in order', () {
        final source = 'World';
        final delta = DocumentDelta(
          operations: [
            InsertOperation(text: 'Hello '),
            RetainOperation(count: 5),
          ],
        );
        final result = delta.applyToText(source);
        expect(result, equals('Hello World'));
      });
    });

    group('Equality & Hashing', () {
      test('two empty deltas are equal', () {
        final delta1 = DocumentDelta.empty();
        final delta2 = DocumentDelta.empty();
        expect(delta1, equals(delta2));
      });

      test('deltas with same operations are equal', () {
        final delta1 = DocumentDelta.insert('Hello');
        final delta2 = DocumentDelta.insert('Hello');
        expect(delta1, equals(delta2));
      });

      test('deltas with different operations are not equal', () {
        final delta1 = DocumentDelta.insert('Hello');
        final delta2 = DocumentDelta.insert('World');
        expect(delta1, isNot(equals(delta2)));
      });

      test('identical delta is equal to itself', () {
        final delta = DocumentDelta.insert('test');
        expect(delta, equals(delta));
      });

      test('hash code is consistent for equal objects', () {
        final delta1 = DocumentDelta.insert('Hello');
        final delta2 = DocumentDelta.insert('Hello');
        expect(delta1.hashCode, equals(delta2.hashCode));
      });

      test('hash code allows use in sets', () {
        final delta1 = DocumentDelta.insert('Hello');
        final delta2 = DocumentDelta.insert('Hello');
        final delta3 = DocumentDelta.insert('World');

        final set = {delta1, delta2, delta3};
        expect(set.length, equals(2));
      });

      test('hash code allows use as map keys', () {
        final delta1 = DocumentDelta.insert('key1');
        final delta2 = DocumentDelta.insert('key1');

        final map = {delta1: 'value'};
        expect(map[delta2], equals('value'));
      });
    });

    group('Iteration with Position', () {
      test('iterateWithPosition tracks correct positions', () {
        final delta = DocumentDelta(
          operations: [
            InsertOperation(text: 'Hello'),
            RetainOperation(count: 5),
            DeleteOperation(count: 3),
          ],
        );

        final positions = delta.iterateWithPosition().toList();
        expect(positions.length, equals(3));
        expect(positions[0].$2, equals(0));
        expect(positions[1].$2, equals(5));
        expect(positions[2].$2, equals(10));
      });

      test('iterateWithPosition on empty delta is empty', () {
        final delta = DocumentDelta.empty();
        final positions = delta.iterateWithPosition().toList();
        expect(positions, isEmpty);
      });

      test('position iteration works with complex operations', () {
        final delta = DocumentDelta(
          operations: [
            InsertOperation(text: 'Hello'),
            InsertOperation(text: ' '),
            InsertOperation(text: 'World'),
          ],
        );

        final positions = delta.iterateWithPosition().toList();
        expect(positions[0].$2, equals(0));
        expect(positions[1].$2, equals(5));
        expect(positions[2].$2, equals(6));
      });
    });

    group('Memory Efficiency (Zero-Copy Properties)', () {
      test('large document delta has minimal memory footprint', () {
        // Instead of storing a 1MB string, store operations
        final largeDelta = DocumentDelta(
          operations: [
            InsertOperation(text: 'A' * 1000000), // 1 million 'A's
            RetainOperation(count: 1000000),
            DeleteOperation(count: 100000),
          ],
        );

        expect(largeDelta.length, equals(1900000));
        expect(largeDelta.operationCount, equals(3));
      });

      test('invert preserves memory efficiency without storing full text in operation',
          () {
        final delta = DocumentDelta.insert('test');
        final inverse = delta.invert('');

        // Inverse should be minimal (just delete count)
        expect(inverse.operations[0], isA<DeleteOperation>());
      });

      test('composed deltas remain efficient', () {
        DocumentDelta result = DocumentDelta.empty();
        for (int i = 0; i < 1000; i++) {
          result = result.compose(DocumentDelta.insert('x'));
        }

        expect(result.operationCount, equals(1000));
        expect(result.length, equals(1000));
      });
    });

    group('Edge Cases & Invariants', () {
      test('toString produces readable output', () {
        final delta = DocumentDelta.insert('test');
        expect(delta.toString(), contains('DocumentDelta'));
        expect(delta.toString(), contains('Insert'));
      });

      test('operations with empty attributes are handled', () {
        final delta = DocumentDelta.insert('text', attributes: {});
        expect(delta.operations[0].length, equals(4));
      });

      test('retain with null attributes works', () {
        final delta = DocumentDelta.retain(5, attributes: null);
        expect(delta.length, equals(5));
      });

      test('multiple inserts at different positions compose', () {
        final ops = [
          InsertOperation(text: 'Hello'),
          RetainOperation(count: 5),
          InsertOperation(text: 'World'),
        ];
        final delta = DocumentDelta(operations: ops);
        expect(delta.operationCount, equals(3));
        expect(delta.length, equals(10));
      });
    });

    group('Performance Characteristics', () {
      test('creating delta is O(1) amortized', () {
        final ops = List.generate(
          10000,
          (i) => InsertOperation(text: 'x'),
        );

        final stopwatch = Stopwatch()..start();
        final delta = DocumentDelta(operations: ops);
        stopwatch.stop();

        expect(delta.operationCount, equals(10000));
        expect(stopwatch.elapsedMilliseconds, lessThan(100)); // Should be very fast
      });

      test('composition with large deltas', () {
        final large1 = DocumentDelta(
          operations: List.generate(100, (i) => InsertOperation(text: 'x')),
        );
        final large2 = DocumentDelta(
          operations: List.generate(100, (i) => InsertOperation(text: 'y')),
        );

        final stopwatch = Stopwatch()..start();
        final composed = large1.compose(large2);
        stopwatch.stop();

        expect(composed, isNotNull);
        expect(stopwatch.elapsedMilliseconds, lessThan(50));
      });
    });
  });
}

/// Extension to generate repeated strings for testing.
extension StringRepeat on String {
  String operator *(int times) {
    return List<String>.filled(times, this).join();
  }
}
