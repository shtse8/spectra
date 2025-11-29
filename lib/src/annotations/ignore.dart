/// Excludes a field from schema generation.
///
/// Apply this annotation to fields that should not appear in the
/// generated schema.
///
/// ```dart
/// @Spectra()
/// class User {
///   final String name;
///
///   @Ignore()
///   final String internalId;  // Won't appear in schema
/// }
/// ```
class Ignore {
  /// Creates a new [Ignore] annotation.
  const Ignore();
}

/// Convenience constant for [Ignore].
const ignore = Ignore();
