import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:source_gen/source_gen.dart';

import '../spec/spec.dart';
import '../utils/string_utils.dart';
import '../utils/type_checkers.dart';
import 'extractor.dart';
import 'spec_builder.dart';

/// Extracts schema information from JsonSerializable classes.
class JsonSerializableExtractor implements Extractor {
  @override
  bool canExtract(InterfaceElement element) {
    return TypeCheckers.jsonSerializable.hasAnnotationOf(element);
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

      // Check @JsonKey for includeFromJson/includeToJson
      final jsonKeyAnnotation = TypeCheckers.jsonKey.firstAnnotationOf(field);
      if (jsonKeyAnnotation != null) {
        final reader = ConstantReader(jsonKeyAnnotation);
        final includeFromJson = reader.peek('includeFromJson')?.boolValue ?? true;
        final includeToJson = reader.peek('includeToJson')?.boolValue ?? true;
        if (!includeFromJson || !includeToJson) continue;
      }

      final fieldMeta = _extractFieldMetadata(field);
      final propertyName = fieldMeta.name ?? field.name;

      // Determine if required
      final hasDefaultValue = jsonKeyAnnotation != null &&
          ConstantReader(jsonKeyAnnotation).peek('defaultValue')?.isNull ==
              false;
      final isNullable =
          field.type.nullabilitySuffix == NullabilitySuffix.question;
      final isRequired = field.isFinal && !isNullable && !hasDefaultValue;

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

    // Check for @JsonKey annotation
    final jsonKeyAnnotation = TypeCheckers.jsonKey.firstAnnotationOf(field);
    if (jsonKeyAnnotation != null) {
      final reader = ConstantReader(jsonKeyAnnotation);
      final nameValue = reader.peek('name');
      return FieldMetadata(
        name: nameValue?.isNull == false ? nameValue?.stringValue : null,
        description: cleanDocComment(field.documentationComment),
      );
    }

    return FieldMetadata(
      description: cleanDocComment(field.documentationComment),
    );
  }
}
