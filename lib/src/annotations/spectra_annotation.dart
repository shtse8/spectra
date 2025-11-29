import 'formats.dart';

/// Marks a class for schema generation.
///
/// Apply this annotation to classes that should have schemas generated.
/// Works with `@freezed`, `@JsonSerializable`, and plain Dart classes.
///
/// ```dart
/// @Spectra(
///   title: 'User',
///   description: 'A user in the system',
/// )
/// class User {
///   final String name;
///   final int age;
/// }
/// ```
class Spectra {
  /// Optional title for the schema.
  ///
  /// If not provided, the class name is used.
  final String? title;

  /// Optional description for the schema.
  ///
  /// Can also be provided via doc comments on the class.
  final String? description;

  /// Output formats to generate.
  ///
  /// Defaults to [SpectraFormat.jsonSchema] if not specified.
  final Set<SpectraFormat>? formats;

  /// Whether to allow additional properties not defined in the schema.
  ///
  /// Defaults to `false` for stricter validation.
  final bool additionalProperties;

  /// Creates a new [Spectra] annotation.
  const Spectra({
    this.title,
    this.description,
    this.formats,
    this.additionalProperties = false,
  });
}

/// Convenience constant for [Spectra] with default options.
const spectra = Spectra();
