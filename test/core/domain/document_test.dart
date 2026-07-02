@TestOn('vm')
import 'package:test/test.dart';
import 'package:h_writer_pro/core/domain/entities/document.dart';

void main() {
  group('Document Entity Tests', () {
    group('Construction & Initialization', () {
      test('creates document with title and paragraphs', () {
        final doc = Document(
          title: 'Test Doc',
          paragraphs: [
            Paragraph.simple(text: 'Hello World'),
          ],
        );

        expect(doc.title, equals('Test Doc'));
        expect(doc.paragraphCount, equals(1));
        expect(doc.isEmpty, isFalse);
      });

      test('empty document creation', () {
        final doc = Document(
          title: 'Empty',
          paragraphs: [],
        );

        expect(doc.isEmpty, isTrue);
        expect(doc.paragraphCount, equals(0));
      });

      test('document auto-generates ID if not provided', () {
        final doc = Document(
          title: 'Auto ID',
          paragraphs: [],
        );

        expect(doc.id, startsWith('doc_'));
      });

      test('document tracks creation and modification times', () {
        final doc = Document(
          title: 'Timed',
          paragraphs: [],
        );

        expect(doc.createdAt, isNotNull);
        expect(doc.modifiedAt, isNotNull);
      });

      test('document metadata stored and accessed', () {
        final metadata = {'author': 'Test User', 'version': 1};
        final doc = Document(
          title: 'Meta',
          paragraphs: [],
          metadata: metadata,
        );

        expect(doc.metadata['author'], equals('Test User'));
      });
    });

    group('Content Management', () {
      test('calculates total length from paragraphs', () {
        final doc = Document(
          title: 'Length Test',
          paragraphs: [
            Paragraph.simple(text: 'Hello'),
            Paragraph.simple(text: 'World'),
          ],
        );

        expect(doc.length, equals(11)); // "Hello" + "\n" + "World"
      });

      test('toPlainText concatenates paragraph text with newlines', () {
        final doc = Document(
          title: 'Plain Text',
          paragraphs: [
            Paragraph.simple(text: 'Line 1'),
            Paragraph.simple(text: 'Line 2'),
            Paragraph.simple(text: 'Line 3'),
          ],
        );

        final plain = doc.toPlainText();
        expect(plain, equals('Line 1\nLine 2\nLine 3'));
      });

      test('iterateWithIndex provides paragraph indices', () {
        final doc = Document(
          title: 'Indexed',
          paragraphs: [
            Paragraph.simple(text: 'First'),
            Paragraph.simple(text: 'Second'),
            Paragraph.simple(text: 'Third'),
          ],
        );

        final indexed = doc.iterateWithIndex().toList();
        expect(indexed.length, equals(3));
        expect(indexed[0].$1, equals(0));
        expect(indexed[1].$1, equals(1));
        expect(indexed[2].$1, equals(2));
      });
    });

    group('Immutability & Copying', () {
      test('copyWithTitle creates new document with updated title', () {
        final doc = Document(
          title: 'Original',
          paragraphs: [Paragraph.simple(text: 'Content')],
        );

        final updated = doc.copyWithTitle('Updated');

        expect(updated.title, equals('Updated'));
        expect(doc.title, equals('Original')); // Original unchanged
        expect(updated.id, equals(doc.id)); // Same ID
      });

      test('copyWithParagraphs creates new document with new content', () {
        final doc = Document(
          title: 'Test',
          paragraphs: [Paragraph.simple(text: 'Old')],
        );

        final newParagraphs = [
          Paragraph.simple(text: 'New 1'),
          Paragraph.simple(text: 'New 2'),
        ];
        final updated = doc.copyWithParagraphs(newParagraphs);

        expect(updated.paragraphCount, equals(2));
        expect(doc.paragraphCount, equals(1)); // Original unchanged
      });

      test('copyWithMetadata merges metadata updates', () {
        final doc = Document(
          title: 'Test',
          paragraphs: [],
          metadata: {'version': 1, 'author': 'Original'},
        );

        final updated = doc.copyWithMetadata({'version': 2});

        expect(updated.metadata['version'], equals(2));
        expect(updated.metadata['author'], equals('Original')); // Preserved
      });

      test('modifiedAt updated when copying', () {
        final doc = Document(
          title: 'Test',
          paragraphs: [],
        );

        Future.delayed(Duration(milliseconds: 10)).then((_) {
          final updated = doc.copyWithTitle('New Title');
          expect(updated.modifiedAt.isAfter(doc.modifiedAt), isTrue);
        });
      });
    });

    group('Equality & Hashing', () {
      test('two documents with same content are equal', () {
        final para = Paragraph.simple(text: 'Content');
        
        final doc1 = Document(
          id: 'same-id',
          title: 'Title',
          paragraphs: [para],
        );
        final doc2 = Document(
          id: 'same-id',
          title: 'Title',
          paragraphs: [para],
        );

        expect(doc1, equals(doc2));
      });

      test('documents with different content are not equal', () {
        final doc1 = Document(
          title: 'Title 1',
          paragraphs: [Paragraph.simple(text: 'A')],
        );
        final doc2 = Document(
          title: 'Title 2',
          paragraphs: [Paragraph.simple(text: 'B')],
        );

        expect(doc1, isNot(equals(doc2)));
      });

      test('hash code consistent for equal documents', () {
        final para = Paragraph.simple(text: 'Content');
        final doc1 = Document(
          id: 'same-id',
          title: 'Title',
          paragraphs: [para],
        );
        final doc2 = Document(
          id: 'same-id',
          title: 'Title',
          paragraphs: [para],
        );

        expect(doc1.hashCode, equals(doc2.hashCode));
      });
    });

    group('Paragraph Access', () {
      test('access paragraphs by index', () {
        final paras = [
          Paragraph.simple(text: 'First'),
          Paragraph.simple(text: 'Second'),
        ];
        final doc = Document(
          title: 'Test',
          paragraphs: paras,
        );

        expect(doc.paragraphs[0].text, equals('First'));
        expect(doc.paragraphs[1].text, equals('Second'));
      });

      test('paragraph list is immutable', () {
        final doc = Document(
          title: 'Test',
          paragraphs: [Paragraph.simple(text: 'Content')],
        );

        expect(() {
          doc.paragraphs.add(Paragraph.simple(text: 'New'));
        }, throwsUnsupportedError);
      });
    });
  });

  group('Paragraph Entity Tests', () {
    group('Construction', () {
      test('creates paragraph with text', () {
        final para = Paragraph.simple(text: 'Hello World');
        expect(para.text, equals('Hello World'));
        expect(para.length, equals(11));
        expect(para.isEmpty, isFalse);
      });

      test('empty paragraph creation', () {
        final para = Paragraph.empty();
        expect(para.isEmpty, isTrue);
        expect(para.text, isEmpty);
      });

      test('paragraph with formatting attributes', () {
        final para = Paragraph.simple(
          text: 'Bold Text',
          attributes: [TextAttribute.bold()],
        );

        expect(para.text, equals('Bold Text'));
      });

      test('paragraph with multiple runs and different formatting', () {
        final runs = [
          TextRun(text: 'Bold ', attributes: [TextAttribute.bold()]),
          TextRun(text: 'Italic ', attributes: [TextAttribute.italic()]),
          TextRun(text: 'Normal'),
        ];
        final para = Paragraph(runs: runs);

        expect(para.text, equals('Bold Italic Normal'));
        expect(para.runCount, equals(3));
      });
    });

    group('Text Access & Attributes', () {
      test('getAttributesAt returns attributes at position', () {
        final para = Paragraph(
          runs: [
            TextRun(text: 'Bold', attributes: [TextAttribute.bold()]),
            TextRun(text: ' Normal'),
          ],
        );

        final boldAttrs = para.getAttributesAt(0);
        expect(boldAttrs, contains(TextAttribute.bold()));

        final normalAttrs = para.getAttributesAt(5);
        expect(normalAttrs, isEmpty);
      });

      test('paragraph length counts all characters', () {
        final para = Paragraph(
          runs: [
            TextRun(text: 'Hello'),
            TextRun(text: ' '),
            TextRun(text: 'World'),
          ],
        );

        expect(para.length, equals(11));
      });
    });

    group('Iteration', () {
      test('iterateRunsWithPositions tracks run boundaries', () {
        final runs = [
          TextRun(text: 'Hello'),
          TextRun(text: ' '),
          TextRun(text: 'World'),
        ];
        final para = Paragraph(runs: runs);

        final positions = para.iterateRunsWithPositions().toList();
        expect(positions.length, equals(3));
        expect(positions[0].$2, equals(0));
        expect(positions[0].$3, equals(5));
        expect(positions[1].$2, equals(5));
        expect(positions[1].$3, equals(6));
        expect(positions[2].$2, equals(6));
        expect(positions[2].$3, equals(11));
      });
    });
  });

  group('TextAttribute Tests', () {
    test('bold attribute creation', () {
      final attr = TextAttribute.bold();
      expect(attr.name, equals('bold'));
      expect(attr.value, isTrue);
    });

    test('font size attribute', () {
      final attr = TextAttribute.fontSize(14);
      expect(attr.name, equals('fontSize'));
      expect(attr.value, equals(14));
    });

    test('color attribute', () {
      final attr = TextAttribute.color('#FF0000');
      expect(attr.name, equals('color'));
      expect(attr.value, equals('#FF0000'));
    });

    test('attributes equality', () {
      final attr1 = TextAttribute.bold();
      final attr2 = TextAttribute.bold();
      expect(attr1, equals(attr2));
    });
  });
}
