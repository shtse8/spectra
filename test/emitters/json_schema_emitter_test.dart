import 'package:spectra/src/emitters/emitter.dart';
import 'package:spectra/src/emitters/json_schema_emitter.dart';
import 'package:spectra/src/spec/spec.dart';
import 'package:test/test.dart';

void main() {
  late JsonSchemaEmitter emitter;
  late EmitContext emptyContext;

  setUp(() {
    emitter = JsonSchemaEmitter();
    emptyContext = const EmitContext(definitions: {}, isRoot: false);
  });

  group('StringSpec', () {
    test('basic string', () {
      const spec = StringSpec();
      final schema = emitter.emit(spec, context: emptyContext);

      expect(schema['type'], 'string');
    });

    test('string with format', () {
      const spec = StringSpec(format: StringFormat.email);
      final schema = emitter.emit(spec, context: emptyContext);

      expect(schema['type'], 'string');
      expect(schema['format'], 'email');
    });

    test('string with constraints', () {
      const spec = StringSpec(
        minLength: 3,
        maxLength: 50,
        pattern: r'^[a-z]+$',
      );
      final schema = emitter.emit(spec, context: emptyContext);

      expect(schema['type'], 'string');
      expect(schema['minLength'], 3);
      expect(schema['maxLength'], 50);
      expect(schema['pattern'], r'^[a-z]+$');
    });

    test('nullable string', () {
      const spec = StringSpec(nullable: true);
      final schema = emitter.emit(spec, context: emptyContext);

      expect(schema['type'], ['string', 'null']);
    });

    test('string with description', () {
      const spec = StringSpec(description: 'A test string');
      final schema = emitter.emit(spec, context: emptyContext);

      expect(schema['description'], 'A test string');
    });
  });

  group('NumberSpec', () {
    test('integer', () {
      const spec = NumberSpec.integer();
      final schema = emitter.emit(spec, context: emptyContext);

      expect(schema['type'], 'integer');
    });

    test('number', () {
      const spec = NumberSpec.double();
      final schema = emitter.emit(spec, context: emptyContext);

      expect(schema['type'], 'number');
    });

    test('with constraints', () {
      const spec = NumberSpec(
        minimum: 0,
        maximum: 100,
        exclusiveMinimum: true,
      );
      final schema = emitter.emit(spec, context: emptyContext);

      expect(schema['exclusiveMinimum'], 0);
      expect(schema['maximum'], 100);
    });
  });

  group('BoolSpec', () {
    test('basic', () {
      const spec = BoolSpec();
      final schema = emitter.emit(spec, context: emptyContext);

      expect(schema['type'], 'boolean');
    });

    test('with default', () {
      const spec = BoolSpec(defaultValue: true);
      final schema = emitter.emit(spec, context: emptyContext);

      expect(schema['default'], true);
    });
  });

  group('ObjectSpec', () {
    test('basic', () {
      const spec = ObjectSpec(
        name: 'User',
        properties: {},
      );
      final schema = emitter.emit(spec, context: emptyContext);

      expect(schema['type'], 'object');
    });

    test('with properties', () {
      const spec = ObjectSpec(
        name: 'User',
        properties: {
          'name': PropertySpec(
            name: 'name',
            type: StringSpec(),
          ),
          'age': PropertySpec(
            name: 'age',
            type: NumberSpec.integer(),
          ),
        },
        required: ['name'],
      );
      final schema = emitter.emit(spec, context: emptyContext);

      expect(schema['type'], 'object');
      expect(schema['properties'], isNotNull);
      expect(schema['properties']['name']['type'], 'string');
      expect(schema['properties']['age']['type'], 'integer');
      expect(schema['required'], ['name']);
    });
  });

  group('ArraySpec', () {
    test('basic', () {
      const spec = ArraySpec(items: StringSpec());
      final schema = emitter.emit(spec, context: emptyContext);

      expect(schema['type'], 'array');
      expect(schema['items']['type'], 'string');
    });

    test('with constraints', () {
      const spec = ArraySpec(
        items: NumberSpec.integer(),
        minItems: 1,
        maxItems: 10,
        uniqueItems: true,
      );
      final schema = emitter.emit(spec, context: emptyContext);

      expect(schema['minItems'], 1);
      expect(schema['maxItems'], 10);
      expect(schema['uniqueItems'], true);
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

      expect(schema['type'], 'string');
      expect(schema['enum'], ['active', 'inactive']);
    });
  });

  group('UnionSpec', () {
    test('discriminated union', () {
      const spec = UnionSpec(
        name: 'Result',
        discriminator: 'type',
        variants: [
          ObjectSpec(name: 'Success', properties: {}),
          ObjectSpec(name: 'Error', properties: {}),
        ],
      );
      final schema = emitter.emit(spec, context: emptyContext);

      expect(schema['oneOf'], hasLength(2));
      expect(schema['discriminator'], {'propertyName': 'type'});
    });
  });

  group('Root schema', () {
    test('includes \$schema', () {
      const spec = ObjectSpec(name: 'User', properties: {});
      final context = const EmitContext(definitions: {}, isRoot: true);
      final schema = emitter.emit(spec, context: context);

      expect(schema[r'$schema'], contains('json-schema.org'));
    });

    test('includes \$defs when definitions present', () {
      const roleSpec = EnumSpec(
        name: 'Role',
        values: [EnumValueSpec(name: 'admin')],
      );
      const spec = ObjectSpec(name: 'User', properties: {});
      final context = EmitContext(
        definitions: {'Role': roleSpec},
        isRoot: true,
      );
      final schema = emitter.emit(spec, context: context);

      expect(schema[r'$defs'], isNotNull);
      expect(schema[r'$defs']['Role'], isNotNull);
    });
  });
}
