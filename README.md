# Spectra

**Spectra** transforms your Dart data classes into JSON Schema, OpenAPI, and Protocol Buffers specifications. Whether you're working with `freezed`, `json_serializable`, or plain Dart classes, Spectra simplifies schema generation with powerful annotations and flexible output formats.

---

## Features

- **Multi-format Output**: Generate JSON Schema, OpenAPI 3.0/3.1, and Protocol Buffers from a single source
- **Flexible Annotations**: Rich annotation system for constraints, descriptions, and customization
- **Framework Support**: Works with `freezed`, `json_serializable`, and plain Dart classes
- **Union Types**: Full support for Freezed sealed class unions with discriminators
- **Type Safety**: Comprehensive validation constraints for strings, numbers, and arrays

---

## Installation

```bash
dart pub add spectra
dart pub add dev:build_runner
```

## Configuration

Add to your `build.yaml`:

```yaml
targets:
  $default:
    builders:
      json_serializable:
        options:
          explicit_to_json: true

global_options:
  freezed|freezed:
    runs_before:
      - spectra|spectra
```

---

## Quick Start

### With Freezed

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:spectra/spectra.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
@Spectra(title: 'User', description: 'A user in the system')
class User with _$User {
  const factory User({
    /// The user's display name
    @Field(minLength: 1, maxLength: 100) required String name,

    /// Email address
    @Field(format: StringFormat.email) required String email,

    /// Age in years
    @Field(minimum: 0, maximum: 150) int? age,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  @spectraOutput
  static String get jsonSchema => _$UserJsonSchema;

  @spectraOutput
  static Map<String, dynamic> get jsonSchemaMap => _$UserJsonSchemaMap;
}
```

### With JsonSerializable

```dart
import 'package:json_annotation/json_annotation.dart';
import 'package:spectra/spectra.dart';

part 'product.g.dart';

@JsonSerializable()
@Spectra(formats: {SpectraFormat.jsonSchema, SpectraFormat.openApi})
class Product {
  /// Product name
  @Field(minLength: 1)
  final String name;

  /// Price in cents
  @Field(minimum: 0)
  final int price;

  /// Available tags
  @Field(minItems: 0, maxItems: 10, uniqueItems: true)
  final List<String> tags;

  Product({
    required this.name,
    required this.price,
    this.tags = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
  Map<String, dynamic> toJson() => _$ProductToJson(this);

  @spectraOutput
  static String get schema => _$ProductJsonSchema;
}
```

### Union Types (Sealed Classes)

```dart
@freezed
@Spectra()
sealed class Result with _$Result {
  const factory Result.success({required String data}) = Success;
  const factory Result.error({required String message, int? code}) = Error;

  factory Result.fromJson(Map<String, dynamic> json) => _$ResultFromJson(json);

  @spectraOutput
  static String get schema => _$ResultJsonSchema;
}
```

Generated schema includes `oneOf` with discriminator:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "oneOf": [
    { "$ref": "#/$defs/Success" },
    { "$ref": "#/$defs/Error" }
  ],
  "discriminator": { "propertyName": "runtimeType" }
}
```

---

## Annotations

### @Spectra

Class-level annotation for schema configuration.

```dart
@Spectra(
  title: 'User',                    // Schema title
  description: 'A user object',     // Schema description
  formats: {SpectraFormat.jsonSchema, SpectraFormat.openApi},
  additionalProperties: false,      // Disallow extra properties
)
```

### @Field

Field-level constraints and metadata.

```dart
// String constraints
@Field(
  minLength: 1,
  maxLength: 100,
  pattern: r'^[a-z]+$',
  format: StringFormat.email,
)
String email;

// Number constraints
@Field(
  minimum: 0,
  maximum: 100,
  exclusiveMinimum: true,
  multipleOf: 0.5,
)
double score;

// Array constraints
@Field(
  minItems: 1,
  maxItems: 10,
  uniqueItems: true,
)
List<String> tags;

// Common options
@Field(
  description: 'Custom description',
  deprecated: true,
  examples: ['example1', 'example2'],
)
```

### @Ignore

Exclude fields from schema generation.

```dart
@Ignore()
String internalField;
```

### @spectraOutput

Mark getters that return generated schema.

```dart
@spectraOutput
static String get jsonSchema => _$UserJsonSchema;

@spectraOutput
static Map<String, dynamic> get schemaMap => _$UserJsonSchemaMap;
```

---

## String Formats

Spectra supports standard JSON Schema string formats:

| Format | Description |
|--------|-------------|
| `StringFormat.email` | Email address |
| `StringFormat.uri` | URI |
| `StringFormat.uuid` | UUID |
| `StringFormat.dateTime` | ISO 8601 date-time |
| `StringFormat.date` | ISO 8601 date |
| `StringFormat.time` | ISO 8601 time |
| `StringFormat.ipv4` | IPv4 address |
| `StringFormat.ipv6` | IPv6 address |
| `StringFormat.hostname` | Hostname |
| `StringFormat.regex` | Regular expression |

---

## Output Formats

### JSON Schema (Draft 2020-12)

```dart
@Spectra(formats: {SpectraFormat.jsonSchema})
```

Generates compliant JSON Schema with full support for:
- Type constraints (string, number, array)
- Nullable types via `type: ["string", "null"]`
- References via `$ref` and `$defs`
- Union types via `oneOf`

### OpenAPI 3.0/3.1

```dart
@Spectra(formats: {SpectraFormat.openApi})
```

Generates OpenAPI-compatible schemas with:
- OpenAPI 3.0 nullable support (`nullable: true`)
- OpenAPI 3.1 JSON Schema compatibility
- Component references (`#/components/schemas/`)

### Protocol Buffers

```dart
@Spectra(formats: {SpectraFormat.protobuf})
```

Generates proto3 message definitions:

```protobuf
syntax = "proto3";

message User {
  string name = 1;
  string email = 2;
  optional int32 age = 3;
}
```

---

## Running the Generator

```bash
dart run build_runner build
```

Or watch for changes:

```bash
dart run build_runner watch
```

---

## Generated Files

For a file `user.dart`, Spectra generates:

- `user.g.dart` - Contains schema getters (`_$UserJsonSchema`, `_$UserJsonSchemaMap`)

Access via your annotated getters:

```dart
print(User.jsonSchema);     // JSON string
print(User.jsonSchemaMap);  // Map<String, dynamic>
```

---

## Migration from SotiSchema

If upgrading from SotiSchema 1.x:

1. Update import: `package:soti_schema/soti_schema.dart` → `package:spectra/spectra.dart`
2. Rename annotation: `@SotiSchema()` → `@Spectra()`
3. Rename output marker: `@jsonSchema` → `@spectraOutput`
4. Update build.yaml: `soti_schema|openApiBuilder` → `spectra|spectra`

---

## License

MIT License - see [LICENSE](LICENSE) for details.
