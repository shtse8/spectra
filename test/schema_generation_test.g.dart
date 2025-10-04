// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schema_generation_test.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JsonPerson _$JsonPersonFromJson(Map<String, dynamic> json) => JsonPerson(
  name: json['name'] as String? ?? '',
  age: (json['age'] as num?)?.toInt() ?? 0,
  hobbies:
      (json['hobbies'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$JsonPersonToJson(JsonPerson instance) =>
    <String, dynamic>{
      'name': instance.name,
      'age': instance.age,
      'hobbies': instance.hobbies,
    };

Address _$AddressFromJson(Map<String, dynamic> json) => Address(
  street: json['street'] as String,
  city: json['city'] as String,
  state: json['state'] as String?,
  postalCode: json['postalCode'] as String?,
  country: json['country'] as String,
);

Map<String, dynamic> _$AddressToJson(Address instance) => <String, dynamic>{
  'street': instance.street,
  'city': instance.city,
  'state': instance.state,
  'postalCode': instance.postalCode,
  'country': instance.country,
};

Employee _$EmployeeFromJson(Map<String, dynamic> json) => Employee(
  name: json['name'] as String,
  employeeId: (json['employeeId'] as num).toInt(),
  department: json['department'] as String,
  email: json['email'] as String,
  officeAddress:
      json['officeAddress'] == null
          ? null
          : Address.fromJson(json['officeAddress'] as Map<String, dynamic>),
  skills:
      (json['skills'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  yearsOfExperience: (json['yearsOfExperience'] as num?)?.toDouble() ?? 0.0,
  isActive: json['isActive'] as bool? ?? true,
  hireDate: DateTime.parse(json['hireDate'] as String),
);

Map<String, dynamic> _$EmployeeToJson(Employee instance) => <String, dynamic>{
  'name': instance.name,
  'employeeId': instance.employeeId,
  'department': instance.department,
  'email': instance.email,
  'officeAddress': instance.officeAddress?.toJson(),
  'skills': instance.skills,
  'yearsOfExperience': instance.yearsOfExperience,
  'isActive': instance.isActive,
  'hireDate': instance.hireDate.toIso8601String(),
};

// **************************************************************************
// SotiSchemaGenerator
// **************************************************************************

const _$JsonPersonSchema =
    r'''{"$schema":"https://json-schema.org/draft/2020-12/schema","type":"object","properties":{"name":{"type":"string"},"age":{"type":"integer"},"hobbies":{"type":"array","items":{"type":"string"}}},"required":["name","age","hobbies"],"$defs":{}}''';
const _$JsonPersonSchemaMap = <String, dynamic>{
  r'''$schema''': r'''https://json-schema.org/draft/2020-12/schema''',
  r'''type''': r'''object''',
  r'''properties''': {
    r'''name''': {r'''type''': r'''string'''},
    r'''age''': {r'''type''': r'''integer'''},
    r'''hobbies''': {
      r'''type''': r'''array''',
      r'''items''': {r'''type''': r'''string'''},
    },
  },
  r'''required''': [r'''name''', r'''age''', r'''hobbies'''],
  r'''$defs''': {},
};

const _$AddressSchema =
    r'''{"$schema":"https://json-schema.org/draft/2020-12/schema","type":"object","properties":{"street":{"type":"string","description":"/// Street address line"},"city":{"type":"string","description":"/// City name"},"state":{"type":"string","description":"/// State or province"},"postalCode":{"type":"string","description":"/// Postal/ZIP code"},"country":{"type":"string","description":"/// Country name"}},"required":["street","city","country"],"$defs":{}}''';

const _$EmployeeSchema =
    r'''{"$schema":"https://json-schema.org/draft/2020-12/schema","type":"object","properties":{"name":{"type":"string","description":"/// Employee's full name"},"employeeId":{"type":"integer","description":"/// Employee ID number"},"department":{"type":"string","description":"/// Department name"},"email":{"type":"string","description":"/// Employee's work email"},"officeAddress":{"$ref":"#/$defs/Address","description":"/// Employee's office address"},"skills":{"type":"array","items":{"type":"string"},"description":"/// List of skills"},"yearsOfExperience":{"type":"number","description":"/// Years of experience"},"isActive":{"type":"boolean","description":"/// Is the employee currently active"},"hireDate":{"type":"string","format":"date-time","description":"/// Hire date"}},"required":["name","employeeId","department","email","skills","yearsOfExperience","isActive","hireDate"],"$defs":{"Address":{"type":"object","properties":{"street":{"type":"string","description":"/// Street address line"},"city":{"type":"string","description":"/// City name"},"state":{"type":"string","description":"/// State or province"},"postalCode":{"type":"string","description":"/// Postal/ZIP code"},"country":{"type":"string","description":"/// Country name"}},"required":["street","city","country"]}}}''';
const _$EmployeeSchemaMap = <String, dynamic>{
  r'''$schema''': r'''https://json-schema.org/draft/2020-12/schema''',
  r'''type''': r'''object''',
  r'''properties''': {
    r'''name''': {
      r'''type''': r'''string''',
      r'''description''': r'''/// Employee's full name''',
    },
    r'''employeeId''': {
      r'''type''': r'''integer''',
      r'''description''': r'''/// Employee ID number''',
    },
    r'''department''': {
      r'''type''': r'''string''',
      r'''description''': r'''/// Department name''',
    },
    r'''email''': {
      r'''type''': r'''string''',
      r'''description''': r'''/// Employee's work email''',
    },
    r'''officeAddress''': {
      r'''$ref''': r'''#/$defs/Address''',
      r'''description''': r'''/// Employee's office address''',
    },
    r'''skills''': {
      r'''type''': r'''array''',
      r'''items''': {r'''type''': r'''string'''},
      r'''description''': r'''/// List of skills''',
    },
    r'''yearsOfExperience''': {
      r'''type''': r'''number''',
      r'''description''': r'''/// Years of experience''',
    },
    r'''isActive''': {
      r'''type''': r'''boolean''',
      r'''description''': r'''/// Is the employee currently active''',
    },
    r'''hireDate''': {
      r'''type''': r'''string''',
      r'''format''': r'''date-time''',
      r'''description''': r'''/// Hire date''',
    },
  },
  r'''required''': [
    r'''name''',
    r'''employeeId''',
    r'''department''',
    r'''email''',
    r'''skills''',
    r'''yearsOfExperience''',
    r'''isActive''',
    r'''hireDate''',
  ],
  r'''$defs''': {
    r'''Address''': {
      r'''type''': r'''object''',
      r'''properties''': {
        r'''street''': {
          r'''type''': r'''string''',
          r'''description''': r'''/// Street address line''',
        },
        r'''city''': {
          r'''type''': r'''string''',
          r'''description''': r'''/// City name''',
        },
        r'''state''': {
          r'''type''': r'''string''',
          r'''description''': r'''/// State or province''',
        },
        r'''postalCode''': {
          r'''type''': r'''string''',
          r'''description''': r'''/// Postal/ZIP code''',
        },
        r'''country''': {
          r'''type''': r'''string''',
          r'''description''': r'''/// Country name''',
        },
      },
      r'''required''': [r'''street''', r'''city''', r'''country'''],
    },
  },
};
