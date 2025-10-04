import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:soti_schema_plus/annotations.dart';
import 'package:test/test.dart';

part 'schema_generation_test.g.dart';

void main() {
  group('JsonSerializable Schema Generation', () {
    test('generates String schema for JsonPerson', () {
      expect(JsonPerson.schema, isNotEmpty);
      final schema = jsonDecode(JsonPerson.schema);
      expect(schema[r'$schema'], 'https://json-schema.org/draft/2020-12/schema');
      expect(schema['type'], 'object');
      expect(schema['properties'], isNotNull);
    });

    test('JsonPerson schema has correct properties', () {
      final schema = jsonDecode(JsonPerson.schema);
      final properties = schema['properties'] as Map<String, dynamic>;

      expect(properties['name'], isNotNull);
      expect(properties['name']['type'], 'string');

      expect(properties['age'], isNotNull);
      expect(properties['age']['type'], 'integer');

      expect(properties['hobbies'], isNotNull);
      expect(properties['hobbies']['type'], 'array');
      expect(properties['hobbies']['items']['type'], 'string');
    });

    test('generates Map schema for JsonPerson', () {
      expect(JsonPerson.schemaMap, isNotEmpty);
      expect(JsonPerson.schemaMap[r'$schema'], 'https://json-schema.org/draft/2020-12/schema');
      expect(JsonPerson.schemaMap['type'], 'object');
      expect(JsonPerson.schemaMap['properties'], isNotNull);
    });

    test('String and Map schemas are equivalent', () {
      final stringSchema = jsonDecode(JsonPerson.schema);
      final mapSchema = JsonPerson.schemaMap;

      expect(jsonEncode(stringSchema), jsonEncode(mapSchema));
    });
  });

  group('Address Schema Generation', () {
    test('generates schema with documentation comments', () {
      final schema = jsonDecode(Address.schema);
      final properties = schema['properties'] as Map<String, dynamic>;

      expect(properties['street']['description'], '/// Street address line');
      expect(properties['city']['description'], '/// City name');
      expect(properties['state']['description'], '/// State or province');
      expect(properties['postalCode']['description'], '/// Postal/ZIP code');
      expect(properties['country']['description'], '/// Country name');
    });

    test('handles required vs optional fields', () {
      final schema = jsonDecode(Address.schema);
      final required = schema['required'] as List<dynamic>;

      // street, city, and country are required (non-nullable)
      expect(required, contains('street'));
      expect(required, contains('city'));
      expect(required, contains('country'));

      // state and postalCode are optional (nullable)
      expect(required, isNot(contains('state')));
      expect(required, isNot(contains('postalCode')));
    });

    test('has correct property types', () {
      final schema = jsonDecode(Address.schema);
      final properties = schema['properties'] as Map<String, dynamic>;

      expect(properties['street']['type'], 'string');
      expect(properties['city']['type'], 'string');
      expect(properties['state']['type'], 'string');
      expect(properties['postalCode']['type'], 'string');
      expect(properties['country']['type'], 'string');
    });
  });

  group('Employee Schema Generation with Nested Objects', () {
    test('generates schema with all property types', () {
      final schema = jsonDecode(Employee.schemaString);
      final properties = schema['properties'] as Map<String, dynamic>;

      expect(properties['name']['type'], 'string');
      expect(properties['employeeId']['type'], 'integer');
      expect(properties['department']['type'], 'string');
      expect(properties['email']['type'], 'string');
      expect(properties['skills']['type'], 'array');
      expect(properties['yearsOfExperience']['type'], 'number');
      expect(properties['isActive']['type'], 'boolean');
      expect(properties['hireDate']['type'], 'string');
      expect(properties['hireDate']['format'], 'date-time');
    });

    test('includes field descriptions from doc comments', () {
      final schema = jsonDecode(Employee.schemaString);
      final properties = schema['properties'] as Map<String, dynamic>;

      expect(properties['name']['description'], "/// Employee's full name");
      expect(properties['employeeId']['description'], '/// Employee ID number');
      expect(properties['department']['description'], '/// Department name');
      expect(properties['email']['description'], "/// Employee's work email");
      expect(properties['skills']['description'], '/// List of skills');
      expect(properties['yearsOfExperience']['description'], '/// Years of experience');
      expect(properties['isActive']['description'], '/// Is the employee currently active');
      expect(properties['hireDate']['description'], '/// Hire date');
    });

    test('handles nested object references', () {
      final schema = jsonDecode(Employee.schemaString);
      final properties = schema['properties'] as Map<String, dynamic>;

      // officeAddress should reference Address in $defs
      expect(properties['officeAddress'], isNotNull);
      expect(properties['officeAddress'][r'$ref'], isNotNull);
      expect(properties['officeAddress'][r'$ref'], contains('Address'));
    });

    test('includes nested schema definitions', () {
      final schema = jsonDecode(Employee.schemaString);
      final defs = schema[r'$defs'] as Map<String, dynamic>?;

      expect(defs, isNotNull);
      expect(defs!['Address'], isNotNull);

      final addressDef = defs['Address'] as Map<String, dynamic>;
      expect(addressDef['type'], 'object');
      expect(addressDef['properties'], isNotNull);
    });

    test('default values are not included for json_serializable classes', () {
      final schema = jsonDecode(Employee.schemaString);
      final properties = schema['properties'] as Map<String, dynamic>;

      // Default values in constructor parameters don't generate schema defaults
      // for json_serializable (this is expected behavior)
      expect(properties['skills']['default'], isNull);
      expect(properties['yearsOfExperience']['default'], isNull);
      expect(properties['isActive']['default'], isNull);
    });

    test('flexible schema naming works', () {
      // Test that both schemaString and schemaObject work
      final stringSchema = jsonDecode(Employee.schemaString);
      final objectSchema = Employee.schemaObject;

      expect(jsonEncode(stringSchema), jsonEncode(objectSchema));
    });
  });

  group('Schema Validation', () {
    test('generated schemas are valid JSON', () {
      expect(() => jsonDecode(JsonPerson.schema), returnsNormally);
      expect(() => jsonDecode(Address.schema), returnsNormally);
      expect(() => jsonDecode(Employee.schemaString), returnsNormally);
    });

    test('schemas follow draft 2020-12 format', () {
      final schemas = [
        jsonDecode(JsonPerson.schema),
        jsonDecode(Address.schema),
        jsonDecode(Employee.schemaString),
      ];

      for (final schema in schemas) {
        expect(schema[r'$schema'], 'https://json-schema.org/draft/2020-12/schema');
        expect(schema['type'], 'object');
        expect(schema[r'$defs'], isNotNull);
      }
    });
  });

  group('Data Serialization', () {
    test('JsonPerson serializes correctly', () {
      final person = JsonPerson(
        name: 'John Doe',
        age: 30,
        hobbies: ['reading', 'coding'],
      );

      final json = person.toJson();
      expect(json['name'], 'John Doe');
      expect(json['age'], 30);
      expect(json['hobbies'], ['reading', 'coding']);

      final restored = JsonPerson.fromJson(json);
      expect(restored.name, person.name);
      expect(restored.age, person.age);
      expect(restored.hobbies, person.hobbies);
    });

    test('Address serializes correctly', () {
      final address = Address(
        street: '123 Main St',
        city: 'Springfield',
        state: 'IL',
        postalCode: '62701',
        country: 'USA',
      );

      final json = address.toJson();
      expect(json['street'], '123 Main St');
      expect(json['city'], 'Springfield');
      expect(json['state'], 'IL');
      expect(json['postalCode'], '62701');
      expect(json['country'], 'USA');

      final restored = Address.fromJson(json);
      expect(restored.street, address.street);
      expect(restored.city, address.city);
      expect(restored.state, address.state);
      expect(restored.postalCode, address.postalCode);
      expect(restored.country, address.country);
    });

    test('Employee with nested Address serializes correctly', () {
      final employee = Employee(
        name: 'Jane Smith',
        employeeId: 12345,
        department: 'Engineering',
        email: 'jane.smith@example.com',
        skills: ['Dart', 'Flutter', 'TypeScript'],
        yearsOfExperience: 5.5,
        hireDate: DateTime(2019, 3, 15),
        officeAddress: Address(
          street: '123 Tech Street',
          city: 'San Francisco',
          state: 'CA',
          postalCode: '94105',
          country: 'USA',
        ),
      );

      final json = employee.toJson();
      expect(json['name'], 'Jane Smith');
      expect(json['employeeId'], 12345);
      expect(json['department'], 'Engineering');
      expect(json['email'], 'jane.smith@example.com');
      expect(json['skills'], ['Dart', 'Flutter', 'TypeScript']);
      expect(json['yearsOfExperience'], 5.5);
      expect(json['isActive'], true);
      expect(json['officeAddress'], isNotNull);

      final officeJson = json['officeAddress'] as Map<String, dynamic>;
      expect(officeJson['city'], 'San Francisco');

      final restored = Employee.fromJson(json);
      expect(restored.name, employee.name);
      expect(restored.employeeId, employee.employeeId);
      expect(restored.department, employee.department);
      expect(restored.email, employee.email);
      expect(restored.skills, employee.skills);
      expect(restored.yearsOfExperience, employee.yearsOfExperience);
      expect(restored.isActive, employee.isActive);
      expect(restored.hireDate, employee.hireDate);
      expect(restored.officeAddress?.city, employee.officeAddress?.city);
    });
  });
}

// JsonSerializable Model with Multiple Schema Formats
@SotiSchema()
@JsonSerializable()
class JsonPerson {
  final String name;
  final int age;
  final List<String> hobbies;

  JsonPerson({this.name = '', this.age = 0, this.hobbies = const []});

  factory JsonPerson.fromJson(Map<String, dynamic> json) =>
      _$JsonPersonFromJson(json);

  Map<String, dynamic> toJson() => _$JsonPersonToJson(this);

  @jsonSchema
  static String get schema => _$JsonPersonSchema;

  @jsonSchema
  static Map<String, dynamic> get schemaMap => _$JsonPersonSchemaMap;
}

// Complex JsonSerializable Model with Nested Objects
@SotiSchema()
@JsonSerializable()
class Address {
  /// Street address line
  final String street;

  /// City name
  final String city;

  /// State or province
  final String? state;

  /// Postal/ZIP code
  final String? postalCode;

  /// Country name
  final String country;

  Address({
    required this.street,
    required this.city,
    this.state,
    this.postalCode,
    required this.country,
  });

  factory Address.fromJson(Map<String, dynamic> json) =>
      _$AddressFromJson(json);

  Map<String, dynamic> toJson() => _$AddressToJson(this);

  @jsonSchema
  static String get schema => _$AddressSchema;
}

@SotiSchema()
@JsonSerializable(explicitToJson: true)
class Employee {
  /// Employee's full name
  final String name;

  /// Employee ID number
  final int employeeId;

  /// Department name
  final String department;

  /// Employee's work email
  final String email;

  /// Employee's office address
  final Address? officeAddress;

  /// List of skills
  final List<String> skills;

  /// Years of experience
  final double yearsOfExperience;

  /// Is the employee currently active
  final bool isActive;

  /// Hire date
  final DateTime hireDate;

  Employee({
    required this.name,
    required this.employeeId,
    required this.department,
    required this.email,
    this.officeAddress,
    this.skills = const [],
    this.yearsOfExperience = 0.0,
    this.isActive = true,
    required this.hireDate,
  });

  factory Employee.fromJson(Map<String, dynamic> json) =>
      _$EmployeeFromJson(json);

  Map<String, dynamic> toJson() => _$EmployeeToJson(this);

  // Example of flexible schema naming
  @jsonSchema
  static String get schemaString => _$EmployeeSchema;

  @jsonSchema
  static Map<String, dynamic> get schemaObject => _$EmployeeSchemaMap;
}
