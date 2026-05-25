String riverpodModelGenerateClass(
  String className,
  Map<String, dynamic> json,
  String fileName, {
  bool isNested = false,
  Set<String>? generatedClasses,
}) {
  final StringBuffer buffer = StringBuffer();

  // ✅ FIX 1: shared Set to prevent duplicate nested class generation
  generatedClasses ??= <String>{};
  final modelClassName = '${className}Model';

  if (generatedClasses.contains(modelClassName)) {
    return ''; // already generated — skip
  }
  generatedClasses.add(modelClassName);

  // ─── Imports (root only) ──────────────────────────────────────
  if (!isNested) {
    buffer.writeln(
        "import 'package:freezed_annotation/freezed_annotation.dart';\n");
    // ✅ FIX: snake_case file name
    final snakeFile =
        fileName.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    buffer.writeln(
        "import '../../domain/entity/${snakeFile}_entity.dart';");
    buffer.writeln("part '${snakeFile}_model.freezed.dart';");
    buffer.writeln("part '${snakeFile}_model.g.dart';\n");
  }

  // ─── Freezed class ────────────────────────────────────────────
  buffer.writeln('@freezed');
  buffer.writeln(
      'abstract class $modelClassName with _\$$modelClassName {');
  buffer.writeln('  const $modelClassName._();');
  buffer.writeln('  const factory $modelClassName({');

  final nestedClassesBuffer = StringBuffer();

  json.forEach((key, value) {
    // ✅ FIX 2: camelCase field names + @JsonKey when key differs
    final fieldName = _modelCamelCase(key);
    final needsJsonKey = fieldName != key;

    if (value is Map<String, dynamic>) {
      final nestedModelClass =
          '${_capitalizePascal(key)}Model';
      if (needsJsonKey) {
        buffer.writeln("    @JsonKey(name: '$key')");
      }
      buffer.writeln('    $nestedModelClass? $fieldName,');

      nestedClassesBuffer.write(riverpodModelGenerateClass(
        _capitalizePascal(key),
        value,
        fileName,
        isNested: true,
        generatedClasses: generatedClasses,
      ));
    } else if (value is List &&
        value.isNotEmpty &&
        value.first is Map<String, dynamic>) {
      final singularKey = _singularize(key);
      final nestedModelClass =
          '${_capitalizePascal(singularKey)}Model';
      if (needsJsonKey) {
        buffer.writeln("    @JsonKey(name: '$key')");
      }
      // ✅ FIX 3: @Default([]) for list fields
      buffer.writeln(
          '    @Default([]) List<$nestedModelClass> $fieldName,');

      nestedClassesBuffer.write(riverpodModelGenerateClass(
        _capitalizePascal(singularKey),
        value.first as Map<String, dynamic>,
        fileName,
        isNested: true,
        generatedClasses: generatedClasses,
      ));
    } else {
      final type = _getDartType(value, key);
      if (needsJsonKey) {
        buffer.writeln("    @JsonKey(name: '$key')");
      }
      buffer.writeln('    $type? $fieldName,');
    }
  });

  buffer.writeln('  }) = _$modelClassName;\n');

  // ✅ FIX: fromJson
  buffer.writeln(
      '  factory $modelClassName.fromJson(Map<String, dynamic> json) =>');
  buffer.writeln('      _\$${modelClassName}FromJson(json);');
  buffer.writeln('}');
  buffer.writeln();

  // ─── ✅ FIX 4: toDomain() as extension outside the Freezed class ──
  // Freezed does NOT allow custom methods inside the factory body.
  // Use extension method pattern instead.
  buffer.writeln(
      'extension ${modelClassName}ToDomain on $modelClassName {');
  buffer.writeln(
      '  ${className}Entity toDomain() => ${className}Entity(');

  json.forEach((key, value) {
    final fieldName = _modelCamelCase(key);
    if (value is Map<String, dynamic>) {
      buffer.writeln('    $fieldName: $fieldName?.toDomain(),');
    } else if (value is List &&
        value.isNotEmpty &&
        value.first is Map<String, dynamic>) {
      // ✅ FIX: @Default([]) means list is never null — no ?
      buffer.writeln(
          '    $fieldName: $fieldName.map((e) => e.toDomain()).toList(),');
    } else {
      buffer.writeln('    $fieldName: $fieldName,');
    }
  });

  buffer.writeln('  );');
  buffer.writeln('}');
  buffer.writeln();

  // ─── Nested classes ───────────────────────────────────────────
  buffer.write(nestedClassesBuffer.toString());

  return buffer.toString();
}

// ─── Type inference ───────────────────────────────────────────────
String _getDartType(dynamic value, String key) {
  // ✅ FIX 5: null guard
  if (value == null) return 'dynamic';
  if (value is int) return 'int';
  if (value is double) return 'double';
  if (value is String) return 'String';
  if (value is bool) return 'bool';

  if (value is List) {
    if (value.isEmpty) return 'List<dynamic>';
    // ✅ FIX 6: typed list inference
    if (value.first is Map<String, dynamic>) {
      return 'List<${_capitalizePascal(_singularize(key))}Model>';
    }
    if (value.first is String) return 'List<String>';
    if (value.first is int) return 'List<int>';
    if (value.first is double) return 'List<double>';
    if (value.first is bool) return 'List<bool>';
    return 'List<dynamic>';
  }

  if (value is Map<String, dynamic>) {
    return '${_capitalizePascal(key)}Model';
  }

  return 'dynamic';
}

// ─── Helpers ──────────────────────────────────────────────────────
String _capitalizePascal(String text) {
  if (text.isEmpty) return '';
  return text
      .split(RegExp(r'[_\s]+'))
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join();
}

/// Converts snake_case / PascalCase key to camelCase field name
String _modelCamelCase(String text) {
  final pascal = _capitalizePascal(text);
  return pascal.isEmpty ? '' : pascal[0].toLowerCase() + pascal.substring(1);
}

String _singularize(String text) {
  if (text.endsWith('ies')) {
    return '${text.substring(0, text.length - 3)}y';
  }
  if (text.endsWith('s') && text.length > 1) {
    return text.substring(0, text.length - 1);
  }
  return text;
}