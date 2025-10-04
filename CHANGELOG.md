## 1.3.0

- Fix deprecated analyzer API usage: migrate from Element2 to Element API
- Update to use current analyzer package APIs (metadata.annotations, etc.)

## 1.2.0

- Make sure builder generates schema properly for freezed and json_serializer.
- Remove conflict with JsonSchema
- Fix annotation detection: use `SotiJsonSchema` and improve `@JsonSerializable`
  detection.
- Enforce strict mode: classes with `@SotiSchema()` must also have
  `@JsonSerializable()` or `@freezed`.
- Fix code generation quoting using raw triple-quoted strings to avoid formatter
  errors.
- Update examples: add missing `part` directives, pretty-print example output.
- Documentation updates: configuration, troubleshooting, and run instructions.

## 1.1.0

- Cloned from original repo
- Updated to the latest versions of dependent packages

## 1.0.0

- Initial version.
