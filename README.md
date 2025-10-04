# soti_schema_plus

soti_schema_plus is a fork of https://github.com/shtse8/SotiSchema, which
appears to be abandoned. It provides for generating JSON schemas directly from
your Dart data classes, whether you're working with `freezed` or
`json_serializable`.

This package automatically generates JSON Schema (draft 2020-12) from your Dart
classes, making it easy to maintain consistent schemas alongside your data
models.

## 🚀 Getting Started

### Installation

Add these dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  soti_schema_plus: ^1.3.0
  freezed_annotation: ^3.1.0  # if using freezed
  json_annotation: ^4.9.0      # if using json_serializable

dev_dependencies:
  build_runner: ^2.4.13
  freezed: ^3.2.0               # if using freezed
  json_serializable: ^6.11.0    # if using json_serializable
```

### Configuration

Configure your `build.yaml` file at the root of your project (this registers the
builder so dependents like your app/example can use it):

```yaml
builders:
  soti_schema:
    import: "package:soti_schema_plus/builder.dart"
    builder_factories: ["sotiSchemaBuilder"]
    build_extensions: {".dart": [".g.part"]}
    auto_apply: dependents
    build_to: cache
    applies_builders: ["source_gen|combining_builder"]
```

For projects using both `freezed` and `json_serializable`, add this to your
`build.yaml`:

```yaml
targets:
  $default:
    builders:
      json_serializable:
        options:
          explicit_to_json: true
```

- **`explicit_to_json: true`** ensures that nested objects are correctly
  serialized by generating explicit `toJson` methods.

### Run Code Generation

Generate the schema files using build_runner:

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## 💡 How to Use SotiSchema

### Example with `freezed`

Here's how to generate a JSON schema using SotiSchema with a `freezed` class:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:soti_schema_plus/annotations.dart';

part 'example_model.freezed.dart';
part 'example_model.g.dart';

@freezed
@SotiSchema()
class ExampleModel with _$ExampleModel {
  const ExampleModel._(); // Required for custom getters
  const factory ExampleModel({
    @Default('') String name,
    @Default(0) int age,
    @Default([]) List<String> hobbies,
  }) = _ExampleModel;

  factory ExampleModel.fromJson(Map<String, dynamic> json) =>
      _$ExampleModelFromJson(json);

  @jsonSchema
  static String get schema => _$ExampleModelSchema;
}
```

### Example with `json_serializable`

Prefer `json_serializable`? SotiSchema has you covered:

```dart
import 'package:json_annotation/json_annotation.dart';
import 'package:soti_schema_plus/annotations.dart';

part 'example_model.g.dart';

@SotiSchema()
@JsonSerializable()
class ExampleModel {
  final String name;
  final int age;
  final List<String> hobbies;

  ExampleModel({
    this.name = '',
    this.age = 0,
    this.hobbies = const [],
  });

  factory ExampleModel.fromJson(Map<String, dynamic> json) =>
      _$ExampleModelFromJson(json);

  Map<String, dynamic> toJson() => _$ExampleModelToJson(this);

  @jsonSchema
  static String get schema => _$ExampleModelSchema;

  @jsonSchema
  static Map<String, dynamic> get schemaMap => _$ExampleModelSchemaMap;
}
```

### Adding Descriptions to Your Schema

When generating schemas with SotiSchema, you can include descriptions for your
fields in two ways:

1. **Doc Comments**: Use regular Dart doc comments (`///`) above your class
   fields. SotiSchema will automatically extract these comments and include them
   as descriptions in the generated schema.

2. **`@Description` Annotation**: If you prefer more control or want to add
   descriptions that differ from your doc comments, you can use the
   `@Description` annotation. This approach allows you to provide explicit
   descriptions directly.

#### Example with Doc Comments

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:soti_schema_plus/annotations.dart';

part 'example_model.freezed.dart';
part 'example_model.g.dart';

@freezed
@SotiSchema()
class ExampleModel with _$ExampleModel {
  const ExampleModel._();
  const factory ExampleModel({
    /// The name of the person.
    @Default('') String name,

    /// The age of the person in years.
    @Default(0) int age,

    /// A list of hobbies the person enjoys.
    @Default([]) List<String> hobbies,
  }) = _ExampleModel;

  factory ExampleModel.fromJson(Map<String, dynamic> json) =>
      _$ExampleModelFromJson(json);

  @jsonSchema
  static String get schema => _$ExampleModelSchema;
}
```

In this example, the doc comments will be used as descriptions in the generated
JSON schema.

#### Example with `@Description` Annotation

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:soti_schema_plus/annotations.dart';

part 'example_model.freezed.dart';
part 'example_model.g.dart';

@freezed
@SotiSchema()
class ExampleModel with _$ExampleModel {
  const ExampleModel._();
  const factory ExampleModel({
    @Description('The name of the person.')
    @Default('') String name,

    @Description('The age of the person in years.')
    @Default(0) int age,

    @Description('A list of hobbies the person enjoys.')
    @Default([]) List<String> hobbies,
  }) = _ExampleModel;

  factory ExampleModel.fromJson(Map<String, dynamic> json) =>
      _$ExampleModelFromJson(json);

  @jsonSchema
  static String get schema => _$ExampleModelSchema;
}
```

In this example, the `@Description` annotations will be used as descriptions in
the generated JSON schema.

### Flexible Schema Naming

With SotiSchema, you have the freedom to name your schema methods however you
like and choose between returning a `String` or `Map<String, dynamic>`.
SotiSchema adapts to your needs:

```dart
@jsonSchema
static String get customSchemaName => _$ExampleModelSchema;

@jsonSchema
static Map<String, dynamic> get anotherSchema => _$ExampleModelSchemaMap;
```

---

## 🎯 Complete Example

See the `example/` directory for a complete working example that demonstrates:

- Basic freezed models with schema generation
- JsonSerializable models with dual schema formats (String and Map)
- Models with documentation comments
- Complex nested objects with schema references
- Various data types including DateTime, Maps, and Lists

Run the example:

```bash
cd example
dart pub get
dart run build_runner build --delete-conflicting-outputs
dart run main.dart
```

---

## 📝 Generated Schema Format

SotiSchema generates JSON Schema draft 2020-12 compatible schemas. Here's an
example of what gets generated:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "name": {
      "type": "string",
      "description": "The name of the person.",
      "default": ""
    },
    "age": {
      "type": "integer",
      "description": "The age of the person in years.",
      "default": 0
    },
    "hobbies": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "description": "A list of hobbies the person enjoys.",
      "default": []
    }
  },
  "$defs": {}
}
```

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for
details.
