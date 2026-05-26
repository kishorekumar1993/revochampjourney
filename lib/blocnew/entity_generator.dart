
class EntityGenerator {
  EntityGenerator({
    required this.className,
    required this.sampleJson,
    this.generatedEntities = const {},
  });

  final String className;
  final Map<String, dynamic> sampleJson;
  final Map<String, String> generatedEntities; // className -> fileContent

  String generate() {
    final fields = _parseFields(sampleJson, className);
    final buf = StringBuffer();

    buf.writeln("import 'package:equatable/equatable.dart';");
    buf.writeln("import 'package:meta/meta.dart';");
    
    // Add imports for nested entities
    final nestedImports = <String>{};
    for (final f in fields) {
      if (f.isNestedEntity && f.nestedClassName != null) {
        final nestedSnake = _toSnakeCase(f.nestedClassName!);
        nestedImports.add("import '${nestedSnake}_entity.dart';");
      }
    }
    for (final imp in nestedImports) {
      buf.writeln(imp);
    }
    
    buf.writeln();
    buf.writeln('/// Auto-generated pure entity for [$className].');
    buf.writeln('@immutable');
    buf.writeln('class $className extends Equatable {');
    buf.writeln('  const $className({');
    for (final f in fields) {
      if (f.isRequired) {
        buf.writeln('    required this.${f.name},');
      } else {
        buf.writeln('    this.${f.name},');
      }
    }
    buf.writeln('  });');
    buf.writeln();

    for (final f in fields) {
      buf.writeln('  /// ${_toCap(f.name)}.');
      buf.writeln('  final ${f.type} ${f.name};');
    }
    buf.writeln();

    // copyWith
    buf.writeln('  $className copyWith({');
    for (final f in fields) {
      buf.writeln('    Object? ${f.name} = _unset,');
    }
    buf.writeln('  }) {');
    buf.writeln('    return $className(');
    for (final f in fields) {
      buf.writeln('      ${f.name}: identical(${f.name}, _unset) ? this.${f.name} : ${f.name} as ${f.type},');
    }
    buf.writeln('    );');
    buf.writeln('  }');
    buf.writeln();

    buf.writeln('  @override');
    buf.writeln('  List<Object?> get props => [');
    for (final f in fields) {
      buf.writeln('    ${f.name},');
    }
    buf.writeln('  ];');
    buf.writeln();
    buf.writeln('  @override');
    buf.writeln('  bool get stringify => true;');
    buf.writeln();
    buf.writeln('  static const Object _unset = Object();');
    buf.writeln('}');

    return buf.toString();
  }

  List<_EntityField> _parseFields(Map<String, dynamic> json, String parentClassName) {
    final fields = <_EntityField>[];
    for (final entry in json.entries) {
      final jsonKey = entry.key;
      final value = entry.value;
      final dartName = _toCamelCase(jsonKey);
      final (type, nestedClassName, isNestedEntity) = _inferType(value, dartName, parentClassName);
      final isRequired = value != null;
      
      fields.add(_EntityField(
        name: dartName,
        jsonKey: jsonKey,
        type: type,
        isRequired: isRequired,
        isNestedEntity: isNestedEntity,
        nestedClassName: nestedClassName,
      ));
    }
    return fields;
  }

  (String type, String? nestedClassName, bool isNestedEntity) _inferType(
    dynamic value,
    String fieldName,
    String parentClassName,
  ) {
    if (value == null) return ('dynamic', null, false);
    if (value is int) return ('int', null, false);
    if (value is double) return ('double', null, false);
    if (value is bool) return ('bool', null, false);
    if (value is String) {
      if (_isIsoDate(value)) return ('DateTime', null, false);
      return ('String', null, false);
    }
    if (value is List) {
      if (value.isEmpty) return ('List<dynamic>', null, false);
      final (itemType, nestedItemName, isNested) = _inferType(value.first, '${fieldName}Item', parentClassName);
      if (isNested) {
        final nestedClassName = '${_toCap(fieldName)}Entity';
        _generateNestedEntity(nestedClassName, value.first as Map<String, dynamic>);
        return ('List<$nestedClassName>', nestedClassName, true);
      }
      return ('List<$itemType>', null, false);
    }
    if (value is Map<String, dynamic>) {
      final nestedClassName = '${_toCap(fieldName)}Entity';
      _generateNestedEntity(nestedClassName, value);
      return (nestedClassName, nestedClassName, true);
    }
    return ('dynamic', null, false);
  }

  void _generateNestedEntity(String className, Map<String, dynamic> nestedJson) {
    if (generatedEntities.containsKey(className)) return;
    final generator = EntityGenerator(
      className: className,
      sampleJson: nestedJson,
      generatedEntities: generatedEntities,
    );
    final content = generator.generate();
    generatedEntities[className] = content;
  }

  bool _isIsoDate(String s) {
    return RegExp(r'^\d{4}-\d{2}-\d{2}(T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})?)?$').hasMatch(s);
  }

  String _toCamelCase(String key) {
    final parts = key.split(RegExp(r'[_-]'));
    if (parts.isEmpty) return key;
    final first = parts.first;
    if (parts.length == 1) return first;
    final rest = parts.skip(1).map((p) => p.isNotEmpty ? p[0].toUpperCase() + p.substring(1) : '');
    return first + rest.join();
  }

  String _toCap(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }

  String _toSnakeCase(String text) {
    if (text.isEmpty) return text;
    final buffer = StringBuffer();
    buffer.write(text[0].toLowerCase());
    for (int i = 1; i < text.length; i++) {
      final char = text[i];
      if (char.toUpperCase() == char && char != char.toLowerCase()) {
        buffer.write('_${char.toLowerCase()}');
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }
}

class _EntityField {
  final String name;
  final String jsonKey;
  final String type;
  final bool isRequired;
  final bool isNestedEntity;
  final String? nestedClassName;

  _EntityField({
    required this.name,
    required this.jsonKey,
    required this.type,
    required this.isRequired,
    this.isNestedEntity = false,
    this.nestedClassName,
  });
}