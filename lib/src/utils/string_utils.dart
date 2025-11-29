/// Utility functions for string manipulation.
library;

/// Converts a string to camelCase.
String toCamelCase(String input) {
  if (input.isEmpty) return input;

  final words = input.split(RegExp(r'[_\-\s]+'));
  if (words.isEmpty) return input;

  return words.first.toLowerCase() +
      words.skip(1).map((word) => capitalize(word)).join();
}

/// Converts a string to PascalCase.
String toPascalCase(String input) {
  if (input.isEmpty) return input;

  final words = input.split(RegExp(r'[_\-\s]+'));
  return words.map((word) => capitalize(word)).join();
}

/// Converts a string to snake_case.
String toSnakeCase(String input) {
  if (input.isEmpty) return input;

  return input
      .replaceAllMapped(
        RegExp(r'([A-Z])'),
        (match) => '_${match.group(1)!.toLowerCase()}',
      )
      .replaceAll(RegExp(r'^_'), '')
      .replaceAll(RegExp(r'_+'), '_')
      .toLowerCase();
}

/// Capitalizes the first letter of a string.
String capitalize(String input) {
  if (input.isEmpty) return input;
  return input[0].toUpperCase() + input.substring(1).toLowerCase();
}

/// Extracts clean description from doc comments.
String? cleanDocComment(String? docComment) {
  if (docComment == null || docComment.isEmpty) return null;

  return docComment
      .replaceAll(RegExp(r'^\s*\/\*\*\s*', multiLine: true), '')
      .replaceAll(RegExp(r'\s*\*\/\s*$', multiLine: true), '')
      .replaceAll(RegExp(r'^\s*\*\s?', multiLine: true), '')
      .replaceAll(RegExp(r'^\s*\/\/\/\s?', multiLine: true), '')
      .trim();
}
