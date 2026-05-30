

class DartModelGenerator {
  final Map<String, String> _classesToGenerate = {};

  String generate(String rootClassName, dynamic decodedJson) {
    _classesToGenerate.clear();
    
    if (decodedJson is Map<String, dynamic>) {
      _generateClass(rootClassName, decodedJson);
    } else if (decodedJson is List) {
      if (decodedJson.isNotEmpty && decodedJson.first is Map<String, dynamic>) {
        _generateClass(rootClassName, decodedJson.first as Map<String, dynamic>);
      } else {
        // Simple primitive list fallback
        return 'typedef $rootClassName = List<dynamic>;';
      }
    } else {
      return 'typedef $rootClassName = dynamic;';
    }

    final buffer = StringBuffer();
    // Root class is written first
    if (_classesToGenerate.containsKey(rootClassName)) {
      buffer.writeln(_classesToGenerate[rootClassName]);
    }
    _classesToGenerate.forEach((className, classCode) {
      if (className != rootClassName) {
        buffer.writeln(classCode);
      }
    });
    return buffer.toString();
  }

  void _generateClass(String className, Map<String, dynamic> jsonMap) {
    if (_classesToGenerate.containsKey(className)) return;

    final fields = <String, String>{};
    final listTypes = <String, String>{};
    final nestedObjects = <String, String>{};

    for (final entry in jsonMap.entries) {
      final key = entry.key;
      final val = entry.value;
      final fieldName = _safeFieldName(key);

      if (val is String) {
        fields[fieldName] = 'String';
      } else if (val is int) {
        fields[fieldName] = 'int';
      } else if (val is double) {
        fields[fieldName] = 'double';
      } else if (val is bool) {
        fields[fieldName] = 'bool';
      } else if (val is Map<String, dynamic>) {
        final subClassName = _capitalize(className) + _capitalize(fieldName);
        fields[fieldName] = subClassName;
        nestedObjects[fieldName] = subClassName;
        _generateClass(subClassName, val);
      } else if (val is List) {
        if (val.isEmpty) {
          fields[fieldName] = 'List<dynamic>';
        } else {
          final first = val.first;
          if (first is String) {
            fields[fieldName] = 'List<String>';
          } else if (first is int) {
            fields[fieldName] = 'List<int>';
          } else if (first is double) {
            fields[fieldName] = 'List<double>';
          } else if (first is bool) {
            fields[fieldName] = 'List<bool>';
          } else if (first is Map<String, dynamic>) {
            final subClassName = _capitalize(className) + _capitalize(_singular(fieldName));
            fields[fieldName] = 'List<$subClassName>';
            listTypes[fieldName] = subClassName;
            _generateClass(subClassName, first);
          } else {
            fields[fieldName] = 'List<dynamic>';
          }
        }
      } else {
        fields[fieldName] = 'dynamic';
      }
    }

    final buffer = StringBuffer();
    buffer.writeln('class $className {');

    fields.forEach((fieldName, typeName) {
      buffer.writeln('  final $typeName $fieldName;');
    });
    buffer.writeln('');

    buffer.writeln('  $className({');
    fields.forEach((fieldName, _) {
      buffer.writeln('    required this.$fieldName,');
    });
    buffer.writeln('  });');
    buffer.writeln('');

    buffer.writeln('  factory $className.fromJson(Map<String, dynamic> json) {');
    buffer.writeln('    return $className(');
    fields.forEach((fieldName, typeName) {
      final jsonKey = jsonMap.keys.firstWhere((k) => _safeFieldName(k) == fieldName, orElse: () => fieldName);
      if (nestedObjects.containsKey(fieldName)) {
        final subClass = nestedObjects[fieldName]!;
        buffer.writeln("      $fieldName: json['$jsonKey'] != null ? $subClass.fromJson(json['$jsonKey'] as Map<String, dynamic>) : $subClass.empty(),");
      } else if (listTypes.containsKey(fieldName)) {
        final subClass = listTypes[fieldName]!;
        buffer.writeln("      $fieldName: json['$jsonKey'] != null ? (json['$jsonKey'] as List).map((i) => $subClass.fromJson(i as Map<String, dynamic>)).toList() : [],");
      } else {
        String fallback = 'null';
        if (typeName == 'String') {
          fallback = "''";
        } else if (typeName == 'int') {
          fallback = '0';
        } else if (typeName == 'double') {
          fallback = '0.0';
        } else if (typeName == 'bool') {
          fallback = 'false';
        } else if (typeName.startsWith('List')) {
          fallback = 'const []';
        }

        if (fallback == 'null') {
          buffer.writeln("      $fieldName: json['$jsonKey'],");
        } else {
          buffer.writeln("      $fieldName: json['$jsonKey'] ?? $fallback,");
        }
      }
    });
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln('');

    buffer.writeln('  Map<String, dynamic> toJson() {');
    buffer.writeln('    return {');
    fields.forEach((fieldName, typeName) {
      final jsonKey = jsonMap.keys.firstWhere((k) => _safeFieldName(k) == fieldName, orElse: () => fieldName);
      if (nestedObjects.containsKey(fieldName)) {
        buffer.writeln("      '$jsonKey': $fieldName.toJson(),");
      } else if (listTypes.containsKey(fieldName)) {
        buffer.writeln("      '$jsonKey': $fieldName.map((i) => i.toJson()).toList(),");
      } else {
        buffer.writeln("      '$jsonKey': $fieldName,");
      }
    });
    buffer.writeln('    };');
    buffer.writeln('  }');

    buffer.writeln('');
    buffer.writeln('  factory $className.empty() {');
    buffer.writeln('    return $className(');
    fields.forEach((fieldName, typeName) {
      if (nestedObjects.containsKey(fieldName)) {
        final subClass = nestedObjects[fieldName]!;
        buffer.writeln("      $fieldName: $subClass.empty(),");
      } else if (typeName.startsWith('List')) {
        buffer.writeln("      $fieldName: const [],");
      } else if (typeName == 'String') {
        buffer.writeln("      $fieldName: '',");
      } else if (typeName == 'int') {
        buffer.writeln("      $fieldName: 0,");
      } else if (typeName == 'double') {
        buffer.writeln("      $fieldName: 0.0,");
      } else if (typeName == 'bool') {
        buffer.writeln("      $fieldName: false,");
      } else {
        buffer.writeln("      $fieldName: null,");
      }
    });
    buffer.writeln('    );');
    buffer.writeln('  }');

    buffer.writeln('}');
    buffer.writeln('');

    _classesToGenerate[className] = buffer.toString();
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  String _singular(String s) {
    if (s.toLowerCase().endsWith('s') && s.length > 1) {
      return s.substring(0, s.length - 1);
    }
    return s;
  }

  String _safeFieldName(String s) {
    var clean = s.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
    if (clean.isEmpty) return 'field';
    if (RegExp(r'^[0-9]').hasMatch(clean)) {
      clean = 'val_$clean';
    }
    final parts = clean.split('_');
    final buffer = StringBuffer(parts.first);
    for (int i = 1; i < parts.length; i++) {
      buffer.write(_capitalize(parts[i]));
    }
    final finalStr = buffer.toString();
    const keywords = {'class', 'interface', 'extends', 'implements', 'import', 'export', 'final', 'const', 'var', 'dynamic', 'void', 'null', 'true', 'false', 'return', 'if', 'else', 'switch', 'case', 'default', 'for', 'while', 'do', 'break', 'continue', 'in', 'is', 'as', 'new', 'this', 'super'};
    if (keywords.contains(finalStr.toLowerCase())) {
      return '${finalStr}Value';
    }
    return finalStr;
  }
}
