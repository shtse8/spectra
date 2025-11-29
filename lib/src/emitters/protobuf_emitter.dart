import '../spec/spec.dart';
import '../utils/string_utils.dart';
import 'emitter.dart';

/// Emits Protocol Buffers (.proto) definition from TypeSpec.
class ProtobufEmitter extends SpecEmitter<String> {
  /// The proto syntax version.
  final String syntaxVersion;

  /// The package name for the proto file.
  final String? packageName;

  /// Creates a new [ProtobufEmitter].
  ProtobufEmitter({
    this.syntaxVersion = 'proto3',
    this.packageName,
  });

  @override
  String get formatName => 'Protobuf';

  @override
  String emit(TypeSpec spec, {required EmitContext context}) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('syntax = "$syntaxVersion";');
    buffer.writeln();

    if (packageName != null) {
      buffer.writeln('package $packageName;');
      buffer.writeln();
    }

    // Emit main message
    _emitMessage(buffer, spec, context);

    // Emit referenced types
    for (final entry in context.definitions.entries) {
      buffer.writeln();
      _emitMessage(buffer, entry.value, context, name: entry.key);
    }

    return buffer.toString();
  }

  void _emitMessage(
    StringBuffer buffer,
    TypeSpec spec,
    EmitContext context, {
    String? name,
  }) {
    switch (spec) {
      case ObjectSpec():
        _emitObjectMessage(buffer, spec, context, name: name);
      case EnumSpec():
        _emitEnum(buffer, spec, name: name);
      case UnionSpec():
        _emitUnionMessage(buffer, spec, context, name: name);
      case StringSpec():
      case NumberSpec():
      case BoolSpec():
      case ArraySpec():
      case MapSpec():
      case RefSpec():
        // Primitive types don't need message definitions
        break;
    }
  }

  void _emitObjectMessage(
    StringBuffer buffer,
    ObjectSpec spec,
    EmitContext context, {
    String? name,
  }) {
    final messageName = name ?? spec.name;

    if (spec.description != null) {
      buffer.writeln('// ${spec.description}');
    }

    buffer.writeln('message $messageName {');

    var fieldNumber = 1;
    for (final entry in spec.properties.entries) {
      final property = entry.value;
      final fieldType = _typeToProtoType(property.type);
      final fieldName = toSnakeCase(property.effectiveName);

      if (property.type.description != null) {
        buffer.writeln('  // ${property.type.description}');
      }

      final optional = !property.required ? 'optional ' : '';
      buffer.writeln('  $optional$fieldType $fieldName = $fieldNumber;');
      fieldNumber++;
    }

    buffer.writeln('}');
  }

  void _emitEnum(
    StringBuffer buffer,
    EnumSpec spec, {
    String? name,
  }) {
    final enumName = name ?? spec.name;

    if (spec.description != null) {
      buffer.writeln('// ${spec.description}');
    }

    buffer.writeln('enum $enumName {');

    // Proto3 requires first enum value to be 0
    buffer.writeln('  ${enumName.toUpperCase()}_UNSPECIFIED = 0;');

    var valueNumber = 1;
    for (final value in spec.values) {
      final valueName = '${enumName.toUpperCase()}_${value.name.toUpperCase()}';
      if (value.description != null) {
        buffer.writeln('  // ${value.description}');
      }
      buffer.writeln('  $valueName = $valueNumber;');
      valueNumber++;
    }

    buffer.writeln('}');
  }

  void _emitUnionMessage(
    StringBuffer buffer,
    UnionSpec spec,
    EmitContext context, {
    String? name,
  }) {
    final messageName = name ?? spec.name;

    if (spec.description != null) {
      buffer.writeln('// ${spec.description}');
    }

    buffer.writeln('message $messageName {');
    buffer.writeln('  oneof variant {');

    var fieldNumber = 1;
    for (final variant in spec.variants) {
      final variantName = toSnakeCase(variant.name);
      buffer.writeln('    ${variant.name} $variantName = $fieldNumber;');
      fieldNumber++;
    }

    buffer.writeln('  }');
    buffer.writeln('}');

    // Emit variant messages
    for (final variant in spec.variants) {
      buffer.writeln();
      _emitObjectMessage(buffer, variant, context);
    }
  }

  String _typeToProtoType(TypeSpec spec) {
    return switch (spec) {
      StringSpec() => 'string',
      NumberSpec(:final isInteger) => isInteger ? 'int64' : 'double',
      BoolSpec() => 'bool',
      ArraySpec(:final items) => 'repeated ${_typeToProtoType(items)}',
      MapSpec(:final valueType) =>
        'map<string, ${_typeToProtoType(valueType)}>',
      EnumSpec(:final name) => name,
      ObjectSpec(:final name) => name,
      UnionSpec(:final name) => name,
      RefSpec(:final typeName) => typeName,
    };
  }
}
