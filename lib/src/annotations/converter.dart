/// Custom schema converter for complex types.
///
/// Implement this interface to provide custom schema generation logic
/// for types that need special handling.
///
/// ```dart
/// class MoneyConverter implements SpecConverter {
///   const MoneyConverter();
///
///   @override
///   Map<String, dynamic> convert() {
///     return {
///       'type': 'object',
///       'properties': {
///         'amount': {'type': 'number'},
///         'currency': {'type': 'string', 'minLength': 3, 'maxLength': 3},
///       },
///       'required': ['amount', 'currency'],
///     };
///   }
/// }
/// ```
abstract class SpecConverter {
  /// Converts the annotated type to a schema map.
  Map<String, dynamic> convert();
}

/// Applies a custom converter to a field for schema generation.
///
/// ```dart
/// @Spectra()
/// class Order {
///   @Converter(MoneyConverter())
///   final Money total;
/// }
/// ```
class Converter {
  /// The converter instance to use.
  final SpecConverter converter;

  /// Creates a new [Converter] annotation.
  const Converter(this.converter);
}
