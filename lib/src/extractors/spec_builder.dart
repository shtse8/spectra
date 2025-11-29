import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';

import '../spec/spec.dart';
import '../utils/string_utils.dart';
import '../utils/type_checkers.dart';

/// Builds TypeSpec from Dart types.
class SpecBuilder {
  /// Collected type definitions.
  final Map<String, TypeSpec> definitions = {};

  /// Types currently being processed (for cycle detection).
  final Set<String> _processingTypes = {};

  /// Builds a TypeSpec from a Dart type.
  TypeSpec buildFromType(DartType type, {FieldMetadata? fieldMeta}) {
    final isNullable = type.nullabilitySuffix == NullabilitySuffix.question;

    TypeSpec spec = _buildCoreType(type, fieldMeta: fieldMeta);

    // Apply field metadata overrides
    if (fieldMeta != null) {
      spec = _applyFieldMetadata(spec, fieldMeta);
    }

    // Make nullable if needed
    if (isNullable && !spec.nullable) {
      spec = spec.asNullable();
    }

    return spec;
  }

  TypeSpec _buildCoreType(DartType type, {FieldMetadata? fieldMeta}) {
    // Handle nullable types
    final coreType = type.alias?.element.name != null
        ? type
        : (type is InterfaceType ? type : type);

    // Primitives
    if (TypeCheckers.string.isExactlyType(coreType)) {
      return StringSpec(
        format: fieldMeta?.format,
        pattern: fieldMeta?.pattern,
        minLength: fieldMeta?.minLength,
        maxLength: fieldMeta?.maxLength,
      );
    }

    if (TypeCheckers.int_.isExactlyType(coreType)) {
      return NumberSpec.integer(
        minimum: fieldMeta?.minimum,
        maximum: fieldMeta?.maximum,
        exclusiveMinimum: fieldMeta?.exclusiveMinimum ?? false,
        exclusiveMaximum: fieldMeta?.exclusiveMaximum ?? false,
        multipleOf: fieldMeta?.multipleOf,
      );
    }

    if (TypeCheckers.double_.isExactlyType(coreType)) {
      return NumberSpec.double(
        minimum: fieldMeta?.minimum,
        maximum: fieldMeta?.maximum,
        exclusiveMinimum: fieldMeta?.exclusiveMinimum ?? false,
        exclusiveMaximum: fieldMeta?.exclusiveMaximum ?? false,
        multipleOf: fieldMeta?.multipleOf,
      );
    }

    if (TypeCheckers.num_.isExactlyType(coreType)) {
      return NumberSpec(
        minimum: fieldMeta?.minimum,
        maximum: fieldMeta?.maximum,
        exclusiveMinimum: fieldMeta?.exclusiveMinimum ?? false,
        exclusiveMaximum: fieldMeta?.exclusiveMaximum ?? false,
        multipleOf: fieldMeta?.multipleOf,
      );
    }

    if (TypeCheckers.bool_.isExactlyType(coreType)) {
      return const BoolSpec();
    }

    // DateTime -> string with date-time format
    if (TypeCheckers.dateTime.isExactlyType(coreType)) {
      return const StringSpec(format: StringFormat.dateTime);
    }

    // Uri -> string with uri format
    if (TypeCheckers.uri.isExactlyType(coreType)) {
      return const StringSpec(format: StringFormat.uri);
    }

    // Duration -> string with duration format
    if (TypeCheckers.duration.isExactlyType(coreType)) {
      return const StringSpec(format: StringFormat.duration);
    }

    // Enum types
    if (coreType.element is EnumElement) {
      return _buildEnumSpec(coreType.element as EnumElement);
    }

    // Collections
    if (coreType is InterfaceType) {
      // List/Set/Iterable
      if (TypeCheckers.iterable.isAssignableFromType(coreType)) {
        final itemType = coreType.typeArguments.isNotEmpty
            ? coreType.typeArguments.first
            : coreType;
        return ArraySpec(
          items: buildFromType(itemType),
          minItems: fieldMeta?.minItems,
          maxItems: fieldMeta?.maxItems,
          uniqueItems: fieldMeta?.uniqueItems ?? false,
        );
      }

      // Map
      if (TypeCheckers.map.isAssignableFromType(coreType)) {
        final keyType = coreType.typeArguments.isNotEmpty
            ? coreType.typeArguments[0]
            : coreType;
        final valueType = coreType.typeArguments.length > 1
            ? coreType.typeArguments[1]
            : coreType;
        return MapSpec(
          keyType: buildFromType(keyType),
          valueType: buildFromType(valueType),
        );
      }

      // Object/dynamic fallback
      if (TypeCheckers.object.isExactlyType(coreType) ||
          coreType is DynamicType) {
        return const ObjectSpec(name: 'Object', properties: {});
      }

      // Complex object type - create reference
      return _buildComplexType(coreType);
    }

    // Dynamic type
    if (coreType is DynamicType) {
      return const ObjectSpec(name: 'dynamic', properties: {});
    }

    // Fallback
    return const ObjectSpec(name: 'unknown', properties: {});
  }

  TypeSpec _buildComplexType(InterfaceType type) {
    final element = type.element;
    final typeName = element.name;

    // Check for cycles
    if (_processingTypes.contains(typeName)) {
      return RefSpec(typeName: typeName);
    }

    // Check if already defined
    if (definitions.containsKey(typeName)) {
      return RefSpec(typeName: typeName);
    }

    // Mark as processing
    _processingTypes.add(typeName);

    try {
      // Build the object spec
      final spec = _buildObjectSpec(element);

      // Store in definitions
      definitions[typeName] = spec;

      return RefSpec(typeName: typeName);
    } finally {
      _processingTypes.remove(typeName);
    }
  }

  ObjectSpec _buildObjectSpec(InterfaceElement element) {
    final properties = <String, PropertySpec>{};
    final required = <String>[];

    for (final field in element.fields) {
      if (field.isStatic || !field.isPublic) continue;
      if (field.isSynthetic) continue;

      // Check for @Ignore
      if (TypeCheckers.ignore.hasAnnotationOf(field)) continue;

      final fieldMeta = _extractFieldMetadata(field);
      final propertyName = fieldMeta.name ?? field.name;
      final typeSpec = buildFromType(field.type, fieldMeta: fieldMeta);

      final isRequired = field.type.nullabilitySuffix == NullabilitySuffix.none;

      properties[propertyName] = PropertySpec(
        name: field.name,
        jsonName: fieldMeta.name,
        type: typeSpec,
        required: isRequired,
      );

      if (isRequired) {
        required.add(propertyName);
      }
    }

    return ObjectSpec(
      name: element.name,
      properties: properties,
      required: required,
      description: cleanDocComment(element.documentationComment),
    );
  }

  EnumSpec _buildEnumSpec(EnumElement element) {
    final values = <EnumValueSpec>[];

    for (final field in element.fields) {
      if (!field.isEnumConstant) continue;

      // Check for @JsonValue annotation
      String? jsonValue;
      final jsonValueAnnotation =
          TypeCheckers.jsonValue.firstAnnotationOf(field);
      if (jsonValueAnnotation != null) {
        final value = jsonValueAnnotation.getField('value');
        if (value != null && !value.isNull) {
          jsonValue = value.toStringValue();
        }
      }

      values.add(EnumValueSpec(
        name: field.name,
        jsonValue: jsonValue,
        description: cleanDocComment(field.documentationComment),
      ));
    }

    return EnumSpec(
      name: element.name,
      values: values,
      description: cleanDocComment(element.documentationComment),
    );
  }

  FieldMetadata _extractFieldMetadata(Element element) {
    // Check for @Field annotation
    final fieldAnnotation = TypeCheckers.field.firstAnnotationOf(element);
    if (fieldAnnotation != null) {
      return FieldMetadata.fromAnnotation(ConstantReader(fieldAnnotation));
    }

    // Check for @JsonKey annotation
    final jsonKeyAnnotation = TypeCheckers.jsonKey.firstAnnotationOf(element);
    if (jsonKeyAnnotation != null) {
      final reader = ConstantReader(jsonKeyAnnotation);
      final nameValue = reader.peek('name');
      return FieldMetadata(
        name: nameValue?.isNull == false ? nameValue?.stringValue : null,
        description: cleanDocComment(element.documentationComment),
      );
    }

    // Default metadata from doc comments
    return FieldMetadata(
      description: cleanDocComment(element.documentationComment),
    );
  }

  TypeSpec _applyFieldMetadata(TypeSpec spec, FieldMetadata meta) {
    // Apply description if not already set
    if (meta.description != null && spec.description == null) {
      return spec.withDescription(meta.description!);
    }
    return spec;
  }
}

/// Metadata extracted from field annotations.
class FieldMetadata {
  final String? name;
  final String? description;
  final bool deprecated;
  final List<Object>? examples;

  // String constraints
  final int? minLength;
  final int? maxLength;
  final String? pattern;
  final StringFormat? format;

  // Number constraints
  final num? minimum;
  final num? maximum;
  final bool? exclusiveMinimum;
  final bool? exclusiveMaximum;
  final num? multipleOf;

  // Array constraints
  final int? minItems;
  final int? maxItems;
  final bool? uniqueItems;

  const FieldMetadata({
    this.name,
    this.description,
    this.deprecated = false,
    this.examples,
    this.minLength,
    this.maxLength,
    this.pattern,
    this.format,
    this.minimum,
    this.maximum,
    this.exclusiveMinimum,
    this.exclusiveMaximum,
    this.multipleOf,
    this.minItems,
    this.maxItems,
    this.uniqueItems,
  });

  factory FieldMetadata.fromAnnotation(ConstantReader reader) {
    StringFormat? format;
    final formatValue = reader.peek('format');
    if (formatValue != null && !formatValue.isNull) {
      final enumIndex = formatValue.objectValue.getField('index')?.toIntValue();
      if (enumIndex != null) {
        format = StringFormat.values[enumIndex];
      }
    }

    return FieldMetadata(
      name: _readString(reader, 'name'),
      description: _readString(reader, 'description'),
      deprecated: reader.peek('deprecated')?.boolValue ?? false,
      examples: _readList(reader, 'examples'),
      minLength: _readInt(reader, 'minLength'),
      maxLength: _readInt(reader, 'maxLength'),
      pattern: _readString(reader, 'pattern'),
      format: format,
      minimum: _readNum(reader, 'minimum'),
      maximum: _readNum(reader, 'maximum'),
      exclusiveMinimum: reader.peek('exclusiveMinimum')?.boolValue,
      exclusiveMaximum: reader.peek('exclusiveMaximum')?.boolValue,
      multipleOf: _readNum(reader, 'multipleOf'),
      minItems: _readInt(reader, 'minItems'),
      maxItems: _readInt(reader, 'maxItems'),
      uniqueItems: reader.peek('uniqueItems')?.boolValue,
    );
  }

  static String? _readString(ConstantReader reader, String field) {
    final value = reader.peek(field);
    return value?.isNull == false ? value?.stringValue : null;
  }

  static int? _readInt(ConstantReader reader, String field) {
    final value = reader.peek(field);
    return value?.isNull == false ? value?.intValue : null;
  }

  static num? _readNum(ConstantReader reader, String field) {
    final value = reader.peek(field);
    if (value == null || value.isNull) return null;
    return value.isInt ? value.intValue : value.doubleValue;
  }

  static List<Object>? _readList(ConstantReader reader, String field) {
    final value = reader.peek(field);
    if (value == null || value.isNull) return null;
    return value.listValue.map((e) => _dartObjectToValue(e)).toList();
  }

  static Object _dartObjectToValue(DartObject obj) {
    if (obj.isNull) return 'null';
    if (obj.toStringValue() != null) return obj.toStringValue()!;
    if (obj.toIntValue() != null) return obj.toIntValue()!;
    if (obj.toDoubleValue() != null) return obj.toDoubleValue()!;
    if (obj.toBoolValue() != null) return obj.toBoolValue()!;
    return obj.toString();
  }
}
