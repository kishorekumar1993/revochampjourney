// lib/bloc/generators/model/model_generator.dart

class ModelGenerator {
  ModelGenerator({
    required this.modelClassName,
    required this.entityClassName,
    required this.sampleJson,
    required this.entityImportPath,
    this.nestedMappings = const {}, // optional: jsonKey -> modelClassName
  });

  final String modelClassName;
  final String entityClassName;
  final Map<String, dynamic> sampleJson;
  final String entityImportPath;
  final Map<String, String> nestedMappings;

  String generate() {
    final fields = _parseFieldsWithJsonKeys(sampleJson);
    final buf = StringBuffer();

    buf.writeln("import '$entityImportPath';");
    buf.writeln();

    buf.writeln('/// Data layer model for [$modelClassName].');
    buf.writeln('/// Handles JSON serialization; extends [$entityClassName].');
    buf.writeln('class $modelClassName extends $entityClassName {');
    buf.writeln('  const $modelClassName({');
    for (final f in fields) {
      buf.writeln('    required super.${f.name},');
    }
    buf.writeln('  });');
    buf.writeln();

    // fromJson
    buf.writeln('  factory $modelClassName.fromJson(Map<String, dynamic> json) {');
    buf.writeln('    return $modelClassName(');
    for (final f in fields) {
      buf.writeln('      ${f.name}: ${_jsonGetter(f, f.jsonKey)},');
    }
    buf.writeln('    );');
    buf.writeln('  }');
    buf.writeln();

    // toJson
    buf.writeln('  Map<String, dynamic> toJson() => {');
    for (final f in fields) {
      buf.writeln("    '${f.jsonKey}': ${_jsonSetter(f)},");
    }
    buf.writeln('  };');
    buf.writeln();

    // toEntity
    buf.writeln('  $entityClassName toEntity() => $entityClassName(');
    for (final f in fields) {
      buf.writeln('    ${f.name}: ${f.name},');
    }
    buf.writeln('  );');
    buf.writeln('}');

    return buf.toString();
  }

  List<GeneratorField> _parseFieldsWithJsonKeys(Map<String, dynamic> json) {
    final List<GeneratorField> fields = [];
    for (final entry in json.entries) {
      final jsonKey = entry.key;
      final value = entry.value;
      final dartFieldName = _toCamelCase(jsonKey);
      final fieldType = _inferType(value);
      final isDateTime = fieldType == 'DateTime';
      final isNullable = false; // you can enhance to detect null values
      fields.add(GeneratorField(
        name: dartFieldName,
        jsonKey: jsonKey,
        type: fieldType,
        isNullable: isNullable,
        isDateTime: isDateTime,
      ));
    }
    return fields;
  }

  String _toCamelCase(String key) {
    final parts = key.split(RegExp(r'[_-]'));
    if (parts.isEmpty) return key;
    final first = parts.first;
    if (parts.length == 1) return first;
    final rest = parts.skip(1).map((p) => p.isNotEmpty
        ? p[0].toUpperCase() + p.substring(1)
        : '');
    return first + rest.join();
  }

  String _inferType(dynamic value) {
    if (value == null) return 'dynamic';
    if (value is int) return 'int';
    if (value is double) return 'double';
    if (value is bool) return 'bool';
    if (value is String) {
      if (_isIsoDate(value)) return 'DateTime';
      return 'String';
    }
    if (value is List) {
      if (value.isEmpty) return 'List<dynamic>';
      final itemType = _inferType(value.first);
      return 'List<$itemType>';
    }
    if (value is Map) return 'Map<String, dynamic>';
    return 'dynamic';
  }

  bool _isIsoDate(String s) {
    return RegExp(r'^\d{4}-\d{2}-\d{2}(T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})?)?$').hasMatch(s);
  }

  String _jsonGetter(GeneratorField field, String jsonKey) {
    final isNullable = field.isNullable;
    final type = field.type;

    // Handle nested model (manual mapping)
    if (type == 'Map<String, dynamic>' && nestedMappings.containsKey(jsonKey)) {
      final nestedModel = nestedMappings[jsonKey]!;
      if (isNullable) {
        return "json['$jsonKey'] != null ? $nestedModel.fromJson(json['$jsonKey'] as Map<String,dynamic>) : null";
      } else {
        return "$nestedModel.fromJson(json['$jsonKey'] as Map<String,dynamic>)";
      }
    }

    // DateTime
    if (type == 'DateTime') {
      if (isNullable) {
        return "json['$jsonKey'] != null ? DateTime.parse(json['$jsonKey'] as String) : null";
      }
      return "DateTime.parse(json['$jsonKey'] as String)";
    }

    // Safe numeric parsing
    if (type == 'int') {
      return _safeNumericGetter(jsonKey, 'int', isNullable);
    }
    if (type == 'double') {
      return _safeNumericGetter(jsonKey, 'double', isNullable);
    }

    // List handling
    if (type.startsWith('List<')) {
      final innerType = _extractInnerType(type);
      if (innerType == 'dynamic' || innerType.isEmpty) {
        return isNullable
            ? "(json['$jsonKey'] as List<dynamic>?)?.toList()"
            : "(json['$jsonKey'] as List<dynamic>).toList()";
      }
      if (_isCustomType(innerType)) {
        final safeCast = isNullable ? "as List<dynamic>?" : "as List<dynamic>";
        final mapExpr = ".map((e) => $innerType.fromJson(e as Map<String,dynamic>)).toList()";
        if (isNullable) {
          return "json['$jsonKey'] != null ? (json['$jsonKey'] $safeCast)$mapExpr : null";
        } else {
          return "(json['$jsonKey'] $safeCast)$mapExpr";
        }
      } else {
        final cast = isNullable ? "as List<dynamic>?" : "as List<dynamic>";
        final toList = ".cast<$innerType>().toList()";
        if (isNullable) {
          return "json['$jsonKey'] != null ? (json['$jsonKey'] $cast)$toList : null";
        } else {
          return "(json['$jsonKey'] $cast)$toList";
        }
      }
    }

    // Map (non‑nested)
    if (type == 'Map<String, dynamic>') {
      return isNullable
          ? "json['$jsonKey'] as Map<String, dynamic>?"
          : "json['$jsonKey'] as Map<String, dynamic>";
    }

    // Custom model
    if (_isCustomType(type)) {
      if (isNullable) {
        return "json['$jsonKey'] != null ? $type.fromJson(json['$jsonKey'] as Map<String,dynamic>) : null";
      } else {
        return "$type.fromJson(json['$jsonKey'] as Map<String,dynamic>)";
      }
    }

    // Primitive types (String, bool, etc.)
    final safeType = _primitiveTypeCast(type);
    if (isNullable) {
      return "json['$jsonKey'] as $safeType?";
    } else {
      return "json['$jsonKey'] as $safeType";
    }
  }

  String _safeNumericGetter(String jsonKey, String targetType, bool isNullable) {
    final prefix = isNullable ? "json['$jsonKey'] != null ? " : "";
    final suffix = isNullable ? " : null" : "";
    if (targetType == 'int') {
      return "$prefix(json['$jsonKey'] as num).toInt()$suffix";
    } else if (targetType == 'double') {
      return "$prefix(json['$jsonKey'] as num).toDouble()$suffix";
    }
    return "json['$jsonKey'] as $targetType";
  }

  String _jsonSetter(GeneratorField field) {
    final type = field.type;
    final name = field.name;
    final nullable = field.isNullable;

    if (type == 'DateTime') {
      return nullable ? "$name?.toIso8601String()" : "$name.toIso8601String()";
    }
    if (type.startsWith('List<')) {
      final innerType = _extractInnerType(type);
      if (_isCustomType(innerType)) {
        return nullable ? "$name?.map((e) => e.toJson()).toList()" : "$name.map((e) => e.toJson()).toList()";
      } else {
        return name;
      }
    }
    if (_isCustomType(type)) {
      return nullable ? "$name?.toJson()" : "$name.toJson()";
    }
    return name;
  }

  String _extractInnerType(String listType) {
    final start = listType.indexOf('<');
    final end = listType.lastIndexOf('>');
    if (start == -1 || end == -1) return '';
    return listType.substring(start + 1, end);
  }

  bool _isCustomType(String type) {
    const primitives = {'String', 'int', 'double', 'bool', 'dynamic', 'Map', 'List', 'DateTime'};
    final base = type.split('<').first;
    return !primitives.contains(base);
  }

  String _primitiveTypeCast(String type) {
    switch (type) {
      case 'int':
        return 'int';
      case 'double':
        return 'double';
      case 'bool':
        return 'bool';
      case 'String':
        return 'String';
      default:
        return 'dynamic';
    }
  }
}

class GeneratorField {
  final String name;
  final String jsonKey;
  final String type;
  final bool isNullable;
  final bool isDateTime;

  GeneratorField({
    required this.name,
    required this.jsonKey,
    required this.type,
    this.isNullable = false,
    this.isDateTime = false,
  });
}

