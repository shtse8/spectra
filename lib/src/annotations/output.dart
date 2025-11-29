/// Marks a static getter as an output target for generated schema.
///
/// Apply this annotation to static getters that should receive the
/// generated schema content.
///
/// ```dart
/// @Spectra()
/// class User {
///   final String name;
///
///   @spectraOutput
///   static String get jsonSchema => _$UserJsonSchema;
///
///   @spectraOutput
///   static Map<String, dynamic> get schemaMap => _$UserSchemaMap;
/// }
/// ```
class SpectraOutput {
  /// Creates a new [SpectraOutput] annotation.
  const SpectraOutput();
}

/// Convenience constant for [SpectraOutput].
const spectraOutput = SpectraOutput();
