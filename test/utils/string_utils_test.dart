import 'package:spectra_schema/src/utils/string_utils.dart';
import 'package:test/test.dart';

void main() {
  group('toCamelCase', () {
    test('empty string', () {
      expect(toCamelCase(''), '');
    });

    test('single word', () {
      expect(toCamelCase('hello'), 'hello');
    });

    test('snake_case to camelCase', () {
      expect(toCamelCase('hello_world'), 'helloWorld');
    });

    test('kebab-case to camelCase', () {
      expect(toCamelCase('hello-world'), 'helloWorld');
    });

    test('space separated to camelCase', () {
      expect(toCamelCase('hello world'), 'helloWorld');
    });

    test('multiple underscores', () {
      expect(toCamelCase('hello__world'), 'helloWorld');
    });

    test('mixed separators', () {
      expect(toCamelCase('hello_world-test case'), 'helloWorldTestCase');
    });
  });

  group('toPascalCase', () {
    test('empty string', () {
      expect(toPascalCase(''), '');
    });

    test('single word', () {
      expect(toPascalCase('hello'), 'Hello');
    });

    test('snake_case to PascalCase', () {
      expect(toPascalCase('hello_world'), 'HelloWorld');
    });

    test('kebab-case to PascalCase', () {
      expect(toPascalCase('hello-world'), 'HelloWorld');
    });

    test('space separated to PascalCase', () {
      expect(toPascalCase('hello world'), 'HelloWorld');
    });
  });

  group('toSnakeCase', () {
    test('empty string', () {
      expect(toSnakeCase(''), '');
    });

    test('single lowercase word', () {
      expect(toSnakeCase('hello'), 'hello');
    });

    test('camelCase to snake_case', () {
      expect(toSnakeCase('helloWorld'), 'hello_world');
    });

    test('PascalCase to snake_case', () {
      expect(toSnakeCase('HelloWorld'), 'hello_world');
    });

    test('multiple capitals', () {
      expect(toSnakeCase('helloWorldTest'), 'hello_world_test');
    });

    test('already snake_case', () {
      expect(toSnakeCase('hello_world'), 'hello_world');
    });

    test('consecutive capitals', () {
      expect(toSnakeCase('getHTTPResponse'), 'get_h_t_t_p_response');
    });
  });

  group('capitalize', () {
    test('empty string', () {
      expect(capitalize(''), '');
    });

    test('single letter', () {
      expect(capitalize('a'), 'A');
    });

    test('lowercase word', () {
      expect(capitalize('hello'), 'Hello');
    });

    test('uppercase word', () {
      expect(capitalize('HELLO'), 'Hello');
    });

    test('mixed case', () {
      expect(capitalize('hELLO'), 'Hello');
    });
  });

  group('cleanDocComment', () {
    test('null input', () {
      expect(cleanDocComment(null), isNull);
    });

    test('empty string', () {
      expect(cleanDocComment(''), isNull);
    });

    test('triple slash comment', () {
      expect(cleanDocComment('/// This is a comment'), 'This is a comment');
    });

    test('multi-line triple slash', () {
      expect(
        cleanDocComment('/// Line 1\n/// Line 2'),
        'Line 1\nLine 2',
      );
    });

    test('block comment', () {
      expect(
        cleanDocComment('/** This is a comment */'),
        'This is a comment',
      );
    });

    test('multi-line block comment', () {
      expect(
        cleanDocComment('/**\n * Line 1\n * Line 2\n */'),
        'Line 1\nLine 2',
      );
    });

    test('comment with asterisk lines', () {
      expect(
        cleanDocComment('/**\n* First line\n* Second line\n*/'),
        'First line\nSecond line',
      );
    });

    test('plain text (no comment markers)', () {
      expect(cleanDocComment('Just plain text'), 'Just plain text');
    });
  });
}
