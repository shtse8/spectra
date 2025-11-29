import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:source_gen/source_gen.dart';

import '../annotations/annotations.dart';

/// Type checkers for identifying and working with Dart types.
class TypeCheckers {
  // Primitive types
  static const string = TypeChecker.fromRuntime(String);
  static const int_ = TypeChecker.fromRuntime(int);
  static const double_ = TypeChecker.fromRuntime(double);
  static const bool_ = TypeChecker.fromRuntime(bool);
  static const num_ = TypeChecker.fromRuntime(num);

  // Collection types
  static const iterable = TypeChecker.fromRuntime(Iterable);
  static const list = TypeChecker.fromRuntime(List);
  static const set = TypeChecker.fromRuntime(Set);
  static const map = TypeChecker.fromRuntime(Map);

  // Common types
  static const dateTime = TypeChecker.fromRuntime(DateTime);
  static const uri = TypeChecker.fromRuntime(Uri);
  static const duration = TypeChecker.fromRuntime(Duration);
  static const object = TypeChecker.fromRuntime(Object);
  static const dynamic_ = TypeChecker.fromRuntime(dynamic);

  // Annotations - Spectra
  static const spectra = TypeChecker.fromRuntime(Spectra);
  static const field = TypeChecker.fromRuntime(Field);
  static const ignore = TypeChecker.fromRuntime(Ignore);
  static const converter = TypeChecker.fromRuntime(Converter);
  static const spectraOutput = TypeChecker.fromRuntime(SpectraOutput);

  // Annotations - json_annotation
  static const jsonSerializable = TypeChecker.fromRuntime(JsonSerializable);
  static const jsonKey = TypeChecker.fromRuntime(JsonKey);
  static const jsonValue = TypeChecker.fromRuntime(JsonValue);

  // Annotations - freezed_annotation
  static const freezed = TypeChecker.fromRuntime(Freezed);
  static const freezedDefault = TypeChecker.fromRuntime(Default);

  const TypeCheckers._();
}
