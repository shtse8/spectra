import 'package:spectra/src/emitters/emitter.dart';
import 'package:spectra/src/emitters/openapi_emitter.dart';
import 'package:spectra/src/spec/spec.dart';
import 'package:test/test.dart';

void main() {
  late OpenApiEmitter emitter30;
  late OpenApiEmitter emitter31;
  late EmitContext emptyContext;

  setUp(() {
    emitter30 = OpenApiEmitter(version: OpenApiVersion.v30);
    emitter31 = OpenApiEmitter(version: OpenApiVersion.v31);
    emptyContext = const EmitContext(definitions: {}, isRoot: false);
  });

  group('StringSpec', () {
    test('basic string', () {
      const spec = StringSpec();
      final schema = emitter31.emit(spec, context: emptyContext);

      expect(schema['type'], 'string');
    });

    test('string with format', () {
      const spec = StringSpec(format: StringFormat.uuid);
      final schema = emitter31.emit(spec, context: emptyContext);

      expect(schema['type'], 'string');
      expect(schema['format'], 'uuid');
    });

    test('string with constraints', () {
      const spec = StringSpec(
        minLength: 5,
        maxLength: 100,
        pattern: r'^\w+$',
      );
      final schema = emitter31.emit(spec, context: emptyContext);

      expect(schema['minLength'], 5);
      expect(schema['maxLength'], 100);
      expect(schema['pattern'], r'^\w+$');
    });
  });

  group('Nullable handling', () {
    test('OpenAPI 3.0 uses nullable property', () {
      const spec = StringSpec(nullable: true);
      final schema = emitter30.emit(spec, context: emptyContext);

      expect(schema['type'], 'string');
      expect(schema['nullable'], true);
    });

    test('OpenAPI 3.1 uses JSON Schema style', () {
      const spec = StringSpec(nullable: true);
      final schema = emitter31.emit(spec, context: emptyContext);

      expect(schema['type'], ['string', 'null']);
      expect(schema['nullable'], isNull);
    });
  });

  group('NumberSpec', () {
    test('integer', () {
      const spec = NumberSpec.integer();
      final schema = emitter31.emit(spec, context: emptyContext);

      expect(schema['type'], 'integer');
    });

    test('number', () {
      const spec = NumberSpec.double();
      final schema = emitter31.emit(spec, context: emptyContext);

      expect(schema['type'], 'number');
    });

    test('OpenAPI 3.0 exclusiveMinimum as boolean', () {
      const spec = NumberSpec(
        minimum: 0,
        exclusiveMinimum: true,
      );
      final schema = emitter30.emit(spec, context: emptyContext);

      expect(schema['minimum'], 0);
      expect(schema['exclusiveMinimum'], true);
    });

    test('OpenAPI 3.1 exclusiveMinimum as value', () {
      const spec = NumberSpec(
        minimum: 0,
        exclusiveMinimum: true,
      );
      final schema = emitter31.emit(spec, context: emptyContext);

      expect(schema['exclusiveMinimum'], 0);
      expect(schema['minimum'], isNull);
    });
  });

  group('ObjectSpec', () {
    test('basic', () {
      const spec = ObjectSpec(name: 'User', properties: {});
      final schema = emitter31.emit(spec, context: emptyContext);

      expect(schema['type'], 'object');
    });

    test('with title', () {
      const spec = ObjectSpec(
        name: 'User',
        title: 'User Object',
        properties: {},
      );
      final schema = emitter31.emit(spec, context: emptyContext);

      expect(schema['title'], 'User Object');
    });

    test('with additionalProperties false', () {
      const spec = ObjectSpec(
        name: 'User',
        properties: {},
        additionalProperties: false,
      );
      final schema = emitter31.emit(spec, context: emptyContext);

      expect(schema['additionalProperties'], false);
    });
  });

  group('ArraySpec', () {
    test('basic', () {
      const spec = ArraySpec(items: StringSpec());
      final schema = emitter31.emit(spec, context: emptyContext);

      expect(schema['type'], 'array');
      expect(schema['items']['type'], 'string');
    });

    test('with constraints', () {
      const spec = ArraySpec(
        items: NumberSpec.integer(),
        minItems: 1,
        maxItems: 100,
        uniqueItems: true,
      );
      final schema = emitter31.emit(spec, context: emptyContext);

      expect(schema['minItems'], 1);
      expect(schema['maxItems'], 100);
      expect(schema['uniqueItems'], true);
    });
  });

  group('EnumSpec', () {
    test('string enum', () {
      const spec = EnumSpec(
        name: 'Color',
        values: [
          EnumValueSpec(name: 'red'),
          EnumValueSpec(name: 'green'),
          EnumValueSpec(name: 'blue'),
        ],
      );
      final schema = emitter31.emit(spec, context: emptyContext);

      expect(schema['type'], 'string');
      expect(schema['enum'], ['red', 'green', 'blue']);
    });

    test('enum with custom json values', () {
      const spec = EnumSpec(
        name: 'Status',
        values: [
          EnumValueSpec(name: 'active', jsonValue: 'ACTIVE'),
          EnumValueSpec(name: 'inactive', jsonValue: 'INACTIVE'),
        ],
      );
      final schema = emitter31.emit(spec, context: emptyContext);

      expect(schema['enum'], ['ACTIVE', 'INACTIVE']);
    });
  });

  group('UnionSpec', () {
    test('discriminated union', () {
      const spec = UnionSpec(
        name: 'Result',
        discriminator: 'type',
        variants: [
          ObjectSpec(name: 'Success', properties: {}),
          ObjectSpec(name: 'Failure', properties: {}),
        ],
      );
      final schema = emitter31.emit(spec, context: emptyContext);

      expect(schema['oneOf'], hasLength(2));
      expect(schema['discriminator'], {'propertyName': 'type'});
    });
  });

  group('RefSpec', () {
    test('uses OpenAPI component path', () {
      const spec = RefSpec(typeName: 'User');
      final schema = emitter31.emit(spec, context: emptyContext);

      expect(schema[r'$ref'], contains('components/schemas'));
    });
  });

  group('MapSpec', () {
    test('emits as object with additionalProperties', () {
      const spec = MapSpec(keyType: StringSpec(), valueType: StringSpec());
      final schema = emitter31.emit(spec, context: emptyContext);

      expect(schema['type'], 'object');
      expect(schema['additionalProperties']['type'], 'string');
    });
  });

  group('Examples', () {
    test('OpenAPI 3.0 uses singular example', () {
      const spec = StringSpec(examples: ['test@example.com', 'user@test.com']);
      final schema = emitter30.emit(spec, context: emptyContext);

      expect(schema['example'], 'test@example.com');
      expect(schema['examples'], isNull);
    });

    test('OpenAPI 3.1 uses plural examples', () {
      const spec = StringSpec(examples: ['test@example.com', 'user@test.com']);
      final schema = emitter31.emit(spec, context: emptyContext);

      expect(schema['examples'], ['test@example.com', 'user@test.com']);
      expect(schema['example'], isNull);
    });
  });

  group('Deprecated', () {
    test('includes deprecated flag', () {
      const spec = StringSpec(isDeprecated: true);
      final schema = emitter31.emit(spec, context: emptyContext);

      expect(schema['deprecated'], true);
    });
  });

  group('Root schema with definitions', () {
    test('includes components/schemas', () {
      const roleSpec = EnumSpec(
        name: 'Role',
        values: [EnumValueSpec(name: 'admin')],
      );
      const spec = ObjectSpec(name: 'User', properties: {});
      final context = EmitContext(
        definitions: {'Role': roleSpec},
        isRoot: true,
      );
      final schema = emitter31.emit(spec, context: context);

      expect(schema['components'], isNotNull);
      expect(schema['components']['schemas'], isNotNull);
      expect(schema['components']['schemas']['Role'], isNotNull);
    });
  });
}
