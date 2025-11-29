import 'package:analyzer/dart/element/element.dart';

import '../spec/spec.dart';

/// Result of extracting schema information from a class.
class ExtractionResult {
  /// The main type specification.
  final TypeSpec spec;

  /// Additional type definitions that are referenced.
  final Map<String, TypeSpec> definitions;

  /// Creates a new [ExtractionResult].
  const ExtractionResult({
    required this.spec,
    this.definitions = const {},
  });
}

/// Base interface for extracting schema information from Dart classes.
abstract class Extractor {
  /// Whether this extractor can handle the given element.
  bool canExtract(InterfaceElement element);

  /// Extracts schema information from the given element.
  ExtractionResult extract(InterfaceElement element);
}

/// Type of data class detected.
enum DataClassType {
  /// Class annotated with @freezed
  freezed,

  /// Class annotated with @JsonSerializable
  jsonSerializable,

  /// Plain Dart class
  plain,

  /// Unsupported class type
  unsupported,
}
