# Spectra - 完整重構計劃

## 📛 重新命名

**舊名**: `soti_schema` → **新名**: `spectra`

**理念**: Spec (規格) + Dart 諧音 + 光譜意象 (支援多種輸出格式)

---

## 🏗️ 新架構設計

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           SPECTRA ARCHITECTURE                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌──────────────┐    ┌──────────────┐    ┌────────────────────────┐    │
│  │  Annotations │───▶│  Extractors  │───▶│    Spec (IR Model)     │    │
│  │              │    │              │    │                        │    │
│  │ @Spectra     │    │ • Freezed    │    │ • TypeSpec (sealed)    │    │
│  │ @Field       │    │ • JsonSer... │    │ • ObjectSpec           │    │
│  │ @Ignore      │    │ • PlainDart  │    │ • ArraySpec            │    │
│  │ @Converter   │    │              │    │ • StringSpec           │    │
│  └──────────────┘    └──────────────┘    │ • NumberSpec           │    │
│                                          │ • EnumSpec             │    │
│                                          │ • UnionSpec            │    │
│                                          │ • RefSpec              │    │
│                                          └───────────┬────────────┘    │
│                                                      │                 │
│                    ┌─────────────────────────────────┼─────────────┐   │
│                    │                                 ▼             │   │
│                    │  ┌─────────────────────────────────────────┐  │   │
│                    │  │              Emitters                   │  │   │
│                    │  ├─────────────────────────────────────────┤  │   │
│                    │  │  • JsonSchemaEmitter  → JSON Schema     │  │   │
│                    │  │  • OpenApiEmitter     → OpenAPI 3.x     │  │   │
│                    │  │  • ProtobufEmitter    → .proto files    │  │   │
│                    │  │  • TypeScriptEmitter  → .d.ts (bonus)   │  │   │
│                    │  └─────────────────────────────────────────┘  │   │
│                    └───────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 📁 新檔案結構

```
lib/
├── spectra.dart                    # 主入口 (exports annotations)
├── src/
│   ├── annotations/
│   │   ├── annotations.dart        # 所有 annotation exports
│   │   ├── spectra.dart            # @Spectra class annotation
│   │   ├── field.dart              # @Field property annotation
│   │   ├── ignore.dart             # @Ignore annotation
│   │   └── converter.dart          # @Converter annotation
│   │
│   ├── spec/                       # Intermediate Representation
│   │   ├── spec.dart               # exports
│   │   ├── type_spec.dart          # sealed TypeSpec base
│   │   ├── primitive_spec.dart     # String, int, double, bool
│   │   ├── object_spec.dart        # Objects with properties
│   │   ├── array_spec.dart         # Arrays/Lists
│   │   ├── map_spec.dart           # Maps/Dictionaries
│   │   ├── enum_spec.dart          # Enumerations
│   │   ├── union_spec.dart         # Union/sealed types
│   │   ├── ref_spec.dart           # References to other specs
│   │   └── nullable_spec.dart      # Nullable wrapper
│   │
│   ├── extractors/                 # Extract metadata from Dart types
│   │   ├── extractors.dart         # exports
│   │   ├── extractor.dart          # Base Extractor interface
│   │   ├── freezed_extractor.dart  # Freezed class support
│   │   ├── json_serializable_extractor.dart
│   │   └── plain_dart_extractor.dart
│   │
│   ├── emitters/                   # Output format generators
│   │   ├── emitters.dart           # exports
│   │   ├── emitter.dart            # Base Emitter interface
│   │   ├── json_schema_emitter.dart
│   │   ├── openapi_emitter.dart
│   │   └── protobuf_emitter.dart
│   │
│   ├── generator/                  # Build system integration
│   │   ├── spectra_generator.dart  # Main generator
│   │   └── builder.dart            # Builder factory
│   │
│   └── utils/                      # Utilities
│       ├── type_checkers.dart      # Type checking helpers
│       └── string_utils.dart       # String manipulation
│
├── builder.dart                    # Builder entry point (for build.yaml)
│
test/
├── annotations/
│   └── annotations_test.dart
├── spec/
│   ├── type_spec_test.dart
│   └── spec_builder_test.dart
├── extractors/
│   ├── freezed_extractor_test.dart
│   └── json_serializable_extractor_test.dart
├── emitters/
│   ├── json_schema_emitter_test.dart
│   ├── openapi_emitter_test.dart
│   └── protobuf_emitter_test.dart
├── integration/
│   ├── freezed_integration_test.dart
│   └── json_serializable_integration_test.dart
└── fixtures/
    └── test_models.dart
```

---

## 📝 新 Annotations API

### @Spectra - 類級別註解

```dart
/// 標記類別進行 schema 生成
@Spectra(
  title: 'User',                    // Schema 標題
  description: 'A user account',    // Schema 描述
  formats: {SpectraFormat.jsonSchema, SpectraFormat.openApi},  // 輸出格式
  additionalProperties: false,      // 是否允許額外屬性
)
class User { ... }
```

### @Field - 屬性級別註解

```dart
@Field(
  // 基本
  name: 'user_name',               // 覆蓋 JSON key
  description: 'The username',     // 描述
  deprecated: true,                // 標記棄用
  examples: ['john_doe'],          // 範例值

  // String 約束
  minLength: 3,
  maxLength: 50,
  pattern: r'^[a-z0-9_]+$',
  format: StringFormat.email,

  // Number 約束
  minimum: 0,
  maximum: 150,
  exclusiveMinimum: true,
  multipleOf: 0.5,

  // Array 約束
  minItems: 1,
  maxItems: 100,
  uniqueItems: true,
)
```

### @Ignore - 忽略屬性

```dart
class User {
  final String name;

  @Ignore()  // 不會出現在 schema
  final String internalId;
}
```

### @Converter - 自定義轉換

```dart
class User {
  @Converter(DateTimeConverter())  // 自定義 schema 生成
  final DateTime createdAt;
}

class DateTimeConverter implements SpecConverter {
  const DateTimeConverter();

  @override
  TypeSpec toSpec(DartType type) {
    return StringSpec(format: StringFormat.dateTime);
  }
}
```

### @SpectraOutput - 輸出標記

```dart
class User {
  // ...

  @spectraOutput  // 標記此 getter 接收生成的 schema
  static String get jsonSchema => _$UserJsonSchema;

  @spectraOutput
  static Map<String, dynamic> get openApiSchema => _$UserOpenApiSchema;
}
```

---

## 🔧 Spec (Intermediate Representation)

```dart
/// 所有 Spec 類型的基類
sealed class TypeSpec {
  final String? description;
  final bool nullable;
  final List<String>? examples;
  final bool deprecated;

  const TypeSpec({
    this.description,
    this.nullable = false,
    this.examples,
    this.deprecated = false,
  });
}

/// 字串類型
final class StringSpec extends TypeSpec {
  final StringFormat? format;
  final String? pattern;
  final int? minLength;
  final int? maxLength;
  final String? defaultValue;

  const StringSpec({
    this.format,
    this.pattern,
    this.minLength,
    this.maxLength,
    this.defaultValue,
    super.description,
    super.nullable,
    super.examples,
    super.deprecated,
  });
}

/// 數字類型
final class NumberSpec extends TypeSpec {
  final bool isInteger;
  final num? minimum;
  final num? maximum;
  final bool exclusiveMinimum;
  final bool exclusiveMaximum;
  final num? multipleOf;
  final num? defaultValue;

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
    super.deprecated,
  });
}

/// 布林類型
final class BoolSpec extends TypeSpec {
  final bool? defaultValue;

  const BoolSpec({
    this.defaultValue,
    super.description,
    super.nullable,
    super.examples,
    super.deprecated,
  });
}

/// 物件類型
final class ObjectSpec extends TypeSpec {
  final String name;
  final Map<String, PropertySpec> properties;
  final List<String> required;
  final bool additionalProperties;

  const ObjectSpec({
    required this.name,
    required this.properties,
    this.required = const [],
    this.additionalProperties = false,
    super.description,
    super.nullable,
    super.examples,
    super.deprecated,
  });
}

/// 屬性規格
final class PropertySpec {
  final String name;
  final String? jsonName;  // JSON key (可能不同)
  final TypeSpec type;
  final bool required;

  const PropertySpec({
    required this.name,
    this.jsonName,
    required this.type,
    this.required = true,
  });
}

/// 陣列類型
final class ArraySpec extends TypeSpec {
  final TypeSpec items;
  final int? minItems;
  final int? maxItems;
  final bool uniqueItems;

  const ArraySpec({
    required this.items,
    this.minItems,
    this.maxItems,
    this.uniqueItems = false,
    super.description,
    super.nullable,
    super.examples,
    super.deprecated,
  });
}

/// Map 類型
final class MapSpec extends TypeSpec {
  final TypeSpec keyType;
  final TypeSpec valueType;

  const MapSpec({
    required this.keyType,
    required this.valueType,
    super.description,
    super.nullable,
    super.examples,
    super.deprecated,
  });
}

/// 枚舉類型
final class EnumSpec extends TypeSpec {
  final String name;
  final List<EnumValueSpec> values;

  const EnumSpec({
    required this.name,
    required this.values,
    super.description,
    super.nullable,
    super.examples,
    super.deprecated,
  });
}

final class EnumValueSpec {
  final String name;
  final String? jsonValue;  // JSON 中的值 (可能不同)
  final String? description;

  const EnumValueSpec({
    required this.name,
    this.jsonValue,
    this.description,
  });
}

/// Union 類型 (Freezed sealed classes)
final class UnionSpec extends TypeSpec {
  final String name;
  final String? discriminator;  // e.g., 'runtimeType'
  final List<ObjectSpec> variants;

  const UnionSpec({
    required this.name,
    this.discriminator,
    required this.variants,
    super.description,
    super.nullable,
    super.examples,
    super.deprecated,
  });
}

/// 引用類型
final class RefSpec extends TypeSpec {
  final String typeName;

  const RefSpec({
    required this.typeName,
    super.nullable,
  });
}
```

---

## 🔌 Emitter 介面

```dart
/// Emitter 基類
abstract class SpecEmitter<T> {
  /// 輸出格式名稱
  String get formatName;

  /// 將 TypeSpec 轉換為目標格式
  T emit(TypeSpec spec, {required SpecContext context});
}

/// 生成上下文
class SpecContext {
  /// 所有已定義的類型
  final Map<String, TypeSpec> definitions;

  /// 是否為根類型
  final bool isRoot;

  const SpecContext({
    required this.definitions,
    this.isRoot = false,
  });
}
```

### JSON Schema Emitter

```dart
class JsonSchemaEmitter extends SpecEmitter<Map<String, dynamic>> {
  final JsonSchemaVersion version;

  const JsonSchemaEmitter({
    this.version = JsonSchemaVersion.draft202012,
  });

  @override
  String get formatName => 'jsonSchema';

  @override
  Map<String, dynamic> emit(TypeSpec spec, {required SpecContext context}) {
    final schema = _emitType(spec, context);

    if (context.isRoot) {
      return {
        r'$schema': version.schemaUri,
        ...schema,
        if (context.definitions.isNotEmpty)
          r'$defs': {
            for (final entry in context.definitions.entries)
              entry.key: _emitType(entry.value, context.copyWith(isRoot: false)),
          },
      };
    }

    return schema;
  }

  Map<String, dynamic> _emitType(TypeSpec spec, SpecContext context) {
    return switch (spec) {
      StringSpec() => _emitString(spec),
      NumberSpec() => _emitNumber(spec),
      BoolSpec() => _emitBool(spec),
      ObjectSpec() => _emitObject(spec, context),
      ArraySpec() => _emitArray(spec, context),
      MapSpec() => _emitMap(spec, context),
      EnumSpec() => _emitEnum(spec),
      UnionSpec() => _emitUnion(spec, context),
      RefSpec() => _emitRef(spec),
    };
  }

  // ... 各類型實現
}

enum JsonSchemaVersion {
  draft202012('https://json-schema.org/draft/2020-12/schema'),
  draft201909('https://json-schema.org/draft/2019-09/schema'),
  draft07('http://json-schema.org/draft-07/schema#');

  final String schemaUri;
  const JsonSchemaVersion(this.schemaUri);
}
```

### OpenAPI Emitter

```dart
class OpenApiEmitter extends SpecEmitter<Map<String, dynamic>> {
  final OpenApiVersion version;

  const OpenApiEmitter({
    this.version = OpenApiVersion.v31,
  });

  @override
  String get formatName => 'openApi';

  @override
  Map<String, dynamic> emit(TypeSpec spec, {required SpecContext context}) {
    // OpenAPI 3.1 基本兼容 JSON Schema Draft 2020-12
    // OpenAPI 3.0 需要轉換某些屬性
    // ...
  }
}

enum OpenApiVersion {
  v30,  // OpenAPI 3.0.x
  v31,  // OpenAPI 3.1.x (JSON Schema compatible)
}
```

### Protobuf Emitter

```dart
class ProtobufEmitter extends SpecEmitter<String> {
  @override
  String get formatName => 'protobuf';

  @override
  String emit(TypeSpec spec, {required SpecContext context}) {
    // 生成 .proto 檔案內容
    final buffer = StringBuffer();
    buffer.writeln('syntax = "proto3";');
    buffer.writeln();
    // ...
    return buffer.toString();
  }
}
```

---

## 🔨 Generator 實現

```dart
class SpectraGenerator extends GeneratorForAnnotation<Spectra> {
  final extractors = <DataClassType, Extractor>{
    DataClassType.freezed: FreezedExtractor(),
    DataClassType.jsonSerializable: JsonSerializableExtractor(),
    DataClassType.plain: PlainDartExtractor(),
  };

  final emitters = <SpectraFormat, SpecEmitter>{
    SpectraFormat.jsonSchema: JsonSchemaEmitter(),
    SpectraFormat.openApi: OpenApiEmitter(),
    SpectraFormat.protobuf: ProtobufEmitter(),
  };

  @override
  FutureOr<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@Spectra can only be applied to classes.',
        element: element,
      );
    }

    // 1. 識別 data class 類型
    final dataClassType = _identifyDataClassType(element);

    // 2. 取得對應 extractor
    final extractor = extractors[dataClassType];
    if (extractor == null) {
      throw InvalidGenerationSourceError(
        'Unsupported class type. Use @freezed, @JsonSerializable, or plain Dart class.',
        element: element,
      );
    }

    // 3. 抽取 TypeSpec
    final spec = extractor.extract(element);

    // 4. 讀取輸出配置
    final formats = _getRequestedFormats(element, annotation);

    // 5. 生成各格式輸出
    final buffer = StringBuffer();
    for (final format in formats) {
      final emitter = emitters[format]!;
      final output = emitter.emit(spec, context: SpecContext(
        definitions: extractor.definitions,
        isRoot: true,
      ));

      _writeOutput(buffer, element.name, emitter.formatName, output);
    }

    return buffer.toString();
  }
}
```

---

## ✅ 測試策略

### Unit Tests

```dart
// test/spec/type_spec_test.dart
void main() {
  group('StringSpec', () {
    test('basic string', () {
      const spec = StringSpec();
      expect(spec.nullable, isFalse);
      expect(spec.format, isNull);
    });

    test('email format', () {
      const spec = StringSpec(format: StringFormat.email);
      expect(spec.format, StringFormat.email);
    });
  });
}

// test/emitters/json_schema_emitter_test.dart
void main() {
  late JsonSchemaEmitter emitter;

  setUp(() {
    emitter = const JsonSchemaEmitter();
  });

  group('StringSpec', () {
    test('basic string', () {
      const spec = StringSpec();
      final schema = emitter.emit(spec, context: emptyContext);

      expect(schema, {'type': 'string'});
    });

    test('string with constraints', () {
      const spec = StringSpec(
        minLength: 3,
        maxLength: 50,
        pattern: r'^[a-z]+$',
      );
      final schema = emitter.emit(spec, context: emptyContext);

      expect(schema, {
        'type': 'string',
        'minLength': 3,
        'maxLength': 50,
        'pattern': r'^[a-z]+$',
      });
    });

    test('nullable string', () {
      const spec = StringSpec(nullable: true);
      final schema = emitter.emit(spec, context: emptyContext);

      expect(schema, {
        'type': ['string', 'null'],
      });
    });
  });

  group('EnumSpec', () {
    test('string enum', () {
      const spec = EnumSpec(
        name: 'Status',
        values: [
          EnumValueSpec(name: 'active'),
          EnumValueSpec(name: 'inactive'),
        ],
      );
      final schema = emitter.emit(spec, context: emptyContext);

      expect(schema, {
        'type': 'string',
        'enum': ['active', 'inactive'],
      });
    });
  });

  group('UnionSpec', () {
    test('discriminated union', () {
      const spec = UnionSpec(
        name: 'Result',
        discriminator: 'type',
        variants: [
          ObjectSpec(name: 'Success', properties: {}, required: []),
          ObjectSpec(name: 'Error', properties: {}, required: []),
        ],
      );
      final schema = emitter.emit(spec, context: emptyContext);

      expect(schema['oneOf'], hasLength(2));
      expect(schema['discriminator'], {'propertyName': 'type'});
    });
  });
}
```

### Integration Tests

```dart
// test/integration/freezed_integration_test.dart
@Tags(['integration'])
void main() {
  group('Freezed integration', () {
    test('simple freezed class', () async {
      // 使用 build_runner_core 進行實際生成測試
    });

    test('freezed union types', () async {
      // 測試 sealed class 支援
    });
  });
}
```

---

## 📋 實施步驟

### Phase 1: 基礎重構 (Core)
1. [ ] 重命名 package 為 `spectra`
2. [ ] 建立新檔案結構
3. [ ] 實現 TypeSpec IR 模型
4. [ ] 實現新 Annotations

### Phase 2: Extractors
5. [ ] 實現 FreezedExtractor
6. [ ] 實現 JsonSerializableExtractor
7. [ ] 實現 PlainDartExtractor
8. [ ] 支援 Union types

### Phase 3: Emitters
9. [ ] 實現 JsonSchemaEmitter (修復所有 bugs)
10. [ ] 實現 OpenApiEmitter
11. [ ] 實現 ProtobufEmitter

### Phase 4: Generator
12. [ ] 實現新 SpectraGenerator
13. [ ] 更新 build.yaml
14. [ ] 整合測試

### Phase 5: 文檔與發佈
15. [ ] 更新 README.md
16. [ ] 更新 CHANGELOG.md
17. [ ] 更新 pubspec.yaml
18. [ ] 發佈 2.0.0

---

## 📦 pubspec.yaml (新)

```yaml
name: spectra
description: >-
  A powerful Dart code generator that transforms your data classes into
  JSON Schema, OpenAPI, and Protobuf specifications. Perfect for AI integrations
  and API documentation.
version: 2.0.0
homepage: https://github.com/shtse8/spectra
repository: https://github.com/shtse8/spectra

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  analyzer: ^6.4.1
  build: ^2.4.1
  source_gen: ^1.5.0
  meta: ^1.15.0
  json_annotation: ^4.9.0
  collection: ^1.18.0
  freezed_annotation: ^2.4.4

dev_dependencies:
  lints: ^4.0.0
  test: ^1.24.0
  build_runner: ^2.4.6
  build_test: ^2.2.0
```

---

## 🎯 預期效果

### 使用範例

```dart
import 'package:spectra/spectra.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
@Spectra(
  title: 'User',
  description: 'A user in the system',
)
class User with _$User {
  const factory User({
    @Field(
      description: 'Unique identifier',
      format: StringFormat.uuid,
    )
    required String id,

    @Field(
      description: 'User email address',
      format: StringFormat.email,
    )
    required String email,

    @Field(
      description: 'User age',
      minimum: 0,
      maximum: 150,
    )
    @Default(0) int age,

    @Field(
      description: 'User roles',
      minItems: 1,
    )
    @Default([]) List<Role> roles,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  @spectraOutput
  static String get jsonSchema => _$UserJsonSchema;

  @spectraOutput
  static Map<String, dynamic> get openApiSchema => _$UserOpenApiSchema;
}

@Spectra()
enum Role {
  @Field(description: 'Administrator with full access')
  admin,

  @Field(description: 'Regular user')
  user,

  @Field(description: 'Read-only guest')
  guest,
}
```

### 生成輸出

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "User",
  "description": "A user in the system",
  "type": "object",
  "properties": {
    "id": {
      "type": "string",
      "format": "uuid",
      "description": "Unique identifier"
    },
    "email": {
      "type": "string",
      "format": "email",
      "description": "User email address"
    },
    "age": {
      "type": "integer",
      "description": "User age",
      "minimum": 0,
      "maximum": 150,
      "default": 0
    },
    "roles": {
      "type": "array",
      "description": "User roles",
      "minItems": 1,
      "items": {
        "$ref": "#/$defs/Role"
      },
      "default": []
    }
  },
  "required": ["id", "email"],
  "$defs": {
    "Role": {
      "type": "string",
      "enum": ["admin", "user", "guest"]
    }
  }
}
```
