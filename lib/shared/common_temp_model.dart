String riverpodModelGenerateClass(
  String className,
  Map<String, dynamic> json,
  String fileName, {
  bool isNested = false,
  Set<String>? generatedClasses,
}) {
  final StringBuffer buffer = StringBuffer();
  generatedClasses ??= <String>{};
  final modelClassName = '${className}Model';

  if (generatedClasses.contains(modelClassName)) {
    return '';
  }
  generatedClasses.add(modelClassName);

  if (!isNested) {
    final snakeFile = fileName.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    buffer.writeln("import '../../domain/entity/${snakeFile}_entity.dart';");
    buffer.writeln();
  }

  buffer.writeln('class $modelClassName {');

  // Fields – all nullable (type already includes ?)
  final nestedClassesBuffer = StringBuffer();
  json.forEach((key, value) {
    final fieldName = _modelCamelCase(key);
    final type = _getDartType(value, key); // already returns e.g. int? / String?
    buffer.writeln('  final $type $fieldName;'); // NO extra ? here
  });
  buffer.writeln();

  // Constructor – parameters are optional (implicitly null)
  buffer.writeln('  $modelClassName({');
  json.forEach((key, value) {
    final fieldName = _modelCamelCase(key);
    buffer.writeln('    this.$fieldName,');
  });
  buffer.writeln('  });');
  buffer.writeln();

  // fromJson
  buffer.writeln('  factory $modelClassName.fromJson(Map<String, dynamic> json) {');
  buffer.writeln('    return $modelClassName(');
  json.forEach((key, value) {
    final fieldName = _modelCamelCase(key);
    final rawKey = key;
    if (value is Map<String, dynamic>) {
      buffer.writeln(
          "      $fieldName: json['$rawKey'] != null ? ${_capitalizePascal(key)}Model.fromJson(json['$rawKey']) : null,");
    } else if (value is List && value.isNotEmpty && value.first is Map<String, dynamic>) {
      final singular = _capitalizePascal(_singularize(key));
      buffer.writeln(
          "      $fieldName: (json['$rawKey'] as List<dynamic>?)?.map((e) => ${singular}Model.fromJson(e as Map<String, dynamic>)).toList(),");
    } else if (value is List) {
      buffer.writeln(
          "      $fieldName: (json['$rawKey'] as List<dynamic>?)?.map((e) => e as ${_primitiveListType(value)}).toList(),");
    } else {
      // primitive – direct assignment, can be null
      buffer.writeln("      $fieldName: json['$rawKey'],");
    }
  });
  buffer.writeln('    );');
  buffer.writeln('  }');
  buffer.writeln();

  // toJson
  buffer.writeln('  Map<String, dynamic> toJson() {');
  buffer.writeln('    return {');
  json.forEach((key, value) {
    final fieldName = _modelCamelCase(key);
    final rawKey = key;
    if (value is Map<String, dynamic>) {
      buffer.writeln("      '$rawKey': $fieldName?.toJson(),");
    } else if (value is List && value.isNotEmpty && value.first is Map<String, dynamic>) {
      buffer.writeln("      '$rawKey': $fieldName?.map((e) => e.toJson()).toList(),");
    } else {
      buffer.writeln("      '$rawKey': $fieldName,");
    }
  });
  buffer.writeln('    };');
  buffer.writeln('  }');
  buffer.writeln();

  // toDomain
  buffer.writeln('  ${className}Entity toDomain() {');
  buffer.writeln('    return ${className}Entity(');
  json.forEach((key, value) {
    final fieldName = _modelCamelCase(key);
    if (value is Map<String, dynamic>) {
      buffer.writeln('      $fieldName: $fieldName!.toDomain(),');
    } else if (value is List && value.isNotEmpty && value.first is Map<String, dynamic>) {
      buffer.writeln('      $fieldName: $fieldName?.map((e) => e.toDomain()).toList() ?? [],');
    } else {
      buffer.writeln('      $fieldName: $fieldName!,');
    }
  });
  buffer.writeln('    );');
  buffer.writeln('  }');
  buffer.writeln();

  // copyWith – parameters are already nullable, no extra ? needed
  buffer.writeln('  $modelClassName copyWith({');
  json.forEach((key, value) {
    final fieldName = _modelCamelCase(key);
    final type = _getDartType(value, key); // e.g. int?, List<...>?
    buffer.writeln('    $type $fieldName,'); // NO extra ? here
  });
  buffer.writeln('  }) {');
  buffer.writeln('    return $modelClassName(');
  json.forEach((key, value) {
    final fieldName = _modelCamelCase(key);
    buffer.writeln('      $fieldName: $fieldName ?? this.$fieldName,');
  });
  buffer.writeln('    );');
  buffer.writeln('  }');

  buffer.writeln('}');
  buffer.writeln();

  // Generate nested classes
  json.forEach((key, value) {
    if (value is Map<String, dynamic>) {
      nestedClassesBuffer.write(riverpodModelGenerateClass(
        _capitalizePascal(key),
        value,
        fileName,
        isNested: true,
        generatedClasses: generatedClasses,
      ));
    } else if (value is List && value.isNotEmpty && value.first is Map<String, dynamic>) {
      nestedClassesBuffer.write(riverpodModelGenerateClass(
        _capitalizePascal(_singularize(key)),
        value.first as Map<String, dynamic>,
        fileName,
        isNested: true,
        generatedClasses: generatedClasses,
      ));
    }
  });

  buffer.write(nestedClassesBuffer.toString());
  return buffer.toString();
}

// ─── Helpers (unchanged) ────────────────────────────────────────────────

String _getDartType(dynamic value, String key) {
  if (value == null) return 'dynamic';
  if (value is int) return 'int?';
  if (value is double) return 'double?';
  if (value is String) return 'String?';
  if (value is bool) return 'bool?';

  if (value is List) {
    if (value.isEmpty) return 'List<dynamic>?';
    if (value.first is Map<String, dynamic>) {
      return 'List<${_capitalizePascal(_singularize(key))}Model>?';
    }
    return 'List<${_primitiveListType(value)}>?';
  }

  if (value is Map<String, dynamic>) {
    return '${_capitalizePascal(key)}Model?';
  }

  return 'dynamic';
}

String _primitiveListType(List value) {
  if (value.isEmpty) return 'dynamic';
  final e = value.first;
  if (e is String) return 'String';
  if (e is int) return 'int';
  if (e is double) return 'double';
  if (e is bool) return 'bool';
  return 'dynamic';
}

String _capitalizePascal(String text) {
  if (text.isEmpty) return '';
  return text
      .split(RegExp(r'[_\s]+'))
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join();
}

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