import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:spectra_schema/spectra.dart';

part 'result.freezed.dart';
part 'result.g.dart';

/// A result type representing success or failure.
///
/// This demonstrates Spectra's support for Freezed union types.
@freezed
@Spectra(
  title: 'ApiResult',
  description: 'Represents the result of an API operation',
)
sealed class ApiResult<T> with _$ApiResult<T> {
  /// Successful result with data.
  const factory ApiResult.success({
    required T data,
    String? message,
  }) = ApiSuccess<T>;

  /// Failed result with error details.
  const factory ApiResult.failure({
    required String error,
    int? errorCode,
    Map<String, dynamic>? details,
  }) = ApiFailure<T>;

  factory ApiResult.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) =>
      _$ApiResultFromJson(json, fromJsonT);

  @spectraOutput
  static String get jsonSchema => _$ApiResultJsonSchema;
}
