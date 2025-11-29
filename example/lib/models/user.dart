import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:spectra/spectra.dart';

part 'user.freezed.dart';
part 'user.g.dart';

/// A user in the system.
@freezed
@Spectra(
  title: 'User',
  description: 'Represents a user account in the system',
)
class User with _$User {
  const factory User({
    /// The user's unique identifier.
    required String id,

    /// The user's display name.
    @Field(minLength: 1, maxLength: 100) required String name,

    /// The user's email address.
    @Field(format: StringFormat.email) required String email,

    /// The user's age in years.
    @Field(minimum: 0, maximum: 150) int? age,

    /// User's profile tags.
    @Field(maxItems: 10, uniqueItems: true) @Default([]) List<String> tags,

    /// Whether the user account is active.
    @Default(true) bool isActive,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  /// Get the JSON Schema for User as a string.
  @spectraOutput
  static String get jsonSchema => _$UserJsonSchema;

  /// Get the JSON Schema for User as a Map.
  @spectraOutput
  static Map<String, dynamic> get jsonSchemaMap => _$UserJsonSchemaMap;
}
