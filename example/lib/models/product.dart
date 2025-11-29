import 'package:json_annotation/json_annotation.dart';
import 'package:spectra/spectra.dart';

part 'product.g.dart';

/// Product status enumeration.
enum ProductStatus {
  @JsonValue('DRAFT')
  draft,
  @JsonValue('ACTIVE')
  active,
  @JsonValue('DISCONTINUED')
  discontinued,
}

/// A product in the catalog.
@JsonSerializable()
@Spectra(
  title: 'Product',
  description: 'A product available in the catalog',
  additionalProperties: false,
)
class Product {
  /// Unique product identifier.
  final String id;

  /// Product name.
  @Field(minLength: 1, maxLength: 200)
  final String name;

  /// Product description.
  @Field(description: 'Detailed product description')
  final String? description;

  /// Price in cents.
  @Field(minimum: 0)
  final int priceInCents;

  /// Current stock quantity.
  @Field(minimum: 0)
  final int stock;

  /// Product status.
  final ProductStatus status;

  /// Product categories.
  @Field(minItems: 1, maxItems: 5)
  final List<String> categories;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.priceInCents,
    this.stock = 0,
    this.status = ProductStatus.draft,
    required this.categories,
  });

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
  Map<String, dynamic> toJson() => _$ProductToJson(this);

  @spectraOutput
  static String get jsonSchema => _$ProductJsonSchema;
}
