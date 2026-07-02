# H Writer Pro

**Professional word processor with 0% failure risk and ultra-low memory consumption.**

Pure Dart 3.x core with zero Flutter dependencies. Clean Architecture across desktop and mobile OS.

## Phase 1: Dart Core Text Engine & Document Model

This phase implements the foundational text processing engine using the Delta data structure for efficient, undo/redo-capable document manipulation.

### Project Structure

```
lib/
├── core/                    # Pure Dart, zero UI dependencies
│   ├── domain/
│   │   ├── entities/        # DocumentDelta, core value objects
│   │   ├── repositories/    # Abstract data contracts
│   │   └── usecases/        # Business logic
│   ├── data/
│   │   ├── models/          # Data transfer objects
│   │   ├── parsers/         # Text/document parsing
│   │   ├── exporters/       # Export to various formats
│   │   └── repositories/    # Concrete implementations
│   └── utils/               # Core utilities
│
└── presentation/            # Flutter UI layer
    ├── bloc/                # State management (BLoC)
    ├── screens/             # Pages
    └── widgets/             # Reusable components
```

## Foundation: DocumentDelta Entity

The `DocumentDelta` is the immutable core abstraction representing text changes:

- **Insert**: Add text with optional formatting
- **Delete**: Remove characters  
- **Retain**: Keep existing text or apply attributes

### Key Properties

✓ **Zero-Copy**: Operations stored, not raw text  
✓ **Undo/Redo**: Automatic operation inversion  
✓ **OT Support**: Transform for collaborative editing  
✓ **Memory Efficient**: O(n) operations instead of O(text_size)  
✓ **Composable**: Combine multiple deltas  
✓ **Immutable**: Inherent thread safety  

### Example Usage

```dart
// Single operations
final insert = DocumentDelta.insert('Hello World');
final delete = DocumentDelta.delete(5);
final retain = DocumentDelta.retain(10);

// Composition
final combined = insert.compose(retain);

// Undo via inversion
final undo = insert.invert('');

// Apply to text
final result = insert.applyToText('');  // "Hello World"

// Operational Transform (concurrent editing)
final delta1 = DocumentDelta.insert('A');
final delta2 = DocumentDelta.insert('B');
final transformed = delta1.transform(delta2);
```

## Running Tests

```bash
# Run all tests
dart test

# Run specific test file
dart test test/core/domain/document_delta_test.dart

# Run with verbose output
dart test -v
```

## Architecture Principles

1. **Strict Separation**: Core `lib/core/` has zero Flutter dependencies
2. **Immutability**: All value objects are immutable (final)
3. **Sound Null Safety**: 100% null-safe Dart code
4. **TDD First**: Tests written before implementation
5. **Clean Architecture**: Domain → Data → Presentation layers

## Next Phases

- **Phase 2**: Document Model (paragraphs, formatting, metadata)
- **Phase 3**: Text Engine (composition, transformation, validation)
- **Phase 4**: File I/O (XAN format, DOCX, PDF export)
- **Phase 5**: Plugin System
- **Phase 6**: Flutter UI with BLoC state management
- **Phase 7**: Cross-platform build (iOS, Android, macOS, Windows, Linux)

---

**Status**: Foundation layer complete. Awaiting code review and approval.
