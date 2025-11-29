/// Intermediate Representation (IR) for schema types.
///
/// These types represent the abstract schema structure that can be
/// transformed into various output formats (JSON Schema, OpenAPI, Protobuf).
library spectra.spec;

import '../annotations/formats.dart';

// Re-export for convenience
export '../annotations/formats.dart' show StringFormat;

/// Base class for all type specifications.
///
/// This sealed class hierarchy represents the intermediate representation
/// of schema types that can be transformed into various output formats.
sealed class TypeSpec {
  /// Optional description of this type.
  final String? description;

  /// Whether this type accepts null values.
  final bool nullable;

  /// Example values for documentation.
  final List<Object>? examples;

  /// Whether this type is deprecated.
  final bool isDeprecated;

  /// Creates a new [TypeSpec].
  const TypeSpec({
    this.description,
    this.nullable = false,
    this.examples,
    this.isDeprecated = false,
  });

  /// Creates a copy of this spec with nullable set to true.
  TypeSpec asNullable();

  /// Creates a copy of this spec with the given description.
  TypeSpec withDescription(String description);
}

/// Specification for string types.
final class StringSpec extends TypeSpec {
  /// Format hint for the string value.
  final StringFormat? format;

  /// Regular expression pattern for validation.
  final String? pattern;

  /// Minimum length of the string.
  final int? minLength;

  /// Maximum length of the string.
  final int? maxLength;

  /// Default value.
  final String? defaultValue;

  /// Creates a new [StringSpec].
  const StringSpec({
    this.format,
    this.pattern,
    this.minLength,
    this.maxLength,
    this.defaultValue,
    super.description,
    super.nullable,
    super.examples,
    super.isDeprecated,
  });

  @override
  StringSpec asNullable() => StringSpec(
        format: format,
        pattern: pattern,
        minLength: minLength,
        maxLength: maxLength,
        defaultValue: defaultValue,
        description: description,
        nullable: true,
        examples: examples,
        isDeprecated: isDeprecated,
      );

  @override
  StringSpec withDescription(String description) => StringSpec(
        format: format,
        pattern: pattern,
        minLength: minLength,
        maxLength: maxLength,
        defaultValue: defaultValue,
        description: description,
        nullable: nullable,
        examples: examples,
        isDeprecated: isDeprecated,
      );

  /// Creates a copy with the given modifications.
  StringSpec copyWith({
    StringFormat? format,
    String? pattern,
    int? minLength,
    int? maxLength,
    String? defaultValue,
    String? description,
    bool? nullable,
    List<Object>? examples,
    bool? isDeprecated,
  }) =>
      StringSpec(
        format: format ?? this.format,
        pattern: pattern ?? this.pattern,
        minLength: minLength ?? this.minLength,
        maxLength: maxLength ?? this.maxLength,
        defaultValue: defaultValue ?? this.defaultValue,
        description: description ?? this.description,
        nullable: nullable ?? this.nullable,
        examples: examples ?? this.examples,
        isDeprecated: isDeprecated ?? this.isDeprecated,
      );
}

/// Specification for numeric types (integer and floating-point).
final class NumberSpec extends TypeSpec {
  /// Whether this is an integer type.
  final bool isInteger;

  /// Minimum value.
  final num? minimum;

  /// Maximum value.
  final num? maximum;

  /// Whether the minimum is exclusive.
  final bool exclusiveMinimum;

  /// Whether the maximum is exclusive.
  final bool exclusiveMaximum;

  /// Value must be a multiple of this number.
  final num? multipleOf;

  /// Default value.
  final num? defaultValue;

  /// Creates a new [NumberSpec].
  const NumberSpec({
    this.isInteger = false,
    this.minimum,
    this.maximum,
    this.exclusiveMinimum = false,
    this.exclusiveMaximum = false,
    this.multipleOf,
    this.defaultValue,
    super.description,
    super.nullable,
    super.examples,
    super.isDeprecated,
  });

  /// Creates an integer spec.
  const NumberSpec.integer({
    num? minimum,
    num? maximum,
    bool exclusiveMinimum = false,
    bool exclusiveMaximum = false,
    num? multipleOf,
    int? defaultValue,
    String? description,
    bool nullable = false,
    List<Object>? examples,
    bool isDeprecated = false,
  }) : this(
          isInteger: true,
          minimum: minimum,
          maximum: maximum,
          exclusiveMinimum: exclusiveMinimum,
          exclusiveMaximum: exclusiveMaximum,
          multipleOf: multipleOf,
          defaultValue: defaultValue,
          description: description,
          nullable: nullable,
          examples: examples,
          isDeprecated: isDeprecated,
        );

  /// Creates a double/number spec.
  const NumberSpec.double({
    num? minimum,
    num? maximum,
    bool exclusiveMinimum = false,
    bool exclusiveMaximum = false,
    num? multipleOf,
    double? defaultValue,
    String? description,
    bool nullable = false,
    List<Object>? examples,
    bool isDeprecated = false,
  }) : this(
          isInteger: false,
          minimum: minimum,
          maximum: maximum,
          exclusiveMinimum: exclusiveMinimum,
          exclusiveMaximum: exclusiveMaximum,
          multipleOf: multipleOf,
          defaultValue: defaultValue,
          description: description,
          nullable: nullable,
          examples: examples,
          isDeprecated: isDeprecated,
        );

  @override
  NumberSpec asNullable() => NumberSpec(
        isInteger: isInteger,
        minimum: minimum,
        maximum: maximum,
        exclusiveMinimum: exclusiveMinimum,
        exclusiveMaximum: exclusiveMaximum,
        multipleOf: multipleOf,
        defaultValue: defaultValue,
        description: description,
        nullable: true,
        examples: examples,
        isDeprecated: isDeprecated,
      );

  @override
  NumberSpec withDescription(String description) => NumberSpec(
        isInteger: isInteger,
        minimum: minimum,
        maximum: maximum,
        exclusiveMinimum: exclusiveMinimum,
        exclusiveMaximum: exclusiveMaximum,
        multipleOf: multipleOf,
        defaultValue: defaultValue,
        description: description,
        nullable: nullable,
        examples: examples,
        isDeprecated: isDeprecated,
      );

  /// Creates a copy with the given modifications.
  NumberSpec copyWith({
    bool? isInteger,
    num? minimum,
    num? maximum,
    bool? exclusiveMinimum,
    bool? exclusiveMaximum,
    num? multipleOf,
    num? defaultValue,
    String? description,
    bool? nullable,
    List<Object>? examples,
    bool? isDeprecated,
  }) =>
      NumberSpec(
        isInteger: isInteger ?? this.isInteger,
        minimum: minimum ?? this.minimum,
        maximum: maximum ?? this.maximum,
        exclusiveMinimum: exclusiveMinimum ?? this.exclusiveMinimum,
        exclusiveMaximum: exclusiveMaximum ?? this.exclusiveMaximum,
        multipleOf: multipleOf ?? this.multipleOf,
        defaultValue: defaultValue ?? this.defaultValue,
        description: description ?? this.description,
        nullable: nullable ?? this.nullable,
        examples: examples ?? this.examples,
        isDeprecated: isDeprecated ?? this.isDeprecated,
      );
}

/// Specification for boolean types.
final class BoolSpec extends TypeSpec {
  /// Default value.
  final bool? defaultValue;

  /// Creates a new [BoolSpec].
  const BoolSpec({
    this.defaultValue,
    super.description,
    super.nullable,
    super.examples,
    super.isDeprecated,
  });

  @override
  BoolSpec asNullable() => BoolSpec(
        defaultValue: defaultValue,
        description: description,
        nullable: true,
        examples: examples,
        isDeprecated: isDeprecated,
      );

  @override
  BoolSpec withDescription(String description) => BoolSpec(
        defaultValue: defaultValue,
        description: description,
        nullable: nullable,
        examples: examples,
        isDeprecated: isDeprecated,
      );

  /// Creates a copy with the given modifications.
  BoolSpec copyWith({
    bool? defaultValue,
    String? description,
    bool? nullable,
    List<Object>? examples,
    bool? isDeprecated,
  }) =>
      BoolSpec(
        defaultValue: defaultValue ?? this.defaultValue,
        description: description ?? this.description,
        nullable: nullable ?? this.nullable,
        examples: examples ?? this.examples,
        isDeprecated: isDeprecated ?? this.isDeprecated,
      );
}

/// Specification for an object property.
final class PropertySpec {
  /// The Dart field name.
  final String name;

  /// The JSON/serialized name (may differ from [name]).
  final String? jsonName;

  /// The type specification of this property.
  final TypeSpec type;

  /// Whether this property is required.
  final bool required;

  /// Creates a new [PropertySpec].
  const PropertySpec({
    required this.name,
    this.jsonName,
    required this.type,
    this.required = true,
  });

  /// Returns the effective name to use in the schema.
  String get effectiveName => jsonName ?? name;

  /// Creates a copy with the given modifications.
  PropertySpec copyWith({
    String? name,
    String? jsonName,
    TypeSpec? type,
    bool? required,
  }) =>
      PropertySpec(
        name: name ?? this.name,
        jsonName: jsonName ?? this.jsonName,
        type: type ?? this.type,
        required: required ?? this.required,
      );
}

/// Specification for object types with named properties.
final class ObjectSpec extends TypeSpec {
  /// The name of this object type.
  final String name;

  /// The properties of this object, keyed by their effective name.
  final Map<String, PropertySpec> properties;

  /// Names of required properties.
  final List<String> required;

  /// Whether additional properties are allowed.
  final bool additionalProperties;

  /// Optional title for the schema.
  final String? title;

  /// Creates a new [ObjectSpec].
  const ObjectSpec({
    required this.name,
    required this.properties,
    this.required = const [],
    this.additionalProperties = false,
    this.title,
    super.description,
    super.nullable,
    super.examples,
    super.isDeprecated,
  });

  @override
  ObjectSpec asNullable() => ObjectSpec(
        name: name,
        properties: properties,
        required: required,
        additionalProperties: additionalProperties,
        title: title,
        description: description,
        nullable: true,
        examples: examples,
        isDeprecated: isDeprecated,
      );

  @override
  ObjectSpec withDescription(String description) => ObjectSpec(
        name: name,
        properties: properties,
        required: required,
        additionalProperties: additionalProperties,
        title: title,
        description: description,
        nullable: nullable,
        examples: examples,
        isDeprecated: isDeprecated,
      );

  /// Creates a copy with the given modifications.
  ObjectSpec copyWith({
    String? name,
    Map<String, PropertySpec>? properties,
    List<String>? required,
    bool? additionalProperties,
    String? title,
    String? description,
    bool? nullable,
    List<Object>? examples,
    bool? isDeprecated,
  }) =>
      ObjectSpec(
        name: name ?? this.name,
        properties: properties ?? this.properties,
        required: required ?? this.required,
        additionalProperties: additionalProperties ?? this.additionalProperties,
        title: title ?? this.title,
        description: description ?? this.description,
        nullable: nullable ?? this.nullable,
        examples: examples ?? this.examples,
        isDeprecated: isDeprecated ?? this.isDeprecated,
      );
}

/// Specification for array/list types.
final class ArraySpec extends TypeSpec {
  /// The type specification for array items.
  final TypeSpec items;

  /// Minimum number of items.
  final int? minItems;

  /// Maximum number of items.
  final int? maxItems;

  /// Whether items must be unique.
  final bool uniqueItems;

  /// Default value.
  final List<Object>? defaultValue;

  /// Creates a new [ArraySpec].
  const ArraySpec({
    required this.items,
    this.minItems,
    this.maxItems,
    this.uniqueItems = false,
    this.defaultValue,
    super.description,
    super.nullable,
    super.examples,
    super.isDeprecated,
  });

  @override
  ArraySpec asNullable() => ArraySpec(
        items: items,
        minItems: minItems,
        maxItems: maxItems,
        uniqueItems: uniqueItems,
        defaultValue: defaultValue,
        description: description,
        nullable: true,
        examples: examples,
        isDeprecated: isDeprecated,
      );

  @override
  ArraySpec withDescription(String description) => ArraySpec(
        items: items,
        minItems: minItems,
        maxItems: maxItems,
        uniqueItems: uniqueItems,
        defaultValue: defaultValue,
        description: description,
        nullable: nullable,
        examples: examples,
        isDeprecated: isDeprecated,
      );

  /// Creates a copy with the given modifications.
  ArraySpec copyWith({
    TypeSpec? items,
    int? minItems,
    int? maxItems,
    bool? uniqueItems,
    List<Object>? defaultValue,
    String? description,
    bool? nullable,
    List<Object>? examples,
    bool? isDeprecated,
  }) =>
      ArraySpec(
        items: items ?? this.items,
        minItems: minItems ?? this.minItems,
        maxItems: maxItems ?? this.maxItems,
        uniqueItems: uniqueItems ?? this.uniqueItems,
        defaultValue: defaultValue ?? this.defaultValue,
        description: description ?? this.description,
        nullable: nullable ?? this.nullable,
        examples: examples ?? this.examples,
        isDeprecated: isDeprecated ?? this.isDeprecated,
      );
}

/// Specification for map/dictionary types.
final class MapSpec extends TypeSpec {
  /// The type specification for map keys.
  ///
  /// In JSON Schema, keys are always strings, but this is preserved
  /// for documentation and other formats.
  final TypeSpec keyType;

  /// The type specification for map values.
  final TypeSpec valueType;

  /// Creates a new [MapSpec].
  const MapSpec({
    required this.keyType,
    required this.valueType,
    super.description,
    super.nullable,
    super.examples,
    super.isDeprecated,
  });

  @override
  MapSpec asNullable() => MapSpec(
        keyType: keyType,
        valueType: valueType,
        description: description,
        nullable: true,
        examples: examples,
        isDeprecated: isDeprecated,
      );

  @override
  MapSpec withDescription(String description) => MapSpec(
        keyType: keyType,
        valueType: valueType,
        description: description,
        nullable: nullable,
        examples: examples,
        isDeprecated: isDeprecated,
      );

  /// Creates a copy with the given modifications.
  MapSpec copyWith({
    TypeSpec? keyType,
    TypeSpec? valueType,
    String? description,
    bool? nullable,
    List<Object>? examples,
    bool? isDeprecated,
  }) =>
      MapSpec(
        keyType: keyType ?? this.keyType,
        valueType: valueType ?? this.valueType,
        description: description ?? this.description,
        nullable: nullable ?? this.nullable,
        examples: examples ?? this.examples,
        isDeprecated: isDeprecated ?? this.isDeprecated,
      );
}

/// Specification for a single enum value.
final class EnumValueSpec {
  /// The Dart enum value name.
  final String name;

  /// The JSON/serialized value (may differ from [name]).
  final String? jsonValue;

  /// Description of this enum value.
  final String? description;

  /// Creates a new [EnumValueSpec].
  const EnumValueSpec({
    required this.name,
    this.jsonValue,
    this.description,
  });

  /// Returns the effective value to use in the schema.
  String get effectiveValue => jsonValue ?? name;
}

/// Specification for enumeration types.
final class EnumSpec extends TypeSpec {
  /// The name of this enum type.
  final String name;

  /// The enum values.
  final List<EnumValueSpec> values;

  /// Creates a new [EnumSpec].
  const EnumSpec({
    required this.name,
    required this.values,
    super.description,
    super.nullable,
    super.examples,
    super.isDeprecated,
  });

  @override
  EnumSpec asNullable() => EnumSpec(
        name: name,
        values: values,
        description: description,
        nullable: true,
        examples: examples,
        isDeprecated: isDeprecated,
      );

  @override
  EnumSpec withDescription(String description) => EnumSpec(
        name: name,
        values: values,
        description: description,
        nullable: nullable,
        examples: examples,
        isDeprecated: isDeprecated,
      );

  /// Creates a copy with the given modifications.
  EnumSpec copyWith({
    String? name,
    List<EnumValueSpec>? values,
    String? description,
    bool? nullable,
    List<Object>? examples,
    bool? isDeprecated,
  }) =>
      EnumSpec(
        name: name ?? this.name,
        values: values ?? this.values,
        description: description ?? this.description,
        nullable: nullable ?? this.nullable,
        examples: examples ?? this.examples,
        isDeprecated: isDeprecated ?? this.isDeprecated,
      );
}

/// Specification for union/sealed class types.
///
/// Represents a type that can be one of several variants,
/// such as Freezed union types or Dart sealed classes.
final class UnionSpec extends TypeSpec {
  /// The name of this union type.
  final String name;

  /// The discriminator property name.
  ///
  /// This is used for polymorphic deserialization to determine
  /// which variant a JSON object represents.
  final String? discriminator;

  /// The possible variants of this union.
  final List<ObjectSpec> variants;

  /// Creates a new [UnionSpec].
  const UnionSpec({
    required this.name,
    this.discriminator,
    required this.variants,
    super.description,
    super.nullable,
    super.examples,
    super.isDeprecated,
  });

  @override
  UnionSpec asNullable() => UnionSpec(
        name: name,
        discriminator: discriminator,
        variants: variants,
        description: description,
        nullable: true,
        examples: examples,
        isDeprecated: isDeprecated,
      );

  @override
  UnionSpec withDescription(String description) => UnionSpec(
        name: name,
        discriminator: discriminator,
        variants: variants,
        description: description,
        nullable: nullable,
        examples: examples,
        isDeprecated: isDeprecated,
      );

  /// Creates a copy with the given modifications.
  UnionSpec copyWith({
    String? name,
    String? discriminator,
    List<ObjectSpec>? variants,
    String? description,
    bool? nullable,
    List<Object>? examples,
    bool? isDeprecated,
  }) =>
      UnionSpec(
        name: name ?? this.name,
        discriminator: discriminator ?? this.discriminator,
        variants: variants ?? this.variants,
        description: description ?? this.description,
        nullable: nullable ?? this.nullable,
        examples: examples ?? this.examples,
        isDeprecated: isDeprecated ?? this.isDeprecated,
      );
}

/// Specification for a reference to another type.
///
/// Used to avoid duplication when the same type appears multiple times
/// in a schema.
final class RefSpec extends TypeSpec {
  /// The name of the referenced type.
  final String typeName;

  /// Creates a new [RefSpec].
  const RefSpec({
    required this.typeName,
    super.nullable,
    super.description,
    super.examples,
    super.isDeprecated,
  });

  @override
  RefSpec asNullable() => RefSpec(
        typeName: typeName,
        nullable: true,
        description: description,
        examples: examples,
        isDeprecated: isDeprecated,
      );

  @override
  RefSpec withDescription(String description) => RefSpec(
        typeName: typeName,
        nullable: nullable,
        description: description,
        examples: examples,
        isDeprecated: isDeprecated,
      );

  /// Creates a copy with the given modifications.
  RefSpec copyWith({
    String? typeName,
    bool? nullable,
    String? description,
    List<Object>? examples,
    bool? isDeprecated,
  }) =>
      RefSpec(
        typeName: typeName ?? this.typeName,
        nullable: nullable ?? this.nullable,
        description: description ?? this.description,
        examples: examples ?? this.examples,
        isDeprecated: isDeprecated ?? this.isDeprecated,
      );
}
