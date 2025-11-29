# Spectra

[![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![pub package](https://img.shields.io/pub/v/spectra.svg)](https://pub.dev/packages/spectra)

Transform your Dart data classes into **JSON Schema**, **OpenAPI**, and **Protocol Buffers** specifications with a single annotation.

```dart
@Spectra()
@freezed
class User with _$User {
  const factory User({
    @Field(format: StringFormat.email) required String email,
    @Field(minimum: 0, maximum: 150) int? age,
  }) = _User;
}
```

## Features

| Feature | Description |
|---------|-------------|
| 🎯 **Multi-format** | JSON Schema, OpenAPI 3.0/3.1, Protocol Buffers |
| 🧊 **Freezed** | Full support including union types |
| 📦 **json_serializable** | Seamless integration |
| ✅ **Constraints** | String, number, array validation |
| 🔗 **References** | `$ref`, `$defs`, discriminated unions |

## Installation

```bash
dart pub add spectra
dart pub add dev:build_runner
```

## Quick Start

### 1. Annotate your class

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:spectra/spectra.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
@Spectra(title: 'User')
class User with _$User {
  const factory User({
    @Field(minLength: 1, maxLength: 100) required String name,
    @Field(format: StringFormat.email) required String email,
    @Field(minimum: 0) int? age,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  @spectraOutput
  static String get jsonSchema => _$UserJsonSchema;
}
```

### 2. Configure build.yaml

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

### 3. Generate

```bash
dart run build_runner build
```

### 4. Use

```dart
print(User.jsonSchema);
// {
//   "$schema": "https://json-schema.org/draft/2020-12/schema",
//   "title": "User",
//   "type": "object",
//   "properties": {
//     "name": { "type": "string", "minLength": 1, "maxLength": 100 },
//     "email": { "type": "string", "format": "email" },
//     "age": { "type": ["integer", "null"], "minimum": 0 }
//   },
//   "required": ["name", "email"]
// }
```

## Annotations

### @Spectra

```dart
@Spectra(
  title: 'User',
  description: 'A user object',
  formats: {SpectraFormat.jsonSchema, SpectraFormat.openApi},
  additionalProperties: false,
)
```

### @Field

```dart
// String
@Field(minLength: 1, maxLength: 100, pattern: r'^\w+$', format: StringFormat.email)

// Number
@Field(minimum: 0, maximum: 100, exclusiveMinimum: true, multipleOf: 0.5)

// Array
@Field(minItems: 1, maxItems: 10, uniqueItems: true)

// Meta
@Field(description: 'User email', deprecated: true, examples: ['a@b.com'])
```

### @Ignore

```dart
@Ignore()
String internalField;
```

## Union Types

```dart
@freezed
@Spectra()
sealed class Result with _$Result {
  const factory Result.success({required String data}) = Success;
  const factory Result.error({required String message}) = Error;
}
```

Generates `oneOf` with discriminator:

```json
{
  "oneOf": [
    { "$ref": "#/$defs/Success" },
    { "$ref": "#/$defs/Error" }
  ],
  "discriminator": { "propertyName": "runtimeType" }
}
```

## Output Formats

### JSON Schema (Draft 2020-12)

```dart
@Spectra(formats: {SpectraFormat.jsonSchema})
```

### OpenAPI 3.0/3.1

```dart
@Spectra(formats: {SpectraFormat.openApi})
```

### Protocol Buffers

```dart
@Spectra(formats: {SpectraFormat.protobuf})
```

```protobuf
syntax = "proto3";

message User {
  string name = 1;
  string email = 2;
  optional int64 age = 3;
}
```

## String Formats

| Format | Example |
|--------|---------|
| `email` | `user@example.com` |
| `uri` | `https://example.com` |
| `uuid` | `550e8400-e29b-41d4-a716-446655440000` |
| `dateTime` | `2024-01-15T09:30:00Z` |
| `date` | `2024-01-15` |
| `time` | `09:30:00` |
| `ipv4` | `192.168.1.1` |
| `ipv6` | `2001:db8::1` |
| `hostname` | `example.com` |

## Migration from SotiSchema

```diff
- import 'package:soti_schema/soti_schema.dart';
+ import 'package:spectra/spectra.dart';

- @SotiSchema()
+ @Spectra()

- @jsonSchema
+ @spectraOutput

# build.yaml
- soti_schema|openApiBuilder
+ spectra|spectra
```

## License

MIT
