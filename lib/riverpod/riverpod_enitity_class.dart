
import 'package:flutter/foundation.dart';

String generateEntityClass(
  String className,
  Map<String, dynamic> json,
  String? fileName, {
  bool isRoot = true,
}) {
  final buffer = StringBuffer();

  if (isRoot) {
    buffer.writeln("import 'package:freezed_annotation/freezed_annotation.dart';");
    buffer.writeln();

    if (fileName != null && fileName.isNotEmpty) {
      buffer.writeln("part '${fileName}_entity.freezed.dart';");
      buffer.writeln("part '${fileName}_entity.g.dart';");
      buffer.writeln();
    } else {
      debugPrint("⚠️ Warning: fileName is missing or empty for root entity class.");
    }
  }

  buffer.writeln('@freezed');
  buffer.writeln('abstract class $className with _\$$className {');
  buffer.writeln('  const $className._();');
  buffer.writeln('  const factory $className({');

  final nestedClassesBuffer = StringBuffer();

  json.forEach((key, value) {
    final fieldName = _camelCase(key);
    final fieldType = _getEntityType(value, key);

    if (value is Map<String, dynamic>) {
      final nestedClassName = '${_capitalizeToPascalCase(key)}Entity';
      buffer.writeln('    $nestedClassName? $fieldName,');
      nestedClassesBuffer.writeln(generateEntityClass(nestedClassName, value, fileName, isRoot: false));
    } else if (value is List && value.isNotEmpty && value.first is Map<String, dynamic>) {
      final nestedClassName = '${_capitalizeToPascalCase(_singularize(key))}Entity';
      buffer.writeln('    List<$nestedClassName>? $fieldName,');
      nestedClassesBuffer.writeln(generateEntityClass(nestedClassName, value.first, fileName, isRoot: false));
    } else {
      buffer.writeln('    $fieldType? $fieldName,');
    }
  });

  buffer.writeln('  }) = _$className;');
  buffer.writeln();
  buffer.writeln('  factory $className.fromJson(Map<String, dynamic> json) => _\$${className}FromJson(json);');
  buffer.writeln('}');
  buffer.writeln();

  buffer.write(nestedClassesBuffer.toString());

  return buffer.toString();
}

/// Infers the Dart type from a JSON value.
String _getEntityType(dynamic value, String key) {
  if (value is int) return 'int';
  if (value is double) return 'double';
  if (value is bool) return 'bool';
  if (value is String) return 'String';

  if (value is List) {
    if (value.isNotEmpty && value.first is Map<String, dynamic>) {
      return 'List<${_capitalizeToPascalCase(_singularize(key))}Entity>';
    }
    return 'List<dynamic>';
  }

  if (value is Map<String, dynamic>) {
    return '${_capitalizeToPascalCase(key)}Entity';
  }

  return 'dynamic';
}

/// Converts a snake_case or camelCase string to PascalCase.
String _capitalizeToPascalCase(String text) {
  if (text.isEmpty) return '';
  return text.split(RegExp(r'[_\s]')).map((word) {
    if (word.isEmpty) return '';
    return word[0].toUpperCase() + word.substring(1);
  }).join();
}

/// Converts a string to camelCase.
String _camelCase(String text) {
  final pascal = _capitalizeToPascalCase(text);
  return pascal.isEmpty ? '' : pascal[0].toLowerCase() + pascal.substring(1);
}

/// Basic singularization for plural words (customize this if needed).
String _singularize(String word) {
  if (word.endsWith('ies')) {
    return word.replaceAll(RegExp(r'ies$'), 'y');
  } else if (word.endsWith('s') && !word.endsWith('ss')) {
    return word.substring(0, word.length - 1);
  }
  return word;
}
