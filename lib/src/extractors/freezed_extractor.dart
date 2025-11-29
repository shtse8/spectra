import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:source_gen/source_gen.dart';

import '../spec/spec.dart';
import '../utils/string_utils.dart';
import '../utils/type_checkers.dart';
import 'extractor.dart';
import 'spec_builder.dart';

/// Extracts schema information from Freezed classes.
class FreezedExtractor implements Extractor {
  @override
  bool canExtract(InterfaceElement element) {
    return TypeCheckers.freezed.hasAnnotationOf(element);
  }

  @override
  ExtractionResult extract(InterfaceElement element) {
    final builder = SpecBuilder();

    // Check if this is a union type (has multiple factory constructors)
    final factories = _getFactoryConstructors(element);

    TypeSpec spec;
    if (factories.length > 1) {
      // Union type
      spec = _extractUnion(element, factories, builder);
    } else {
      // Single type
      spec = _extractSingle(element, builder);
    }

    return ExtractionResult(
      spec: spec,
      definitions: builder.definitions,
    );
  }

  List<ConstructorElement> _getFactoryConstructors(InterfaceElement element) {
    return element.constructors
        .where((c) => c.isFactory && !c.isPrivate && c.name != 'fromJson')
        .toList();
  }

  ObjectSpec _extractSingle(InterfaceElement element, SpecBuilder builder) {
    // Find the primary constructor (unnamed or first factory)
    final constructor = element.unnamedConstructor ??
        _getFactoryConstructors(element).firstOrNull;

    if (constructor == null) {
      return ObjectSpec(
        name: element.name,
        properties: const {},
        description: cleanDocComment(element.documentationComment),
      );
    }

    return _extractFromConstructor(
      element.name,
      constructor,
      builder,
      description: cleanDocComment(element.documentationComment),
    );
  }

  UnionSpec _extractUnion(
    InterfaceElement element,
    List<ConstructorElement> factories,
    SpecBuilder builder,
  ) {
    final variants = <ObjectSpec>[];

    for (final factory in factories) {
      final variantName =
          factory.name.isEmpty ? element.name : '${element.name}.${factory.name}';

      final variant = _extractFromConstructor(
        variantName,
        factory,
        builder,
        discriminatorValue: factory.name.isEmpty ? 'default' : factory.name,
      );
      variants.add(variant);
    }

    return UnionSpec(
      name: element.name,
      discriminator: 'runtimeType',
      variants: variants,
      description: cleanDocComment(element.documentationComment),
    );
  }

  ObjectSpec _extractFromConstructor(
    String name,
    ConstructorElement constructor,
    SpecBuilder builder, {
    String? description,
    String? discriminatorValue,
  }) {
    final properties = <String, PropertySpec>{};
    final required = <String>[];

    for (final param in constructor.parameters) {
      // Check for @Ignore
      if (TypeCheckers.ignore.hasAnnotationOf(param)) continue;

      final fieldMeta = _extractParameterMetadata(param);
      final propertyName = fieldMeta.name ?? param.name;

      // Check for @Default annotation
      final hasDefault = TypeCheckers.freezedDefault.hasAnnotationOf(param);
      final isOptional = param.isOptional || hasDefault;
      final isNullable =
          param.type.nullabilitySuffix == NullabilitySuffix.question;
      final isRequired = !isOptional && !isNullable;

      final typeSpec = builder.buildFromType(param.type, fieldMeta: fieldMeta);

      properties[propertyName] = PropertySpec(
        name: param.name,
        jsonName: fieldMeta.name,
        type: typeSpec,
        required: isRequired,
      );

      if (isRequired) {
        required.add(propertyName);
      }
    }

    return ObjectSpec(
      name: name,
      properties: properties,
      required: required,
      description: description,
    );
  }

  FieldMetadata _extractParameterMetadata(ParameterElement param) {
    // Check for @Field annotation
    final fieldAnnotation = TypeCheckers.field.firstAnnotationOf(param);
    if (fieldAnnotation != null) {
      return FieldMetadata.fromAnnotation(ConstantReader(fieldAnnotation));
    }

    // Check for @JsonKey annotation
    final jsonKeyAnnotation = TypeCheckers.jsonKey.firstAnnotationOf(param);
    if (jsonKeyAnnotation != null) {
      final reader = ConstantReader(jsonKeyAnnotation);
      final nameValue = reader.peek('name');
      return FieldMetadata(
        name: nameValue?.isNull == false ? nameValue?.stringValue : null,
        description: cleanDocComment(param.documentationComment),
      );
    }

    return FieldMetadata(
      description: cleanDocComment(param.documentationComment),
    );
  }
}
