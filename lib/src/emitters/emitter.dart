import '../spec/spec.dart';

/// Context for schema emission.
class EmitContext {
  /// Type definitions that can be referenced.
  final Map<String, TypeSpec> definitions;

  /// Whether this is the root schema being emitted.
  final bool isRoot;

  /// Creates a new [EmitContext].
  const EmitContext({
    required this.definitions,
    this.isRoot = false,
  });

  /// Creates a new context that is not the root.
  EmitContext asNonRoot() => EmitContext(
        definitions: definitions,
        isRoot: false,
      );
}

/// Base class for schema emitters.
///
/// Emitters transform [TypeSpec] instances into specific output formats.
abstract class SpecEmitter<T> {
  /// The name of the output format.
  String get formatName;

  /// Emits a schema for the given type specification.
  T emit(TypeSpec spec, {required EmitContext context});
}
