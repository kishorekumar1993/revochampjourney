// lib/bloc/generators/entity/entity_generator.dart
//
// Produces a pure immutable Equatable entity class from a JSON sample.
// Handles: String, int, double, bool, DateTime, nested maps, lists.
// No JSON serialization – that belongs in the Model layer.


class EntityGenerator {
  EntityGenerator({
    required this.className,
    required this.sampleJson,
  });

  final String className;
  final Map<String, dynamic> sampleJson;

  String generate() {
    final fields = _parseFields(sampleJson);
    final buf = StringBuffer();

    buf.writeln("import 'package:equatable/equatable.dart';");
    buf.writeln("import 'package:meta/meta.dart';");
    buf.writeln();
    buf.writeln('/// Auto-generated pure entity for [$className].');
    buf.writeln('/// Do NOT put JSON serialization here — use the Model layer.');
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

    // Field declarations
    for (final f in fields) {
      buf.writeln('  /// ${_toCap(f.name)}.');
      buf.writeln('  final ${f.type} ${f.name};');
    }
    buf.writeln();

    // copyWith using sentinel pattern
    buf.writeln('  $className copyWith({');
    for (final f in fields) {
      buf.writeln('    Object? ${f.name} = _unset,');
    }
    buf.writeln('  }) {');
    buf.writeln('    return $className(');
    for (final f in fields) {
      buf.writeln(
          '      ${f.name}: identical(${f.name}, _unset) ? this.${f.name} : ${f.name} as ${f.type},');
    }
    buf.writeln('    );');
    buf.writeln('  }');
    buf.writeln();

    // Equatable props
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

  // ------------------------------------------------------------------
  // Field parsing
  // ------------------------------------------------------------------
  List<_EntityField> _parseFields(Map<String, dynamic> json) {
    final fields = <_EntityField>[];
    for (final entry in json.entries) {
      final jsonKey = entry.key;
      final value = entry.value;
      final dartName = _toCamelCase(jsonKey);
      final type = _inferType(value);
      final isRequired = value != null; // if sample has null, field is optional
      final isDateTime = type == 'DateTime';
      fields.add(_EntityField(
        name: dartName,
        jsonKey: jsonKey,
        type: type,
        isRequired: isRequired,
        isDateTime: isDateTime,
      ));
    }
    return fields;
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
    return RegExp(r'^\d{4}-\d{2}-\d{2}(T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})?)?$')
        .hasMatch(s);
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

  String _toCap(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }
}

// ------------------------------------------------------------------
// Internal field class (preserves original JSON key)
// ------------------------------------------------------------------
class _EntityField {
  final String name;      // Dart camelCase name (e.g., userId)
  final String jsonKey;   // Original API key (e.g., user_id or userId)
  final String type;
  final bool isRequired;
  final bool isDateTime;

  _EntityField({
    required this.name,
    required this.jsonKey,
    required this.type,
    required this.isRequired,
    this.isDateTime = false,
  });
}

// // lib/bloc/generators/entity/entity_generator.dart
// //
// // Produces a pure immutable Equatable entity class from a JSON sample.
// // Handles: String, int, double, bool, DateTime, nested maps, lists.

// import 'package:revojourneytryone/blocnew/field_schema.dart';


// class EntityGenerator {
//   EntityGenerator({
//     required this.className,
//     required this.sampleJson,
//     this.includeJsonMethods = false,
//   });

//   final String className;
//   final Map<String, dynamic> sampleJson;
//   final bool includeJsonMethods;

//   String generate() {
//     final fields = GeneratorField.parseFields(sampleJson);

//     final buf = StringBuffer();
//     buf.writeln("import 'package:equatable/equatable.dart';");
//     buf.writeln();
//     buf.writeln("import 'package:meta/meta.dart';");
//     buf.writeln('/// Auto-generated pure entity for [$className].');
//     buf.writeln('/// Do NOT put JSON serialization here — use the Model layer.');
//     buf.writeln('@immutable');
//     buf.writeln('class $className extends Equatable {');
//     buf.writeln('  const $className({');
//     for (final f in fields) {
//       if (f.isRequired) {
//         buf.writeln('    required this.${f.name},');
//       } else {
//         buf.writeln('    this.${f.name},');
//       }
//     }
//     buf.writeln('  });');
//     buf.writeln();

//     for (final f in fields) {
//       buf.writeln('  /// ${toCap(f.name)}.');
//       buf.writeln('  final ${f.type} ${f.name};');
//     }
//     buf.writeln();

//     // copyWith
//     buf.writeln('  $className copyWith({');
//     for (final f in fields) {
//       final nullable = f.type.endsWith('?') ? f.type : '${f.type}?';
//       buf.writeln('    $nullable ${f.name},');
//     }
//     buf.writeln('  }) {');
//     buf.writeln('    return $className(');
//     for (final f in fields) {
//       buf.writeln('      ${f.name}: ${f.name} ?? this.${f.name},');
//     }
//     buf.writeln('    );');
//     buf.writeln('  }');
//     buf.writeln();

//     if (includeJsonMethods) {
//       _writeFromJson(buf, fields);
//       _writeToJson(buf, fields);
//     }

//     // Equatable props
//     buf.writeln('  @override');
//     buf.writeln('  List<Object?> get props => [');
//     for (final f in fields) {
//       buf.writeln('    ${f.name},');
//     }
//     buf.writeln('  ];');
//     buf.writeln();
//     buf.writeln('  @override');
//     buf.writeln('  bool get stringify => true;');
//     buf.writeln('}');

//     return buf.toString();
//   }

//   void _writeFromJson(StringBuffer buf, List<GeneratorField> fields) {
//     buf.writeln('  factory $className.fromJson(Map<String, dynamic> json) {');
//     buf.writeln('    return $className(');
//     for (final f in fields) {
//       final key = toSnakeCase(f.name);
//       buf.writeln("      ${f.name}: json['$key'] as ${f.type},");
//     }
//     buf.writeln('    );');
//     buf.writeln('  }');
//     buf.writeln();
//   }

//   void _writeToJson(StringBuffer buf, List<GeneratorField> fields) {
//     buf.writeln('  Map<String, dynamic> toJson() => {');
//     for (final f in fields) {
//       final key = toSnakeCase(f.name);
//       buf.writeln("    '$key': ${f.name},");
//     }
//     buf.writeln('  };');
//     buf.writeln();
//   }
// }
