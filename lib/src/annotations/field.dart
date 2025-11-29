import 'formats.dart';

/// Customizes schema generation for a specific field or parameter.
///
/// Apply this annotation to class fields or constructor parameters to
/// provide additional schema metadata.
///
/// ```dart
/// @Spectra()
/// class User {
///   @Field(
///     description: 'User email address',
///     format: StringFormat.email,
///   )
///   final String email;
///
///   @Field(
///     description: 'User age',
///     minimum: 0,
///     maximum: 150,
///   )
///   final int age;
/// }
/// ```
class Field {
  // === Basic metadata ===

  /// Override the property name in the schema.
  ///
  /// By default, the Dart field name is used.
  final String? name;

  /// Description of this field.
  ///
  /// Can also be provided via doc comments.
  final String? description;

  /// Mark this field as deprecated.
  final bool deprecated;

  /// Example values for this field.
  final List<Object>? examples;

  // === String constraints ===

  /// Minimum length for string values.
  final int? minLength;

  /// Maximum length for string values.
  final int? maxLength;

  /// Regular expression pattern for string validation.
  final String? pattern;

  /// Format hint for string values.
  final StringFormat? format;

  // === Number constraints ===

  /// Minimum value for numeric types.
  final num? minimum;

  /// Maximum value for numeric types.
  final num? maximum;

  /// Whether the minimum is exclusive.
  final bool exclusiveMinimum;

  /// Whether the maximum is exclusive.
  final bool exclusiveMaximum;

  /// Value must be a multiple of this number.
  final num? multipleOf;

  // === Array constraints ===

  /// Minimum number of items in an array.
  final int? minItems;

  /// Maximum number of items in an array.
  final int? maxItems;

  /// Whether array items must be unique.
  final bool uniqueItems;

  /// Creates a new [Field] annotation.
  const Field({
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
    this.exclusiveMinimum = false,
    this.exclusiveMaximum = false,
    this.multipleOf,
    this.minItems,
    this.maxItems,
    this.uniqueItems = false,
  });
}
