import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:source_gen/source_gen.dart';

import '../spec/spec.dart';
import '../utils/string_utils.dart';
import '../utils/type_checkers.dart';
import 'extractor.dart';
import 'spec_builder.dart';

/// Extracts schema information from plain Dart classes.
///
/// This extractor handles classes that are not annotated with
/// @freezed or @JsonSerializable, but have @Spectra annotation.
class PlainDartExtractor implements Extractor {
  @override
  bool canExtract(InterfaceElement element) {
    // Can extract if it has @Spectra but not @freezed or @JsonSerializable
    return !TypeCheckers.freezed.hasAnnotationOf(element) &&
        !TypeCheckers.jsonSerializable.hasAnnotationOf(element);
  }

  @override
  ExtractionResult extract(InterfaceElement element) {
    final builder = SpecBuilder();
    final properties = <String, PropertySpec>{};
    final required = <String>[];

    for (final field in element.fields) {
      if (field.isStatic || !field.isPublic) continue;
      if (field.isSynthetic) continue;

      // Check for @Ignore
      if (TypeCheckers.ignore.hasAnnotationOf(field)) continue;

      final fieldMeta = _extractFieldMetadata(field);
      final propertyName = fieldMeta.name ?? field.name;

      // Determine if required based on nullability and final
      final isNullable =
          field.type.nullabilitySuffix == NullabilitySuffix.question;
      final isRequired = field.isFinal && !isNullable;

      final typeSpec = builder.buildFromType(field.type, fieldMeta: fieldMeta);

      properties[propertyName] = PropertySpec(
        name: field.name,
        jsonName: fieldMeta.name,
        type: typeSpec,
        required: isRequired,
      );

      if (isRequired) {
        required.add(propertyName);
      }
    }

    final spec = ObjectSpec(
      name: element.name,
      properties: properties,
      required: required,
      description: cleanDocComment(element.documentationComment),
    );

    return ExtractionResult(
      spec: spec,
      definitions: builder.definitions,
    );
  }

  FieldMetadata _extractFieldMetadata(FieldElement field) {
    // Check for @Field annotation
    final fieldAnnotation = TypeCheckers.field.firstAnnotationOf(field);
    if (fieldAnnotation != null) {
      return FieldMetadata.fromAnnotation(ConstantReader(fieldAnnotation));
    }

    return FieldMetadata(
      description: cleanDocComment(field.documentationComment),
    );
  }
}
