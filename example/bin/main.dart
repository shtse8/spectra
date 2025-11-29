import 'dart:convert';

// Note: After running `dart run build_runner build`, uncomment these imports:
// import 'package:spectra_schema_example/models/user.dart';
// import 'package:spectra_schema_example/models/product.dart';

void main() {
  print('Spectra Example');
  print('================\n');

  print('To generate schemas, run:');
  print('  dart run build_runner build\n');

  print('After generation, you can access schemas like:');
  print('  User.jsonSchema     // Returns JSON string');
  print('  User.jsonSchemaMap  // Returns Map<String, dynamic>\n');

  // Example of what the generated schema would look like:
  final exampleSchema = {
    r'$schema': 'https://json-schema.org/draft/2020-12/schema',
    'title': 'User',
    'description': 'Represents a user account in the system',
    'type': 'object',
    'properties': {
      'id': {'type': 'string'},
      'name': {'type': 'string', 'minLength': 1, 'maxLength': 100},
      'email': {'type': 'string', 'format': 'email'},
      'age': {'type': ['integer', 'null'], 'minimum': 0, 'maximum': 150},
      'tags': {
        'type': 'array',
        'items': {'type': 'string'},
        'maxItems': 10,
        'uniqueItems': true,
      },
      'isActive': {'type': 'boolean', 'default': true},
    },
    'required': ['id', 'name', 'email'],
  };

  print('Example generated schema:');
  final encoder = JsonEncoder.withIndent('  ');
  print(encoder.convert(exampleSchema));
}
