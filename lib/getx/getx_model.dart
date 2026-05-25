String generateClass(
  String className,
  Map<String, dynamic> json, {
  bool isNested = false,
  Set<String>? generatedClasses,
}) {
  generatedClasses ??= <String>{};

  // Avoid regenerating the same class multiple times
  if (generatedClasses.contains(className)) {
    return '';
  }
  generatedClasses.add(className);

  StringBuffer buffer = StringBuffer();

  buffer.writeln('class $className {');

  json.forEach((key, value) {
    String type = getType(value, key);
    buffer.writeln('  final $type? $key;');
  });

  buffer.writeln('\n  $className({');
  json.forEach((key, value) {
    buffer.writeln('    this.$key,');
  });
  buffer.writeln('  });\n');

  // Factory fromJson
  buffer.writeln(
    '  factory $className.fromJson(Map<String, dynamic> json) => $className(',
  );
  json.forEach((key, value) {
    String type = getType(value, key);
    if (type == 'double') {
      buffer.writeln("    $key: (json['$key'] as num?)?.toDouble(),");
    } else if (type == 'List<dynamic>') {
      buffer.writeln(
        "    $key: json['$key'] != null ? List<dynamic>.from(json['$key']) : null,",
      );
    } else if (type.startsWith('List<')) {
      String itemType = type.substring(5, type.length - 1);
      buffer.writeln(
        "    $key: json['$key'] != null ? (json['$key'] as List).map((e) => $itemType.fromJson(e)).toList() : null,",
      );
    } else if (isNestedClass(value)) {
      buffer.writeln(
        "    $key: json['$key'] != null ? $type.fromJson(json['$key']) : null,",
      );
    } else {
      buffer.writeln("    $key: json['$key'],");
    }
  });
  buffer.writeln('  );\n');

  // toJson
  buffer.writeln('  Map<String, dynamic> toJson() {');
  buffer.writeln('    final Map<String, dynamic> data = <String, dynamic>{};');
  json.forEach((key, value) {
    if (value is Map<String, dynamic>) {
      buffer.writeln('    data[\'$key\'] = $key?.toJson();');
    } else if (value is List &&
        value.isNotEmpty &&
        value.first is Map<String, dynamic>) {
      buffer.writeln(
        '    data[\'$key\'] = $key?.map((e) => e.toJson()).toList();',
      );
    } else {
      buffer.writeln("    data['$key'] = $key;");
    }
  });
  buffer.writeln('    return data;');
  buffer.writeln('  }\n');
  buffer.writeln('}\n');

  // Generate nested classes
  json.forEach((key, value) {
    if (value is Map<String, dynamic>) {
      String nestedClass = generateClass(
        pascalCaseName(key),
        value,
        isNested: true,
        generatedClasses: generatedClasses,
      );
      buffer.writeln(nestedClass);
    } else if (value is List &&
        value.isNotEmpty &&
        value.first is Map<String, dynamic>) {
      String nestedClass = generateClass(
        pascalCaseName(singularize(key)),
        value.first as Map<String, dynamic>,
        isNested: true,
        generatedClasses: generatedClasses,
      );
      buffer.writeln(nestedClass);
    }
  });

  return buffer.toString();
}

String getType(dynamic value, String key) {
  if (value is int) return 'int';
  if (value is double) return 'double';
  if (value is String) return 'String';
  if (value is bool) return 'bool';
  if (value is List) {
    if (value.isNotEmpty && value.first is Map<String, dynamic>) {
      return 'List<${pascalCaseName(singularize(key))}>';
    }
    return 'List<dynamic>';
  }
  if (value is Map<String, dynamic>) {
    return pascalCaseName(key);
  }
  return 'dynamic';
}

bool isNestedClass(dynamic value) => value is Map<String, dynamic>;

String capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

String pascalCaseName(String text) {
  if (text.isEmpty) return '';
  final parts = text.split(RegExp(r'[_\s]+'));
  return parts.map((p) => capitalize(p)).join('');
}

String singularize(String text) {
  if (text.endsWith('ies')) {
    return '${text.substring(0, text.length - 3)}y';
  }
  if (text.endsWith('s') && text.length > 1) {
    return text.substring(0, text.length - 1);
  }
  return text;
}
