import 'dart:async';
import 'dart:convert';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'annotations.dart';

enum DataClassType { jsonSerializable, freezed, unsupported }

class PropertyInfo {
  final String name;
  final DartType type;
  final bool isRequired;
  final DartObject? defaultValue;
  final String? description;

  const PropertyInfo(
    this.name,
    this.type, {
    required this.isRequired,
    this.defaultValue,
    this.description,
  });
}

class SotiSchemaGenerator extends GeneratorForAnnotation<SotiSchema> {
  static const _typeCheckers = TypeCheckers();

  final _schemaGenerator = JsonSchemaGenerator();

  @override
  FutureOr<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    // Helpful diagnostics
    log.info('SotiSchema: processing class ${element.displayName}');
    // Check if element is a ClassElement
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        'SotiSchema can only be applied to classes: ${element.displayName}',
      );
    }

    final buffer = StringBuffer();

    // Use Element API to get all getters
    for (final getter in element.getters) {
      if (!getter.isStatic) continue;

      // Check for JsonSchema annotation using the metadata API
      final hasJsonSchema = getter.metadata.annotations.any((anno) {
        final value = anno.computeConstantValue();
        if (value == null || value.type == null) return false;
        return _typeCheckers.jsonSchemaChecker.isExactlyType(value.type!);
      });

      if (hasJsonSchema) {
        log.fine(
          'SotiSchema: found @jsonSchema getter ${getter.displayName} in ${element.displayName}',
        );
        final schema = _schemaGenerator.generateSchema(element);
        final name = await _getRedirectedVariableName(getter, buildStep);
        if (name == null) {
          throw InvalidGenerationSourceError(
            'Failed to extract redirected variable name for ${getter.displayName}.',
          );
        }
        _writeSchemaToBuffer(buffer, name, getter.returnType, schema);
      }
    }

    return buffer.toString();
  }

  void _writeSchemaToBuffer(
    StringBuffer buffer,
    String name,
    DartType type,
    Map<String, dynamic> schema,
  ) {
    if (_typeCheckers.stringChecker.isExactlyType(type)) {
      // Use raw triple quotes so embedded single quotes in descriptions don't break parsing
      buffer.writeln("const $name = r'''${jsonEncode(schema)}''';");
    } else if (_isMapStringDynamic(type)) {
      buffer.writeln('const $name = ${_generateMapLiteral(schema)};');
    } else {
      throw InvalidGenerationSourceError(
        'Failed to generate schema for $name. Only support String or Map<String, dynamic>.',
      );
    }
  }

  String _generateMapLiteral(Map<String, dynamic> map) {
    return '<String, dynamic>${_convertMapToString(map)}';
  }

  String _convertMapToString(Map<String, dynamic> map) {
    return '{${map.entries.map((e) => '${_escapeKey(e.key)}: ${_convertValueToString(e.value)}').join(', ')}}';
  }

  String _escapeKey(String key) {
    // Raw triple-quoted to safely include $ and single quotes
    return "r'''$key'''";
  }

  String _convertValueToString(dynamic value) {
    if (value is Map<String, dynamic>) {
      return _convertMapToString(value);
    } else if (value is List) {
      return _convertListToString(value);
    } else if (value is String) {
      // Raw triple-quoted to avoid escaping for $ and single quotes
      return "r'''$value'''";
    } else {
      return value.toString();
    }
  }

  String _convertListToString(List list) {
    return '[${list.map((e) => _convertValueToString(e)).join(', ')}]';
  }

  bool _isMapStringDynamic(DartType type) {
    if (type is ParameterizedType &&
        _typeCheckers.mapChecker.isExactlyType(type)) {
      var typeArguments = type.typeArguments;
      return typeArguments.length == 2 &&
          _typeCheckers.stringChecker.isExactlyType(typeArguments[0]) &&
          typeArguments[1] is DynamicType;
    }
    return false;
  }

  Future<String?> _getRedirectedVariableName(
    GetterElement getter,
    BuildStep buildStep,
  ) async {
    final parsedLibrary = await _getParsedLibrary(getter, buildStep);
    final fragment = getter.firstFragment;
    final node = _findGetterDeclaration(parsedLibrary, fragment);
    return node != null ? _extractGetterBody(node) : null;
  }

  Future<ParsedLibraryResult> _getParsedLibrary(
    Element element,
    BuildStep buildStep,
  ) async {
    final assetId = buildStep.inputId;
    final resolver = buildStep.resolver;
    final library = await resolver.libraryFor(assetId);

    // Use the session to get the parsed library
    final session = library.session;
    final parsedLibrary = session.getParsedLibraryByElement(element.library!);

    if (parsedLibrary is ParsedLibraryResult) {
      return parsedLibrary;
    }

    throw InvalidGenerationSourceError(
      'Failed to parse library for ${element.displayName}',
    );
  }

  MethodDeclaration? _findGetterDeclaration(
    ParsedLibraryResult parsedLibrary,
    Fragment fragment,
  ) {
    final result = parsedLibrary.getFragmentDeclaration(fragment);
    return (result?.node is MethodDeclaration)
        ? result!.node as MethodDeclaration
        : null;
  }

  String? _extractGetterBody(MethodDeclaration getterDeclaration) {
    final body = getterDeclaration.body;
    if (body is ExpressionFunctionBody) {
      final expression = body.expression;
      if (expression is SimpleIdentifier) {
        return expression.name;
      }
    }
    return null;
  }
}

class JsonSchemaGenerator {
  final _typeCheckers = TypeCheckers();
  final _generatedSchemas = <String, Map<String, dynamic>>{};

  Map<String, dynamic> generateSchema(ClassElement element) {
    _generatedSchemas.clear();
    final mainSchema = _getPropertySchema(element.thisType, isRoot: true);

    return {
      r'$schema': 'https://json-schema.org/draft/2020-12/schema',
      ...mainSchema,
      r'$defs': _generatedSchemas,
    };
  }

  Map<String, dynamic> _getPropertySchema(
    DartType type, {
    bool isRoot = false,
    Set<DartType> seenTypes = const {},
  }) {
    if (!isRoot && seenTypes.contains(type)) {
      final element = type.element;
      if (element != null) {
        return {r'$ref': '#/\$defs/${element.displayName}'};
      }
    }

    var newSeenTypes = Set<DartType>.from(seenTypes)..add(type);

    if (_typeCheckers.stringChecker.isExactlyType(type)) {
      return {'type': 'string'};
    }
    if (_typeCheckers.intChecker.isExactlyType(type)) {
      return {'type': 'integer'};
    }
    if (_typeCheckers.doubleChecker.isExactlyType(type)) {
      return {'type': 'number'};
    }
    if (_typeCheckers.boolChecker.isExactlyType(type)) {
      return {'type': 'boolean'};
    }
    if (_typeCheckers.dateTimeChecker.isExactlyType(type)) {
      return {'type': 'string', 'format': 'date-time'};
    }
    if (_typeCheckers.uriChecker.isExactlyType(type)) {
      return {'type': 'string', 'format': 'uri'};
    }

    if (_typeCheckers.iterableChecker.isAssignableFromType(type)) {
      final itemType = _getGenericType(type);
      return {
        'type': 'array',
        'items': _getPropertySchema(itemType, seenTypes: newSeenTypes),
      };
    }

    if (_typeCheckers.mapChecker.isAssignableFromType(type)) {
      final valueType = _getGenericType(type, 1);
      return {
        'type': 'object',
        'additionalProperties': _getPropertySchema(
          valueType,
          seenTypes: newSeenTypes,
        ),
      };
    }

    if (type is InterfaceType &&
        !_typeCheckers.objectChecker.isExactlyType(type)) {
      return _generateComplexTypeSchema(type, isRoot, newSeenTypes);
    }

    return {'type': 'object'};
  }

  Map<String, dynamic> _generateComplexTypeSchema(
    InterfaceType type,
    bool isRoot,
    Set<DartType> seenTypes,
  ) {
    final element = type.element;
    final typeName = element.displayName;

    if (!isRoot && _generatedSchemas.containsKey(typeName)) {
      return {r'$ref': '#/\$defs/$typeName'};
    }

    final classElement = element;
    final dataClassType = _identifyDataClassType(classElement);
    final properties = _getProperties(classElement, dataClassType);

    final schemaProperties = <String, dynamic>{};
    final required = <String>[];

    for (final property in properties) {
      final propertySchema = _getPropertySchema(
        property.type,
        seenTypes: seenTypes,
      );

      if (property.description != null) {
        propertySchema['description'] = property.description;
      }

      if (property.defaultValue != null) {
        if (_typeCheckers.stringChecker.isAssignableFromType(property.type)) {
          propertySchema['default'] = property.defaultValue!.toStringValue();
        } else if (_typeCheckers.intChecker.isAssignableFromType(
          property.type,
        )) {
          propertySchema['default'] = property.defaultValue!.toIntValue();
        } else if (_typeCheckers.doubleChecker.isAssignableFromType(
          property.type,
        )) {
          propertySchema['default'] = property.defaultValue!.toDoubleValue();
        } else if (_typeCheckers.boolChecker.isAssignableFromType(
          property.type,
        )) {
          propertySchema['default'] = property.defaultValue!.toBoolValue();
        } else if (_typeCheckers.iterableChecker.isAssignableFromType(
          property.type,
        )) {
          propertySchema['default'] = property.defaultValue!.toListValue();
        } else if (_typeCheckers.mapChecker.isAssignableFromType(
          property.type,
        )) {
          propertySchema['default'] = property.defaultValue!.toMapValue();
        } else {
          throw UnsupportedError(
            'Unsupported default value type for property ${property.name}',
          );
        }
      }

      schemaProperties[property.name] = propertySchema;

      if (property.isRequired) {
        required.add(property.name);
      }
    }

    final schema = {
      'type': 'object',
      'properties': schemaProperties,
      if (required.isNotEmpty) 'required': required,
    };

    if (!isRoot) {
      _generatedSchemas[typeName] = schema;
      return {r'$ref': '#/\$defs/$typeName'};
    }

    return schema;
  }

  DataClassType _identifyDataClassType(InterfaceElement element) {
    // Check for JsonSerializable annotation
    final hasJsonSerializable = element.metadata.annotations.any((anno) {
      final value = anno.computeConstantValue();
      if (value == null || value.type == null) return false;
      return _typeCheckers.jsonSerializableChecker.isExactlyType(value.type!);
    });

    if (hasJsonSerializable) {
      log.fine(
        'SotiSchema: ${element.displayName} identified as JsonSerializable',
      );
      return DataClassType.jsonSerializable;
    }

    // Heuristic fallback: match by simple name to handle analyzer/URL discrepancies
    final hasJsonSerializableByName = element.metadata.annotations.any((anno) {
      final t = anno.computeConstantValue()?.type;
      final name = t?.getDisplayString();
      return name == 'JsonSerializable';
    });
    if (hasJsonSerializableByName) {
      log.fine(
        'SotiSchema: ${element.displayName} identified as JsonSerializable (by name)',
      );
      return DataClassType.jsonSerializable;
    }

    // Check for Freezed annotation
    final hasFreezed = element.metadata.annotations.any((anno) {
      final value = anno.computeConstantValue();
      if (value == null || value.type == null) return false;
      return _typeCheckers.freezedChecker.isExactlyType(value.type!);
    });

    if (hasFreezed) {
      log.fine('SotiSchema: ${element.displayName} identified as Freezed');
      return DataClassType.freezed;
    }

    // Provide diagnostics when unsupported
    final annotations = element.metadata.annotations
        .map(
          (a) =>
              a.computeConstantValue()?.type?.getDisplayString() ?? '<unknown>',
        )
        .join(', ');
    log.severe(
      'SotiSchema: ${element.displayName} has unsupported data class type. Found annotations: [$annotations]',
    );
    return DataClassType.unsupported;
  }

  DartType _getGenericType(DartType type, [int index = 0]) {
    return (type is InterfaceType && type.typeArguments.isNotEmpty)
        ? type.typeArguments[index]
        : type;
  }

  List<PropertyInfo> _getProperties(
    InterfaceElement element,
    DataClassType dataClassType,
  ) {
    switch (dataClassType) {
      case DataClassType.jsonSerializable:
        return _getJsonSerializableProperties(element);
      case DataClassType.freezed:
        return _getFreezedProperties(element);
      case DataClassType.unsupported:
        // Strict failure: require @JsonSerializable or @freezed
        throw UnsupportedError(
          'Unsupported data class type for ${element.displayName}. Use @JsonSerializable or @freezed annotation.',
        );
    }
  }

  List<PropertyInfo> _getJsonSerializableProperties(InterfaceElement element) {
    final properties = <PropertyInfo>[];

    // Use Element API to get fields
    for (var field in element.fields) {
      if (field.isStatic || !field.isPublic) continue;

      // Check for JsonKey annotation
      DartObject? jsonKey;
      for (final anno in field.metadata.annotations) {
        final value = anno.computeConstantValue();
        if (value != null && value.type != null) {
          if (_typeCheckers.jsonKeyChecker.isExactlyType(value.type!)) {
            jsonKey = value;
            break;
          }
        }
      }

      final reader = jsonKey != null ? ConstantReader(jsonKey) : null;

      final includeFromJson = reader?.read('includeFromJson').boolValue ?? true;
      final includeToJson = reader?.read('includeToJson').boolValue ?? true;

      if (!includeFromJson || !includeToJson) continue;

      final isRequired =
          field.isFinal &&
          field.type.nullabilitySuffix == NullabilitySuffix.none;
      final defaultValue = reader?.read('defaultValue').objectValue;

      // Get documentation from the field
      final description =
          field.documentationComment
              ?.replaceAll(
                RegExp(r'^\s*\/\*\*\s*|\s*\*\/\s*$|\s*\*\s?', multiLine: true),
                '',
              )
              .trim();

      properties.add(
        PropertyInfo(
          field.displayName,
          field.type,
          isRequired: isRequired,
          defaultValue: defaultValue,
          description: description,
        ),
      );
    }

    return properties;
  }

  List<PropertyInfo> _getFreezedProperties(InterfaceElement element) {
    final properties = <PropertyInfo>[];
    final constructor = element.unnamedConstructor;

    if (constructor == null) {
      throw StateError(
        'No unnamed constructor found for freezed class ${element.displayName}',
      );
    }

    // Use Element API to get parameters
    for (var parameter in constructor.formalParameters) {
      // Check for Default annotation
      DartObject? defaultValueAnnotation;
      for (final anno in parameter.metadata.annotations) {
        final value = anno.computeConstantValue();
        if (value != null && value.type != null) {
          if (_typeCheckers.defaultChecker.isExactlyType(value.type!)) {
            defaultValueAnnotation = value;
            break;
          }
        }
      }

      final defaultValue =
          defaultValueAnnotation != null
              ? ConstantReader(
                defaultValueAnnotation,
              ).read('defaultValue').objectValue
              : null;

      // Get documentation from the parameter
      final description =
          parameter.documentationComment
              ?.replaceAll(
                RegExp(r'^\s*\/\*\*\s*|\s*\*\/\s*$|\s*\*\s?', multiLine: true),
                '',
              )
              .trim();

      properties.add(
        PropertyInfo(
          parameter.displayName,
          parameter.type,
          isRequired: parameter.isRequired,
          defaultValue: defaultValue,
          description: description,
        ),
      );
    }

    return properties;
  }
}

class TypeCheckers {
  // JSON annotation types - using exact URL matching
  final jsonKeyChecker = const TypeChecker.fromUrl(
    'package:json_annotation/json_annotation.dart#JsonKey',
  );
  final jsonSerializableChecker = const TypeChecker.fromUrl(
    'package:json_annotation/json_annotation.dart#JsonSerializable',
  );

  // Core Dart types
  final stringChecker = const TypeChecker.fromUrl('dart:core#String');
  final intChecker = const TypeChecker.fromUrl('dart:core#int');
  final doubleChecker = const TypeChecker.fromUrl('dart:core#double');
  final boolChecker = const TypeChecker.fromUrl('dart:core#bool');
  final iterableChecker = const TypeChecker.fromUrl('dart:core#Iterable');
  final mapChecker = const TypeChecker.fromUrl('dart:core#Map');
  final dateTimeChecker = const TypeChecker.fromUrl('dart:core#DateTime');
  final uriChecker = const TypeChecker.fromUrl('dart:core#Uri');
  final objectChecker = const TypeChecker.fromUrl('dart:core#Object');

  // Local annotation types - using exact URL matching
  final jsonSchemaChecker = const TypeChecker.fromUrl(
    'package:soti_schema_plus/annotations.dart#SotiJsonSchema',
  );
  final descriptionChecker = const TypeChecker.fromUrl(
    'package:soti_schema_plus/annotations.dart#Description',
  );
  final defaultValueChecker = const TypeChecker.fromUrl(
    'package:soti_schema_plus/annotations.dart#DefaultValue',
  );

  // Freezed annotation types - using exact URL matching
  final freezedChecker = const TypeChecker.fromUrl(
    'package:freezed_annotation/freezed_annotation.dart#Freezed',
  );
  final defaultChecker = const TypeChecker.fromUrl(
    'package:freezed_annotation/freezed_annotation.dart#Default',
  );

  const TypeCheckers();
}

Builder sotiSchemaBuilder(BuilderOptions options) =>
    SharedPartBuilder([SotiSchemaGenerator()], 'soti_schema');
