import 'package:spectra/src/spec/spec.dart';
import 'package:test/test.dart';

void main() {
  group('StringSpec', () {
    test('basic string', () {
      const spec = StringSpec();
      expect(spec.nullable, isFalse);
      expect(spec.format, isNull);
      expect(spec.isDeprecated, isFalse);
    });

    test('email format', () {
      const spec = StringSpec(format: StringFormat.email);
      expect(spec.format, StringFormat.email);
    });

    test('with constraints', () {
      const spec = StringSpec(
        minLength: 3,
        maxLength: 50,
        pattern: r'^[a-z]+$',
      );
      expect(spec.minLength, 3);
      expect(spec.maxLength, 50);
      expect(spec.pattern, r'^[a-z]+$');
    });

    test('asNullable', () {
      const spec = StringSpec(format: StringFormat.email);
      final nullable = spec.asNullable();
      expect(nullable.nullable, isTrue);
      expect(nullable.format, StringFormat.email);
    });

    test('withDescription', () {
      const spec = StringSpec();
      final withDesc = spec.withDescription('A test string');
      expect(withDesc.description, 'A test string');
    });
  });

  group('NumberSpec', () {
    test('integer', () {
      const spec = NumberSpec.integer();
      expect(spec.isInteger, isTrue);
    });

    test('double', () {
      const spec = NumberSpec.double();
      expect(spec.isInteger, isFalse);
    });

    test('with constraints', () {
      const spec = NumberSpec(
        minimum: 0,
        maximum: 100,
        exclusiveMinimum: true,
      );
      expect(spec.minimum, 0);
      expect(spec.maximum, 100);
      expect(spec.exclusiveMinimum, isTrue);
      expect(spec.exclusiveMaximum, isFalse);
    });
  });

  group('BoolSpec', () {
    test('basic', () {
      const spec = BoolSpec();
      expect(spec.defaultValue, isNull);
    });

    test('with default', () {
      const spec = BoolSpec(defaultValue: true);
      expect(spec.defaultValue, isTrue);
    });
  });

  group('ObjectSpec', () {
    test('basic', () {
      const spec = ObjectSpec(
        name: 'User',
        properties: {},
      );
      expect(spec.name, 'User');
      expect(spec.properties, isEmpty);
      expect(spec.required, isEmpty);
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
            required: false,
          ),
        },
        required: ['name'],
      );
      expect(spec.properties, hasLength(2));
      expect(spec.required, ['name']);
    });
  });

  group('ArraySpec', () {
    test('basic', () {
      const spec = ArraySpec(items: StringSpec());
      expect(spec.items, isA<StringSpec>());
      expect(spec.uniqueItems, isFalse);
    });

    test('with constraints', () {
      const spec = ArraySpec(
        items: NumberSpec.integer(),
        minItems: 1,
        maxItems: 10,
        uniqueItems: true,
      );
      expect(spec.minItems, 1);
      expect(spec.maxItems, 10);
      expect(spec.uniqueItems, isTrue);
    });
  });

  group('EnumSpec', () {
    test('basic', () {
      const spec = EnumSpec(
        name: 'Status',
        values: [
          EnumValueSpec(name: 'active'),
          EnumValueSpec(name: 'inactive'),
        ],
      );
      expect(spec.name, 'Status');
      expect(spec.values, hasLength(2));
      expect(spec.values[0].effectiveValue, 'active');
    });

    test('with json values', () {
      const spec = EnumSpec(
        name: 'Status',
        values: [
          EnumValueSpec(name: 'active', jsonValue: 'ACTIVE'),
          EnumValueSpec(name: 'inactive', jsonValue: 'INACTIVE'),
        ],
      );
      expect(spec.values[0].effectiveValue, 'ACTIVE');
      expect(spec.values[1].effectiveValue, 'INACTIVE');
    });
  });

  group('UnionSpec', () {
    test('basic', () {
      const spec = UnionSpec(
        name: 'Result',
        discriminator: 'type',
        variants: [
          ObjectSpec(name: 'Success', properties: {}),
          ObjectSpec(name: 'Error', properties: {}),
        ],
      );
      expect(spec.name, 'Result');
      expect(spec.discriminator, 'type');
      expect(spec.variants, hasLength(2));
    });
  });

  group('RefSpec', () {
    test('basic', () {
      const spec = RefSpec(typeName: 'User');
      expect(spec.typeName, 'User');
    });
  });

  group('PropertySpec', () {
    test('effectiveName without jsonName', () {
      const spec = PropertySpec(
        name: 'userName',
        type: StringSpec(),
      );
      expect(spec.effectiveName, 'userName');
    });

    test('effectiveName with jsonName', () {
      const spec = PropertySpec(
        name: 'userName',
        jsonName: 'user_name',
        type: StringSpec(),
      );
      expect(spec.effectiveName, 'user_name');
    });
  });
}
