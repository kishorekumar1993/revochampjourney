
/// Generates Equatable-based entity classes from a JSON map.
/// Prevents duplicate nested class generation.
String generateEquatableEntityClass(
  String className,
  Map<String, dynamic> json,
  String? fileName, {
  bool isRoot = true,
  Set<String>? generatedClasses,
}) {
  // Shared set to avoid generating the same class twice.
  generatedClasses ??= <String>{};
  if (generatedClasses.contains(className)) {
    return '';
  }
  generatedClasses.add(className);

  final buffer = StringBuffer();

  // Add imports only for the root class.
  if (isRoot) {
    buffer.writeln("import 'package:equatable/equatable.dart';");
    buffer.writeln("import 'package:meta/meta.dart';");
    buffer.writeln();
  }

  buffer.writeln('@immutable');
  buffer.writeln('class $className extends Equatable {');
  buffer.writeln('  const $className({');

  final nestedClassesBuffer = StringBuffer();

  // Process fields: generate constructor parameters and nested classes.
  json.forEach((key, value) {
    final fieldName = _camelCase(key);
    _getEquatableEntityType(value, key);

    // For nested objects/lists, generate the nested class code.
    if (value is Map<String, dynamic>) {
      final nestedClassName = '${_capitalizeToPascalCase(key)}Entity';
      nestedClassesBuffer.writeln(
        generateEquatableEntityClass(
          nestedClassName,
          value,
          fileName,
          isRoot: false,
          generatedClasses: generatedClasses,
        ),
      );
    } else if (value is List && value.isNotEmpty && value.first is Map<String, dynamic>) {
      final nestedClassName = '${_capitalizeToPascalCase(_singularize(key))}Entity';
      nestedClassesBuffer.writeln(
        generateEquatableEntityClass(
          nestedClassName,
          value.first,
          fileName,
          isRoot: false,
          generatedClasses: generatedClasses,
        ),
      );
    }

    // All fields are required (non‑nullable).
    buffer.writeln('    required this.$fieldName,');
  });

  buffer.writeln('  });');
  buffer.writeln();

  // Declare fields.
  json.forEach((key, value) {
    final fieldName = _camelCase(key);
    final fieldType = _getEquatableEntityType(value, key);
    buffer.writeln('  final $fieldType $fieldName;');
  });

  buffer.writeln();

  // copyWith method.
  buffer.writeln('  $className copyWith({');
  json.forEach((key, value) {
    final fieldName = _camelCase(key);
    final fieldType = _getEquatableEntityType(value, key);
    buffer.writeln('    $fieldType? $fieldName,');
  });
  buffer.writeln('  }) {');
  buffer.writeln('    return $className(');
  json.forEach((key, _) {
    final fieldName = _camelCase(key);
    buffer.writeln('      $fieldName: $fieldName ?? this.$fieldName,');
  });
  buffer.writeln('    );');
  buffer.writeln('  }');
  buffer.writeln();

  // props.
  buffer.writeln('  @override');
  buffer.writeln('  List<Object?> get props => [');
  json.forEach((key, _) {
    buffer.writeln('        ${_camelCase(key)},');
  });
  buffer.writeln('      ];');
  buffer.writeln();

  // stringify.
  buffer.writeln('  @override');
  buffer.writeln('  bool get stringify => true;');

  buffer.writeln('}');
  buffer.writeln();

  // Append nested classes after the current one.
  buffer.write(nestedClassesBuffer.toString());

  return buffer.toString();
}

// ─── Helpers ────────────────────────────────────────────────

/// Infers the Dart type for Equatable fields (non‑nullable).
String _getEquatableEntityType(dynamic value, String key) {
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

/// Converts to PascalCase (e.g., "created_at" -> "CreatedAt").
String _capitalizeToPascalCase(String text) {
  if (text.isEmpty) return '';
  return text.split(RegExp(r'[_\s]')).map((word) {
    if (word.isEmpty) return '';
    return word[0].toUpperCase() + word.substring(1);
  }).join();
}

/// Converts to camelCase (e.g., "created_at" -> "createdAt").
String _camelCase(String text) {
  final pascal = _capitalizeToPascalCase(text);
  return pascal.isEmpty ? '' : pascal[0].toLowerCase() + pascal.substring(1);
}

/// Basic singularizer (e.g., "reactions" -> "reaction").
String _singularize(String word) {
  if (word.endsWith('ies')) {
    return word.replaceAll(RegExp(r'ies$'), 'y');
  } else if (word.endsWith('s') && !word.endsWith('ss')) {
    return word.substring(0, word.length - 1);
  }
  return word;
}