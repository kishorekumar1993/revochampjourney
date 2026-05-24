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
        capitalize(key),
        value,
        isNested: true,
        generatedClasses: generatedClasses,
      );
      buffer.writeln(nestedClass);
    } else if (value is List &&
        value.isNotEmpty &&
        value.first is Map<String, dynamic>) {
      String nestedClass = generateClass(
        capitalize(key),
        value.first,
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
      return 'List<${capitalize(key)}>';
    }
    return 'List<dynamic>';
  }
  if (value is Map<String, dynamic>) {
    return capitalize(key);
  }
  return 'dynamic';
}

bool isNestedClass(dynamic value) => value is Map<String, dynamic>;

String capitalize(String s) => s[0].toUpperCase() + s.substring(1);


// String generateClass(String className, Map<String, dynamic> json, {bool isNested = false}) {
//   StringBuffer buffer = StringBuffer();

//   buffer.writeln('class $className {');

//   json.forEach((key, value) {
//     String type = getType(value, key);
//     buffer.writeln('  final $type? $key;');
//   });

//   buffer.writeln('\n  $className({');
//   json.forEach((key, value) {
//     buffer.writeln('    this.$key,');
//     // buffer.writeln('    required this.$key,');
//   });
//   buffer.writeln('  });\n');

//   // Factory constructor
//   buffer.writeln('  factory $className.fromJson(Map<String, dynamic> json) => $className(');
//   // json.forEach((key, value) {
//   //   String type = getType(value, key);
//   //   if (type == 'double') {
//   //     buffer.writeln('    $key: (json[\'$key\'] as num).toDouble(),');
//   //   } else if (type == 'List<dynamic>') {
//   //     buffer.writeln('    $key: List<dynamic>.from(json[\'$key\']),');
//   //   } else if (type.startsWith('List<')) {
//   //     String itemType = type.substring(5, type.length - 1);
//   //     buffer.writeln('    $key: (json[\'$key\'] as List).map((e) => $itemType.fromJson(e)).toList(),');
//   //   } else if (isNestedClass(value)) {
//   //     buffer.writeln('    $key: $type.fromJson(json[\'$key\']),');
//   //   } else {
//   //     buffer.writeln('    $key: json[\'$key\'],');
//   //   }
//   // });
//   json.forEach((key, value) {
//   String type = getType(value, key);
//   if (type == 'double') {
//     buffer.writeln("    $key: (json['$key'] as num?)?.toDouble(),");
//   } else if (type == 'List<dynamic>') {
//     buffer.writeln("    $key: json['$key'] != null ? List<dynamic>.from(json['$key']) : null,");
//   } else if (type.startsWith('List<')) {
//     String itemType = type.substring(5, type.length - 1);
//     buffer.writeln(
//       "    $key: json['$key'] != null ? (json['$key'] as List).map((e) => $itemType.fromJson(e)).toList() : null,",
//     );
//   } else if (isNestedClass(value)) {
//     buffer.writeln("    $key: json['$key'] != null ? $type.fromJson(json['$key']) : null,");
//   } else {
//     buffer.writeln("    $key: json['$key'],");
//   }
// });

//   buffer.writeln('  );\n');

// // toJson method
// buffer.writeln('  Map<String, dynamic> toJson() {');
// buffer.writeln('    final Map<String, dynamic> data = <String, dynamic>{};');

// json.forEach((key, value) {
//   if (value is Map<String, dynamic>) {
//     buffer.writeln('    data[\'$key\'] = $key?.toJson();');
//   } else if (value is List && value.isNotEmpty && value.first is Map<String, dynamic>) {
//     buffer.writeln('    data[\'$key\'] = $key?.map((e) => e.toJson()).toList();');
//   } else {
//     buffer.writeln("    data['$key'] = $key;");
//   }
// });

// buffer.writeln('    return data;');
// buffer.writeln('  }\n');

//   // // toJson
//   // buffer.writeln('  Map<String, dynamic> toJson() => {');
//   // buffer.writeln('  final Map<String, dynamic> data = new Map<String, dynamic>()');

    
//   // json.forEach((key, value) {
//   //   if (value is Map<String, dynamic>) {
//   //     buffer.writeln('    "$key": $key.toJson(),');
//   //   } else if (value is List && value.isNotEmpty && value.first is Map<String, dynamic>) {
//   //     buffer.writeln('    "$key": $key.map((e) => e.toJson()).toList(),');
//   //   } else {
//   //     // buffer.writeln('    "$key": $key,');
//   //     buffer.writeln("    data['$key'] = this.$key;,");
      
//   //     // buffer.writeln('    "$key": $key,');
//   //   }
//   // });
//   // buffer.writeln('  };');

//   buffer.writeln('}\n');

//   // Nested classes
//   json.forEach((key, value) {
//     if (value is Map<String, dynamic>) {
//       String nestedClass = generateClass(capitalize(key), value, isNested: true);
//       buffer.writeln(nestedClass);
//     } else if (value is List && value.isNotEmpty && value.first is Map<String, dynamic>) {
//       String nestedClass = generateClass(capitalize(key), value.first, isNested: true);
//       buffer.writeln(nestedClass);
//     }
//   });

//   return buffer.toString();
// }

// String getType(dynamic value, String key) {
//   if (value is int) return 'int';
//   if (value is double) return 'double';
//   if (value is String) return 'String';
//   if (value is bool) return 'bool';
//   if (value is List) {
//     if (value.isNotEmpty && value.first is Map<String, dynamic>) {
//       return 'List<${capitalize(key)}>';
//     }
//     return 'List<dynamic>';
//   }
//   if (value is Map<String, dynamic>) {
//     return capitalize(key);
//   }
//   return 'dynamic';
// }

// bool isNestedClass(dynamic value) => value is Map<String, dynamic>;

// bool isListOfObjects(dynamic value) =>
//     value is List && value.isNotEmpty && value.first is Map<String, dynamic>;

// String capitalize(String s) => s[0].toUpperCase() + s.substring(1);


