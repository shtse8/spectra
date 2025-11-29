import 'dart:async';
import 'dart:convert';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import '../annotations/annotations.dart';
import '../emitters/emitter.dart';
import '../emitters/json_schema_emitter.dart';
import '../emitters/openapi_emitter.dart';
import '../emitters/protobuf_emitter.dart';
import '../extractors/extractor.dart';
import '../extractors/freezed_extractor.dart';
import '../extractors/json_serializable_extractor.dart';
import '../extractors/plain_dart_extractor.dart';
import '../utils/type_checkers.dart';

/// Main generator for Spectra.
class SpectraGenerator extends GeneratorForAnnotation<Spectra> {
  /// Available extractors.
  final List<Extractor> extractors = [
    FreezedExtractor(),
    JsonSerializableExtractor(),
    PlainDartExtractor(),
  ];

  /// Available emitters by format.
  final Map<SpectraFormat, SpecEmitter> emitters = {
    SpectraFormat.jsonSchema: JsonSchemaEmitter(),
    SpectraFormat.openApi: OpenApiEmitter(),
    SpectraFormat.protobuf: ProtobufEmitter(),
  };

  @override
  FutureOr<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@Spectra can only be applied to classes.',
        element: element,
      );
    }

    // Find appropriate extractor
    final extractor = extractors.firstWhere(
      (e) => e.canExtract(element),
      orElse: () => PlainDartExtractor(),
    );

    // Extract type specification
    final result = extractor.extract(element);

    // Determine output formats
    final formats = _getRequestedFormats(annotation);

    // Find output targets
    final outputTargets = await _findOutputTargets(element, buildStep);

    // Generate output for each format
    final buffer = StringBuffer();

    for (final target in outputTargets) {
      final format = _determineFormatForTarget(target, formats);
      final emitter = emitters[format];

      if (emitter == null) continue;

      final context = EmitContext(
        definitions: result.definitions,
        isRoot: true,
      );

      final output = emitter.emit(result.spec, context: context);
      _writeOutput(buffer, target, output);
    }

    return buffer.toString();
  }

  Set<SpectraFormat> _getRequestedFormats(ConstantReader annotation) {
    final formatsValue = annotation.peek('formats');
    if (formatsValue == null || formatsValue.isNull) {
      return {SpectraFormat.jsonSchema};
    }

    final formats = <SpectraFormat>{};
    for (final item in formatsValue.setValue) {
      final index = item.getField('index')?.toIntValue();
      if (index != null && index < SpectraFormat.values.length) {
        formats.add(SpectraFormat.values[index]);
      }
    }

    return formats.isEmpty ? {SpectraFormat.jsonSchema} : formats;
  }

  Future<List<_OutputTarget>> _findOutputTargets(
    ClassElement element,
    BuildStep buildStep,
  ) async {
    final targets = <_OutputTarget>[];

    for (final accessor in element.accessors) {
      if (!accessor.isStatic || !accessor.isGetter) continue;
      if (!TypeCheckers.spectraOutput.hasAnnotationOf(accessor)) continue;

      final name = await _getRedirectedVariableName(accessor, buildStep);
      if (name == null) continue;

      targets.add(_OutputTarget(
        name: name,
        returnType: accessor.returnType,
      ));
    }

    // If no explicit targets, generate default
    if (targets.isEmpty) {
      targets.add(_OutputTarget(
        name: '_\$${element.name}Schema',
        returnType: element.library.typeProvider.stringType,
      ));
    }

    return targets;
  }

  SpectraFormat _determineFormatForTarget(
    _OutputTarget target,
    Set<SpectraFormat> requestedFormats,
  ) {
    // Infer format from variable name
    final name = target.name.toLowerCase();

    if (name.contains('openapi') || name.contains('oas')) {
      return SpectraFormat.openApi;
    }
    if (name.contains('proto')) {
      return SpectraFormat.protobuf;
    }

    // Default to first requested format
    return requestedFormats.first;
  }

  void _writeOutput(
    StringBuffer buffer,
    _OutputTarget target,
    dynamic output,
  ) {
    if (TypeCheckers.string.isExactlyType(target.returnType)) {
      // Output as JSON string
      final jsonString = output is String ? output : jsonEncode(output);
      buffer.writeln("const ${target.name} = r'''");
      buffer.writeln(jsonString);
      buffer.writeln("''';");
    } else if (_isMapStringDynamic(target.returnType)) {
      // Output as Map literal
      buffer.writeln('const ${target.name} = ${_generateMapLiteral(output as Map<String, dynamic>)};');
    } else {
      throw InvalidGenerationSourceError(
        'Output target must return String or Map<String, dynamic>.',
      );
    }
  }

  bool _isMapStringDynamic(DartType type) {
    if (type is ParameterizedType && TypeCheckers.map.isExactlyType(type)) {
      final typeArgs = type.typeArguments;
      return typeArgs.length == 2 &&
          TypeCheckers.string.isExactlyType(typeArgs[0]) &&
          typeArgs[1] is DynamicType;
    }
    return false;
  }

  String _generateMapLiteral(Map<String, dynamic> map) {
    return '<String, dynamic>${_convertMapToString(map)}';
  }

  String _convertMapToString(Map<String, dynamic> map) {
    final entries = map.entries
        .map((e) => '${_escapeKey(e.key)}: ${_convertValueToString(e.value)}')
        .join(', ');
    return '{$entries}';
  }

  String _escapeKey(String key) {
    return "r'$key'";
  }

  String _convertValueToString(dynamic value) {
    if (value is Map<String, dynamic>) {
      return _convertMapToString(value);
    } else if (value is List) {
      return _convertListToString(value);
    } else if (value is String) {
      return "r'$value'";
    } else if (value is bool || value is num) {
      return value.toString();
    } else {
      return "r'$value'";
    }
  }

  String _convertListToString(List list) {
    return '[${list.map(_convertValueToString).join(', ')}]';
  }

  Future<String?> _getRedirectedVariableName(
    PropertyAccessorElement getter,
    BuildStep buildStep,
  ) async {
    try {
      final parsedLibrary = await _getParsedLibrary(getter, buildStep);
      final node = _findGetterDeclaration(parsedLibrary, getter);
      return node != null ? _extractGetterBody(node) : null;
    } catch (_) {
      return null;
    }
  }

  Future<ParsedLibraryResult> _getParsedLibrary(
    Element element,
    BuildStep buildStep,
  ) async {
    final assetId = buildStep.inputId;
    final resolver = buildStep.resolver;
    final library = await resolver.libraryFor(assetId);
    final parsedLibrary =
        library.session.getParsedLibraryByElement(element.library!);
    if (parsedLibrary is! ParsedLibraryResult) {
      throw InvalidGenerationSourceError(
        'Failed to parse library for ${element.displayName}',
      );
    }
    return parsedLibrary;
  }

  MethodDeclaration? _findGetterDeclaration(
    ParsedLibraryResult parsedLibrary,
    PropertyAccessorElement getter,
  ) {
    final result = parsedLibrary.getElementDeclaration(getter);
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

class _OutputTarget {
  final String name;
  final DartType returnType;

  const _OutputTarget({
    required this.name,
    required this.returnType,
  });
}
