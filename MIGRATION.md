# SotiSchema → Spectra 功能差異對比

## 架構變化

### 舊版 (SotiSchema 1.x)
```
builder.dart (單一檔案 ~400 行)
├── SotiSchemaGenerator
├── JsonSchemaGenerator
├── TypeCheckers
└── PropertyInfo
```

### 新版 (Spectra 2.x)
```
lib/src/
├── annotations/          # 分離嘅 Annotations
│   ├── spectra_annotation.dart
│   ├── field.dart
│   ├── ignore.dart
│   ├── converter.dart
│   └── output.dart
├── spec/                 # TypeSpec IR (中間表示)
│   └── spec.dart
├── extractors/           # 提取器 (從 Dart 類型到 IR)
│   ├── freezed_extractor.dart
│   ├── json_serializable_extractor.dart
│   └── plain_dart_extractor.dart
├── emitters/             # 發射器 (從 IR 到輸出格式)
│   ├── json_schema_emitter.dart
│   ├── openapi_emitter.dart
│   └── protobuf_emitter.dart
└── generator/
    └── spectra_generator.dart
```

---

## 功能對比

| 功能 | SotiSchema 1.x | Spectra 2.x |
|------|----------------|-------------|
| **輸出格式** | JSON Schema only | JSON Schema, OpenAPI, Protobuf |
| **JSON Schema 版本** | Draft 2020-12 only | Draft-07, 2019-09, 2020-12 |
| **OpenAPI 版本** | ❌ | 3.0, 3.1 |
| **Nullable 支援** | ❌ 有 bug | ✅ `type: ["string", "null"]` |
| **Enum 支援** | ❌ 有 bug (`_handleEnum` 從未調用) | ✅ 完整支援 |
| **Union Types** | ❌ | ✅ Freezed sealed classes |
| **String 約束** | ❌ | ✅ minLength, maxLength, pattern, format |
| **Number 約束** | ❌ | ✅ min, max, exclusive, multipleOf |
| **Array 約束** | ❌ | ✅ minItems, maxItems, uniqueItems |
| **Description** | ✅ Doc comments + @Description | ✅ Doc comments + @Field |
| **Default Values** | ⚠️ 部分支援 | ✅ 完整支援 |
| **Deprecated** | ❌ | ✅ |
| **Examples** | ❌ | ✅ |
| **$ref 處理** | ❌ 有 bug (字串插值錯誤) | ✅ 正確處理 |
| **測試覆蓋率** | 0% | 94.2% |

---

## Bug 修復

### 1. `$ref` 字串插值錯誤 (Critical)

**舊版 Bug:**
```dart
// 舊版 - 錯誤
return {r'$ref': '#/\$defs/$typeName'};  // 輸出: "#/$defs/$typeName" (字面量)
```

**新版修復:**
```dart
// 新版 - 正確
return {r'$ref': '#/\$defs/${spec.typeName}'};  // 輸出: "#/$defs/User"
```

### 2. `_handleEnum` 從未調用

**舊版:**
```dart
// 定義咗 _handleEnum 方法但從未調用
Map<String, dynamic>? _handleEnum(DartType type) { ... }
```

**新版:**
```dart
// EnumSpec 係 TypeSpec 嘅一部分，自動處理
EnumSpec() => _emitEnum(spec)
```

### 3. Nullable 類型唔支援

**舊版:**
```dart
// 冇處理 nullable types
if (_typeCheckers.stringChecker.isExactlyType(type)) {
  return {'type': 'string'};  // String? 同 String 一樣
}
```

**新版:**
```dart
// 正確處理 nullable
if (spec.nullable && result.containsKey('type')) {
  final type = result['type'];
  if (type is String) {
    result['type'] = [type, 'null'];  // ["string", "null"]
  }
}
```

---

## Annotations 對比

### 舊版
```dart
@SotiSchema()
class User {
  @Description('User name')
  final String name;

  @DefaultValue('guest')
  final String role;

  @jsonSchema
  static String get schema => _$UserSchema;
}
```

### 新版
```dart
@Spectra(
  title: 'User',
  description: 'A user in the system',
  formats: {SpectraFormat.jsonSchema, SpectraFormat.openApi},
  additionalProperties: false,
)
class User {
  @Field(
    minLength: 1,
    maxLength: 100,
    description: 'User name',
  )
  final String name;

  @Field(
    format: StringFormat.email,
    examples: ['user@example.com'],
  )
  final String email;

  @Field(minimum: 0, maximum: 150)
  final int? age;

  @Ignore()
  final String internalField;

  @spectraOutput
  static String get jsonSchema => _$UserJsonSchema;
}
```

---

## 新增 String Formats

| Format | JSON Schema | 用途 |
|--------|-------------|------|
| `email` | `"format": "email"` | 電郵地址 |
| `uri` | `"format": "uri"` | URI |
| `uuid` | `"format": "uuid"` | UUID |
| `dateTime` | `"format": "date-time"` | ISO 8601 日期時間 |
| `date` | `"format": "date"` | ISO 8601 日期 |
| `time` | `"format": "time"` | ISO 8601 時間 |
| `ipv4` | `"format": "ipv4"` | IPv4 地址 |
| `ipv6` | `"format": "ipv6"` | IPv6 地址 |
| `hostname` | `"format": "hostname"` | 主機名 |
| `regex` | `"format": "regex"` | 正則表達式 |

---

## 新增輸出格式

### OpenAPI 3.1
```dart
@Spectra(formats: {SpectraFormat.openApi})
```

輸出:
```yaml
components:
  schemas:
    User:
      type: object
      properties:
        name:
          type: string
          minLength: 1
```

### Protocol Buffers
```dart
@Spectra(formats: {SpectraFormat.protobuf})
```

輸出:
```protobuf
syntax = "proto3";

message User {
  string name = 1;
  optional int64 age = 2;
}
```

---

## Union Types (新功能)

### Freezed Sealed Classes
```dart
@freezed
@Spectra()
sealed class Result with _$Result {
  const factory Result.success({required String data}) = Success;
  const factory Result.error({required String message}) = Error;
}
```

### 生成嘅 JSON Schema
```json
{
  "oneOf": [
    { "$ref": "#/$defs/Success" },
    { "$ref": "#/$defs/Error" }
  ],
  "discriminator": {
    "propertyName": "runtimeType"
  },
  "$defs": {
    "Success": {
      "type": "object",
      "properties": {
        "data": { "type": "string" }
      }
    },
    "Error": {
      "type": "object",
      "properties": {
        "message": { "type": "string" }
      }
    }
  }
}
```

---

## Migration 步驟

```diff
# pubspec.yaml
- soti_schema: ^1.0.0
+ spectra: ^2.0.0

# build.yaml
- soti_schema|soti_schema
+ spectra|spectra

# Dart files
- import 'package:soti_schema/soti_schema.dart';
+ import 'package:spectra/spectra.dart';

- @SotiSchema()
+ @Spectra()

- @Description('...')
+ @Field(description: '...')

- @jsonSchema
+ @spectraOutput
```

---

## 測試覆蓋率

| 組件 | 覆蓋率 |
|------|--------|
| emitter.dart | 100% |
| string_utils.dart | 100% |
| json_schema_emitter.dart | 98.3% |
| openapi_emitter.dart | 93.7% |
| protobuf_emitter.dart | 91.4% |
| spec.dart | 92.7% |
| **總計** | **94.2%** |

測試數量: **175 個**
