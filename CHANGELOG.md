# Changelog

## 2.0.0

### Breaking Changes

- **Renamed package**: `soti_schema` → `spectra`
- **Renamed main annotation**: `@SotiSchema()` → `@Spectra()`
- **Renamed output marker**: `@jsonSchema` → `@spectraOutput`
- **Builder renamed**: `soti_schema|openApiBuilder` → `spectra|spectra`

### New Features

- **Multi-format output**: Generate JSON Schema, OpenAPI 3.0/3.1, and Protocol Buffers from a single source
- **TypeSpec IR**: New intermediate representation for type-safe schema generation
- **Comprehensive constraints**: Full support for string, number, and array validation constraints
- **Union types**: Support for Freezed sealed class unions with discriminators
- **Nullable types**: Proper handling via `type: ["string", "null"]` pattern
- **Field annotation**: Rich `@Field` annotation with all JSON Schema constraints
- **Ignore annotation**: `@Ignore()` to exclude fields from schema generation
- **Custom converters**: `@Converter` annotation for custom type handling
- **Multiple extractors**: Support for Freezed, JsonSerializable, and plain Dart classes

### Architecture

- **Modular design**: Extractor → IR → Emitter pipeline
- **Sealed class hierarchy**: Type-safe TypeSpec IR with exhaustive pattern matching
- **Extensible emitters**: Easy to add new output formats

### Bug Fixes

- Fixed `$ref` string interpolation bug in JSON Schema output
- Fixed enum handling that was never being invoked
- Fixed nullable type support

## 1.0.0

- Initial version.
