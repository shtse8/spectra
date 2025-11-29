import 'package:spectra_schema/src/spec/spec.dart';
import 'package:test/test.dart';

void main() {
  group('StringSpec', () {
    test('basic string', () {
      const spec = StringSpec();
      expect(spec.nullable, isFalse);
      expect(spec.format, isNull);
      expect(spec.isDeprecated, isFalse);
      expect(spec.description, isNull);
      expect(spec.examples, isNull);
      expect(spec.pattern, isNull);
      expect(spec.minLength, isNull);
      expect(spec.maxLength, isNull);
      expect(spec.defaultValue, isNull);
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

    test('copyWith', () {
      const spec = StringSpec(format: StringFormat.email);
      final copied = spec.copyWith(minLength: 5, maxLength: 100);
      expect(copied.format, StringFormat.email);
      expect(copied.minLength, 5);
      expect(copied.maxLength, 100);
    });

    test('with all properties', () {
      const spec = StringSpec(
        format: StringFormat.uri,
        pattern: r'^https://',
        minLength: 10,
        maxLength: 200,
        defaultValue: 'https://example.com',
        description: 'A URL',
        nullable: true,
        examples: ['https://example.com'],
        isDeprecated: true,
      );
      expect(spec.format, StringFormat.uri);
      expect(spec.pattern, r'^https://');
      expect(spec.minLength, 10);
      expect(spec.maxLength, 200);
      expect(spec.defaultValue, 'https://example.com');
      expect(spec.description, 'A URL');
      expect(spec.nullable, isTrue);
      expect(spec.examples, ['https://example.com']);
      expect(spec.isDeprecated, isTrue);
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

    test('asNullable', () {
      const spec = NumberSpec.integer();
      final nullable = spec.asNullable();
      expect(nullable.nullable, isTrue);
      expect(nullable.isInteger, isTrue);
    });

    test('withDescription', () {
      const spec = NumberSpec.integer();
      final withDesc = spec.withDescription('An age');
      expect(withDesc.description, 'An age');
      expect(withDesc.isInteger, isTrue);
    });

    test('copyWith', () {
      const spec = NumberSpec.integer(minimum: 0);
      final copied = spec.copyWith(maximum: 100, exclusiveMaximum: true);
      expect(copied.isInteger, isTrue);
      expect(copied.minimum, 0);
      expect(copied.maximum, 100);
      expect(copied.exclusiveMaximum, isTrue);
    });

    test('integer with all options', () {
      const spec = NumberSpec.integer(
        minimum: 0,
        maximum: 100,
        exclusiveMinimum: true,
        exclusiveMaximum: true,
        multipleOf: 5,
        defaultValue: 50,
        description: 'Score',
        nullable: true,
        examples: [10, 20, 30],
        isDeprecated: true,
      );
      expect(spec.isInteger, isTrue);
      expect(spec.minimum, 0);
      expect(spec.maximum, 100);
      expect(spec.exclusiveMinimum, isTrue);
      expect(spec.exclusiveMaximum, isTrue);
      expect(spec.multipleOf, 5);
      expect(spec.defaultValue, 50);
      expect(spec.description, 'Score');
      expect(spec.nullable, isTrue);
      expect(spec.examples, [10, 20, 30]);
      expect(spec.isDeprecated, isTrue);
    });

    test('double with all options', () {
      const spec = NumberSpec.double(
        minimum: 0.0,
        maximum: 1.0,
        exclusiveMinimum: false,
        exclusiveMaximum: false,
        multipleOf: 0.1,
        defaultValue: 0.5,
        description: 'Ratio',
        nullable: false,
        examples: [0.25, 0.5, 0.75],
        isDeprecated: false,
      );
      expect(spec.isInteger, isFalse);
      expect(spec.minimum, 0.0);
      expect(spec.maximum, 1.0);
      expect(spec.multipleOf, 0.1);
      expect(spec.defaultValue, 0.5);
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

    test('asNullable', () {
      const spec = BoolSpec(defaultValue: false);
      final nullable = spec.asNullable();
      expect(nullable.nullable, isTrue);
      expect(nullable.defaultValue, isFalse);
    });

    test('withDescription', () {
      const spec = BoolSpec();
      final withDesc = spec.withDescription('Is active');
      expect(withDesc.description, 'Is active');
    });

    test('copyWith', () {
      const spec = BoolSpec(defaultValue: true);
      final copied = spec.copyWith(description: 'Enabled');
      expect(copied.defaultValue, isTrue);
      expect(copied.description, 'Enabled');
    });

    test('with all properties', () {
      const spec = BoolSpec(
        defaultValue: true,
        description: 'Active flag',
        nullable: true,
        examples: [true, false],
        isDeprecated: true,
      );
      expect(spec.defaultValue, isTrue);
      expect(spec.description, 'Active flag');
      expect(spec.nullable, isTrue);
      expect(spec.examples, [true, false]);
      expect(spec.isDeprecated, isTrue);
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
      expect(spec.additionalProperties, isFalse);
      expect(spec.title, isNull);
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

    test('asNullable', () {
      const spec = ObjectSpec(name: 'User', properties: {});
      final nullable = spec.asNullable();
      expect(nullable.nullable, isTrue);
      expect(nullable.name, 'User');
    });

    test('withDescription', () {
      const spec = ObjectSpec(name: 'User', properties: {});
      final withDesc = spec.withDescription('A user object');
      expect(withDesc.description, 'A user object');
    });

    test('copyWith', () {
      const spec = ObjectSpec(name: 'User', properties: {});
      final copied = spec.copyWith(title: 'User Object', additionalProperties: true);
      expect(copied.title, 'User Object');
      expect(copied.additionalProperties, isTrue);
    });

    test('with all properties', () {
      const spec = ObjectSpec(
        name: 'User',
        properties: {
          'id': PropertySpec(name: 'id', type: StringSpec()),
        },
        required: ['id'],
        additionalProperties: true,
        title: 'User Model',
        description: 'Represents a user',
        nullable: true,
        examples: [{'id': '123'}],
        isDeprecated: true,
      );
      expect(spec.name, 'User');
      expect(spec.properties, hasLength(1));
      expect(spec.required, ['id']);
      expect(spec.additionalProperties, isTrue);
      expect(spec.title, 'User Model');
      expect(spec.description, 'Represents a user');
      expect(spec.nullable, isTrue);
      expect(spec.isDeprecated, isTrue);
    });
  });

  group('ArraySpec', () {
    test('basic', () {
      const spec = ArraySpec(items: StringSpec());
      expect(spec.items, isA<StringSpec>());
      expect(spec.uniqueItems, isFalse);
      expect(spec.minItems, isNull);
      expect(spec.maxItems, isNull);
      expect(spec.defaultValue, isNull);
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

    test('asNullable', () {
      const spec = ArraySpec(items: StringSpec());
      final nullable = spec.asNullable();
      expect(nullable.nullable, isTrue);
      expect(nullable.items, isA<StringSpec>());
    });

    test('withDescription', () {
      const spec = ArraySpec(items: StringSpec());
      final withDesc = spec.withDescription('List of tags');
      expect(withDesc.description, 'List of tags');
    });

    test('copyWith', () {
      const spec = ArraySpec(items: StringSpec(), minItems: 1);
      final copied = spec.copyWith(maxItems: 100, uniqueItems: true);
      expect(copied.minItems, 1);
      expect(copied.maxItems, 100);
      expect(copied.uniqueItems, isTrue);
    });

    test('with all properties', () {
      const spec = ArraySpec(
        items: StringSpec(),
        minItems: 0,
        maxItems: 10,
        uniqueItems: true,
        defaultValue: ['a', 'b'],
        description: 'Tags list',
        nullable: true,
        examples: [['x', 'y']],
        isDeprecated: true,
      );
      expect(spec.minItems, 0);
      expect(spec.maxItems, 10);
      expect(spec.uniqueItems, isTrue);
      expect(spec.defaultValue, ['a', 'b']);
      expect(spec.description, 'Tags list');
      expect(spec.nullable, isTrue);
      expect(spec.isDeprecated, isTrue);
    });
  });

  group('MapSpec', () {
    test('basic', () {
      const spec = MapSpec(keyType: StringSpec(), valueType: NumberSpec.integer());
      expect(spec.keyType, isA<StringSpec>());
      expect(spec.valueType, isA<NumberSpec>());
    });

    test('asNullable', () {
      const spec = MapSpec(keyType: StringSpec(), valueType: StringSpec());
      final nullable = spec.asNullable();
      expect(nullable.nullable, isTrue);
    });

    test('withDescription', () {
      const spec = MapSpec(keyType: StringSpec(), valueType: StringSpec());
      final withDesc = spec.withDescription('Metadata map');
      expect(withDesc.description, 'Metadata map');
    });

    test('copyWith', () {
      const spec = MapSpec(keyType: StringSpec(), valueType: StringSpec());
      final copied = spec.copyWith(description: 'Config', nullable: true);
      expect(copied.description, 'Config');
      expect(copied.nullable, isTrue);
    });

    test('with all properties', () {
      const spec = MapSpec(
        keyType: StringSpec(),
        valueType: NumberSpec.integer(),
        description: 'Scores map',
        nullable: true,
        examples: [{'a': 1}],
        isDeprecated: true,
      );
      expect(spec.description, 'Scores map');
      expect(spec.nullable, isTrue);
      expect(spec.isDeprecated, isTrue);
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

    test('asNullable', () {
      const spec = EnumSpec(name: 'Status', values: []);
      final nullable = spec.asNullable();
      expect(nullable.nullable, isTrue);
    });

    test('withDescription', () {
      const spec = EnumSpec(name: 'Status', values: []);
      final withDesc = spec.withDescription('User status');
      expect(withDesc.description, 'User status');
    });

    test('copyWith', () {
      const spec = EnumSpec(name: 'Status', values: []);
      final copied = spec.copyWith(name: 'NewStatus', nullable: true);
      expect(copied.name, 'NewStatus');
      expect(copied.nullable, isTrue);
    });

    test('EnumValueSpec with description', () {
      const value = EnumValueSpec(
        name: 'active',
        jsonValue: 'ACTIVE',
        description: 'Active status',
      );
      expect(value.name, 'active');
      expect(value.jsonValue, 'ACTIVE');
      expect(value.effectiveValue, 'ACTIVE');
      expect(value.description, 'Active status');
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

    test('asNullable', () {
      const spec = UnionSpec(name: 'Result', variants: []);
      final nullable = spec.asNullable();
      expect(nullable.nullable, isTrue);
    });

    test('withDescription', () {
      const spec = UnionSpec(name: 'Result', variants: []);
      final withDesc = spec.withDescription('Operation result');
      expect(withDesc.description, 'Operation result');
    });

    test('copyWith', () {
      const spec = UnionSpec(name: 'Result', variants: []);
      final copied = spec.copyWith(discriminator: 'kind', nullable: true);
      expect(copied.discriminator, 'kind');
      expect(copied.nullable, isTrue);
    });

    test('with all properties', () {
      const spec = UnionSpec(
        name: 'Result',
        discriminator: 'type',
        variants: [ObjectSpec(name: 'Ok', properties: {})],
        description: 'A result type',
        nullable: true,
        examples: [{'type': 'Ok'}],
        isDeprecated: true,
      );
      expect(spec.name, 'Result');
      expect(spec.discriminator, 'type');
      expect(spec.variants, hasLength(1));
      expect(spec.description, 'A result type');
      expect(spec.nullable, isTrue);
      expect(spec.isDeprecated, isTrue);
    });
  });

  group('RefSpec', () {
    test('basic', () {
      const spec = RefSpec(typeName: 'User');
      expect(spec.typeName, 'User');
    });

    test('asNullable', () {
      const spec = RefSpec(typeName: 'User');
      final nullable = spec.asNullable();
      expect(nullable.nullable, isTrue);
      expect(nullable.typeName, 'User');
    });

    test('withDescription', () {
      const spec = RefSpec(typeName: 'User');
      final withDesc = spec.withDescription('Reference to user');
      expect(withDesc.description, 'Reference to user');
    });

    test('copyWith', () {
      const spec = RefSpec(typeName: 'User');
      final copied = spec.copyWith(typeName: 'Admin', nullable: true);
      expect(copied.typeName, 'Admin');
      expect(copied.nullable, isTrue);
    });

    test('with all properties', () {
      const spec = RefSpec(
        typeName: 'User',
        nullable: true,
        description: 'User reference',
        examples: ['user-123'],
        isDeprecated: true,
      );
      expect(spec.typeName, 'User');
      expect(spec.nullable, isTrue);
      expect(spec.description, 'User reference');
      expect(spec.isDeprecated, isTrue);
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

    test('copyWith', () {
      const spec = PropertySpec(name: 'id', type: StringSpec());
      final copied = spec.copyWith(jsonName: 'ID', required: false);
      expect(copied.name, 'id');
      expect(copied.jsonName, 'ID');
      expect(copied.required, isFalse);
    });

    test('default required is true', () {
      const spec = PropertySpec(name: 'id', type: StringSpec());
      expect(spec.required, isTrue);
    });
  });
}
