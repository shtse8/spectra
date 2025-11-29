import '../spec/spec.dart';
import 'emitter.dart';

/// JSON Schema version.
enum JsonSchemaVersion {
  /// Draft 2020-12
  draft202012('https://json-schema.org/draft/2020-12/schema'),

  /// Draft 2019-09
  draft201909('https://json-schema.org/draft/2019-09/schema'),

  /// Draft-07
  draft07('http://json-schema.org/draft-07/schema#');

  /// The schema URI for this version.
  final String schemaUri;

  const JsonSchemaVersion(this.schemaUri);
}

/// Emits JSON Schema from TypeSpec.
class JsonSchemaEmitter extends SpecEmitter<Map<String, dynamic>> {
  /// The JSON Schema version to generate.
  final JsonSchemaVersion version;

  /// Creates a new [JsonSchemaEmitter].
  JsonSchemaEmitter({
    this.version = JsonSchemaVersion.draft202012,
  });

  @override
  String get formatName => 'JsonSchema';

  @override
  Map<String, dynamic> emit(TypeSpec spec, {required EmitContext context}) {
    final schema = _emitType(spec, context);

    if (context.isRoot) {
      final result = <String, dynamic>{
        r'$schema': version.schemaUri,
        ...schema,
      };

      // Add $defs if there are definitions
      if (context.definitions.isNotEmpty) {
        result[r'$defs'] = {
          for (final entry in context.definitions.entries)
            entry.key: _emitType(entry.value, context.asNonRoot()),
        };
      }

      return result;
    }

    return schema;
  }

  Map<String, dynamic> _emitType(TypeSpec spec, EmitContext context) {
    final result = switch (spec) {
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

    // Add common properties
    if (spec.description != null) {
      result['description'] = spec.description;
    }
    if (spec.isDeprecated) {
      result['deprecated'] = true;
    }
    if (spec.examples != null && spec.examples!.isNotEmpty) {
      result['examples'] = spec.examples;
    }

    // Handle nullable
    if (spec.nullable && result.containsKey('type')) {
      final type = result['type'];
      if (type is String) {
        result['type'] = [type, 'null'];
      } else if (type is List && !type.contains('null')) {
        result['type'] = [...type, 'null'];
      }
    }

    return result;
  }

  Map<String, dynamic> _emitString(StringSpec spec) {
    final result = <String, dynamic>{'type': 'string'};

    if (spec.format != null) {
      result['format'] = _formatToString(spec.format!);
    }
    if (spec.pattern != null) {
      result['pattern'] = spec.pattern;
    }
    if (spec.minLength != null) {
      result['minLength'] = spec.minLength;
    }
    if (spec.maxLength != null) {
      result['maxLength'] = spec.maxLength;
    }
    if (spec.defaultValue != null) {
      result['default'] = spec.defaultValue;
    }

    return result;
  }

  Map<String, dynamic> _emitNumber(NumberSpec spec) {
    final result = <String, dynamic>{
      'type': spec.isInteger ? 'integer' : 'number',
    };

    if (spec.minimum != null) {
      if (spec.exclusiveMinimum) {
        result['exclusiveMinimum'] = spec.minimum;
      } else {
        result['minimum'] = spec.minimum;
      }
    }
    if (spec.maximum != null) {
      if (spec.exclusiveMaximum) {
        result['exclusiveMaximum'] = spec.maximum;
      } else {
        result['maximum'] = spec.maximum;
      }
    }
    if (spec.multipleOf != null) {
      result['multipleOf'] = spec.multipleOf;
    }
    if (spec.defaultValue != null) {
      result['default'] = spec.defaultValue;
    }

    return result;
  }

  Map<String, dynamic> _emitBool(BoolSpec spec) {
    final result = <String, dynamic>{'type': 'boolean'};

    if (spec.defaultValue != null) {
      result['default'] = spec.defaultValue;
    }

    return result;
  }

  Map<String, dynamic> _emitObject(ObjectSpec spec, EmitContext context) {
    final result = <String, dynamic>{'type': 'object'};

    if (spec.title != null) {
      result['title'] = spec.title;
    }

    if (spec.properties.isNotEmpty) {
      result['properties'] = {
        for (final entry in spec.properties.entries)
          entry.value.effectiveName:
              _emitType(entry.value.type, context.asNonRoot()),
      };
    }

    if (spec.required.isNotEmpty) {
      result['required'] = spec.required;
    }

    if (!spec.additionalProperties) {
      result['additionalProperties'] = false;
    }

    return result;
  }

  Map<String, dynamic> _emitArray(ArraySpec spec, EmitContext context) {
    final result = <String, dynamic>{
      'type': 'array',
      'items': _emitType(spec.items, context.asNonRoot()),
    };

    if (spec.minItems != null) {
      result['minItems'] = spec.minItems;
    }
    if (spec.maxItems != null) {
      result['maxItems'] = spec.maxItems;
    }
    if (spec.uniqueItems) {
      result['uniqueItems'] = true;
    }
    if (spec.defaultValue != null) {
      result['default'] = spec.defaultValue;
    }

    return result;
  }

  Map<String, dynamic> _emitMap(MapSpec spec, EmitContext context) {
    return {
      'type': 'object',
      'additionalProperties': _emitType(spec.valueType, context.asNonRoot()),
    };
  }

  Map<String, dynamic> _emitEnum(EnumSpec spec) {
    return {
      'type': 'string',
      'enum': spec.values.map((v) => v.effectiveValue).toList(),
    };
  }

  Map<String, dynamic> _emitUnion(UnionSpec spec, EmitContext context) {
    final result = <String, dynamic>{
      'oneOf':
          spec.variants.map((v) => _emitType(v, context.asNonRoot())).toList(),
    };

    if (spec.discriminator != null) {
      result['discriminator'] = {
        'propertyName': spec.discriminator,
      };
    }

    return result;
  }

  Map<String, dynamic> _emitRef(RefSpec spec) {
    return {
      r'$ref': '#/\$defs/${spec.typeName}',
    };
  }

  String _formatToString(StringFormat format) {
    return switch (format) {
      StringFormat.email => 'email',
      StringFormat.uri => 'uri',
      StringFormat.uriReference => 'uri-reference',
      StringFormat.uuid => 'uuid',
      StringFormat.dateTime => 'date-time',
      StringFormat.date => 'date',
      StringFormat.time => 'time',
      StringFormat.duration => 'duration',
      StringFormat.ipv4 => 'ipv4',
      StringFormat.ipv6 => 'ipv6',
      StringFormat.hostname => 'hostname',
      StringFormat.jsonPointer => 'json-pointer',
      StringFormat.relativeJsonPointer => 'relative-json-pointer',
      StringFormat.regex => 'regex',
    };
  }
}
