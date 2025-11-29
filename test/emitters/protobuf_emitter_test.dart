import 'package:spectra/src/emitters/emitter.dart';
import 'package:spectra/src/emitters/protobuf_emitter.dart';
import 'package:spectra/src/spec/spec.dart';
import 'package:test/test.dart';

void main() {
  late ProtobufEmitter emitter;
  late EmitContext rootContext;

  setUp(() {
    emitter = ProtobufEmitter();
    rootContext = const EmitContext(definitions: {}, isRoot: true);
  });

  test('formatName', () {
    expect(emitter.formatName, 'Protobuf');
  });

  test('with package name', () {
    final emitterWithPackage = ProtobufEmitter(packageName: 'com.example');
    const spec = ObjectSpec(name: 'User', properties: {});
    final proto = emitterWithPackage.emit(spec, context: rootContext);

    expect(proto, contains('package com.example;'));
  });

  test('with description on object', () {
    const spec = ObjectSpec(
      name: 'User',
      description: 'A user model',
      properties: {},
    );
    final proto = emitter.emit(spec, context: rootContext);

    expect(proto, contains('// A user model'));
  });

  test('with description on field', () {
    const spec = ObjectSpec(
      name: 'User',
      properties: {
        'name': PropertySpec(
          name: 'name',
          type: StringSpec(description: 'User name'),
        ),
      },
    );
    final proto = emitter.emit(spec, context: rootContext);

    expect(proto, contains('// User name'));
  });

  test('enum with description', () {
    const spec = EnumSpec(
      name: 'Status',
      description: 'User status',
      values: [
        EnumValueSpec(name: 'active', description: 'Active user'),
      ],
    );
    final context = EmitContext(
      definitions: {'Status': spec},
      isRoot: true,
    );
    final proto = emitter.emit(
      const ObjectSpec(name: 'Dummy', properties: {}),
      context: context,
    );

    expect(proto, contains('// User status'));
    expect(proto, contains('// Active user'));
  });

  test('union with description', () {
    const spec = UnionSpec(
      name: 'Result',
      description: 'Operation result',
      variants: [ObjectSpec(name: 'Ok', properties: {})],
    );
    final proto = emitter.emit(spec, context: rootContext);

    expect(proto, contains('// Operation result'));
  });

  test('nested object reference', () {
    const spec = ObjectSpec(
      name: 'User',
      properties: {
        'profile': PropertySpec(
          name: 'profile',
          type: ObjectSpec(name: 'Profile', properties: {}),
        ),
      },
    );
    final proto = emitter.emit(spec, context: rootContext);

    expect(proto, contains('Profile profile = 1;'));
  });

  test('enum type in field', () {
    const spec = ObjectSpec(
      name: 'User',
      properties: {
        'status': PropertySpec(
          name: 'status',
          type: EnumSpec(name: 'Status', values: []),
        ),
      },
    );
    final proto = emitter.emit(spec, context: rootContext);

    expect(proto, contains('Status status = 1;'));
  });

  test('union type in field', () {
    const spec = ObjectSpec(
      name: 'User',
      properties: {
        'result': PropertySpec(
          name: 'result',
          type: UnionSpec(name: 'Result', variants: []),
        ),
      },
    );
    final proto = emitter.emit(spec, context: rootContext);

    expect(proto, contains('Result result = 1;'));
  });

  group('Primitive types', () {
    test('StringSpec emits string', () {
      const spec = ObjectSpec(
        name: 'Test',
        properties: {
          'value': PropertySpec(name: 'value', type: StringSpec()),
        },
      );
      final proto = emitter.emit(spec, context: rootContext);

      expect(proto, contains('string value = 1;'));
    });

    test('NumberSpec integer emits int64', () {
      const spec = ObjectSpec(
        name: 'Test',
        properties: {
          'value': PropertySpec(name: 'value', type: NumberSpec.integer()),
        },
      );
      final proto = emitter.emit(spec, context: rootContext);

      expect(proto, contains('int64 value = 1;'));
    });

    test('NumberSpec double emits double', () {
      const spec = ObjectSpec(
        name: 'Test',
        properties: {
          'value': PropertySpec(name: 'value', type: NumberSpec.double()),
        },
      );
      final proto = emitter.emit(spec, context: rootContext);

      expect(proto, contains('double value = 1;'));
    });

    test('BoolSpec emits bool', () {
      const spec = ObjectSpec(
        name: 'Test',
        properties: {
          'value': PropertySpec(name: 'value', type: BoolSpec()),
        },
      );
      final proto = emitter.emit(spec, context: rootContext);

      expect(proto, contains('bool value = 1;'));
    });
  });

  group('ObjectSpec', () {
    test('basic message', () {
      const spec = ObjectSpec(
        name: 'User',
        properties: {},
      );
      final proto = emitter.emit(spec, context: rootContext);

      expect(proto, contains('message User'));
      expect(proto, contains('{'));
      expect(proto, contains('}'));
    });

    test('message with fields', () {
      const spec = ObjectSpec(
        name: 'User',
        properties: {
          'name': PropertySpec(name: 'name', type: StringSpec()),
          'age': PropertySpec(name: 'age', type: NumberSpec.integer()),
          'email': PropertySpec(name: 'email', type: StringSpec()),
        },
      );
      final proto = emitter.emit(spec, context: rootContext);

      expect(proto, contains('message User'));
      expect(proto, contains('string name = 1;'));
      expect(proto, contains('int64 age = 2;'));
      expect(proto, contains('string email = 3;'));
    });

    test('optional fields', () {
      const spec = ObjectSpec(
        name: 'User',
        properties: {
          'name': PropertySpec(name: 'name', type: StringSpec()),
          'nickname': PropertySpec(
            name: 'nickname',
            type: StringSpec(nullable: true),
            required: false,
          ),
        },
      );
      final proto = emitter.emit(spec, context: rootContext);

      expect(proto, contains('string name = 1;'));
      expect(proto, contains('optional string nickname = 2;'));
    });
  });

  group('ArraySpec', () {
    test('emits repeated', () {
      const spec = ObjectSpec(
        name: 'User',
        properties: {
          'tags': PropertySpec(
            name: 'tags',
            type: ArraySpec(items: StringSpec()),
          ),
        },
      );
      final proto = emitter.emit(spec, context: rootContext);

      expect(proto, contains('repeated string tags = 1;'));
    });
  });

  group('EnumSpec', () {
    test('basic enum with UNSPECIFIED', () {
      const spec = EnumSpec(
        name: 'Status',
        values: [
          EnumValueSpec(name: 'active'),
          EnumValueSpec(name: 'inactive'),
        ],
      );
      final context = EmitContext(
        definitions: {'Status': spec},
        isRoot: true,
      );
      final proto = emitter.emit(
        const ObjectSpec(name: 'Dummy', properties: {}),
        context: context,
      );

      expect(proto, contains('enum Status'));
      expect(proto, contains('STATUS_UNSPECIFIED = 0;'));
      expect(proto, contains('STATUS_ACTIVE = 1;'));
      expect(proto, contains('STATUS_INACTIVE = 2;'));
    });
  });

  group('RefSpec', () {
    test('emits type name in field', () {
      const spec = ObjectSpec(
        name: 'User',
        properties: {
          'address': PropertySpec(
            name: 'address',
            type: RefSpec(typeName: 'Address'),
          ),
        },
      );
      final proto = emitter.emit(spec, context: rootContext);

      expect(proto, contains('Address address = 1;'));
    });
  });

  group('MapSpec', () {
    test('emits map type', () {
      const spec = ObjectSpec(
        name: 'User',
        properties: {
          'metadata': PropertySpec(
            name: 'metadata',
            type: MapSpec(keyType: StringSpec(), valueType: StringSpec()),
          ),
        },
      );
      final proto = emitter.emit(spec, context: rootContext);

      expect(proto, contains('map<string, string> metadata = 1;'));
    });
  });

  group('UnionSpec', () {
    test('emits oneof with variant', () {
      const spec = UnionSpec(
        name: 'Result',
        discriminator: 'type',
        variants: [
          ObjectSpec(name: 'Success', properties: {}),
          ObjectSpec(name: 'Error', properties: {}),
        ],
      );
      final proto = emitter.emit(spec, context: rootContext);

      expect(proto, contains('message Result'));
      expect(proto, contains('oneof variant'));
      expect(proto, contains('Success success = 1;'));
      expect(proto, contains('Error error = 2;'));
    });
  });

  group('Root schema', () {
    test('includes syntax declaration', () {
      const spec = ObjectSpec(name: 'User', properties: {});
      final proto = emitter.emit(spec, context: rootContext);

      expect(proto, startsWith('syntax = "proto3";'));
    });

    test('includes definitions', () {
      const roleSpec = EnumSpec(
        name: 'Role',
        values: [
          EnumValueSpec(name: 'admin'),
        ],
      );
      const spec = ObjectSpec(name: 'User', properties: {});
      final context = EmitContext(
        definitions: {'Role': roleSpec},
        isRoot: true,
      );
      final proto = emitter.emit(spec, context: context);

      expect(proto, contains('enum Role'));
      expect(proto, contains('message User'));
    });
  });

  group('Field naming', () {
    test('uses snake_case for field names', () {
      const spec = ObjectSpec(
        name: 'User',
        properties: {
          'firstName': PropertySpec(name: 'firstName', type: StringSpec()),
          'lastName': PropertySpec(name: 'lastName', type: StringSpec()),
        },
      );
      final proto = emitter.emit(spec, context: rootContext);

      expect(proto, contains('string first_name = 1;'));
      expect(proto, contains('string last_name = 2;'));
    });
  });
}
