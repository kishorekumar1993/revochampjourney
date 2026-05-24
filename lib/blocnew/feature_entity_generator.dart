
// lib/bloc/generators/feature_entity_generator.dart
//
// Generates the feature-level domain Entity used as the submit payload.
// FIXED: copyWith sentinel pattern, JSON key preservation, null safety,
//        enum usage, and now uses Model class for dropdown deserialization.

import 'field_schema.dart';

enum StringFallback { emptyString, nullValue, throwOnNull }

class FeatureEntityGenerator {
  FeatureEntityGenerator({
    required this.featureName,
    required this.fields,
    this.fieldJsonKeyOverrides = const {},
    this.stringFallbackStrategy = StringFallback.emptyString,
  });

  final String featureName;
  final List<FieldSchema> fields;
  final Map<String, String> fieldJsonKeyOverrides;
  final StringFallback stringFallbackStrategy;

  String generate() {
    final entityName = '${featureName}Entity';
    final submitFields = fields
        .where((f) =>
            f.fieldType != FieldType.file && f.fieldType != FieldType.image)
        .toList();
    final buf = StringBuffer();

    buf.writeln('// AUTO-GENERATED — do not edit');
    buf.writeln("import 'package:equatable/equatable.dart';");

    // Import entity files for dropdown fields (type dependencies)
    for (final f
        in submitFields.where((f) => f.isAsyncDropdown || f.isStaticDropdown)) {
      final snake = toSnakeCase(f.entityClassName.replaceAll('Entity', ''));
      buf.writeln("import '${snake}_entity.dart';");
    }

    // Import model files for dropdown fields (used in fromJson)
    for (final f
        in submitFields.where((f) => f.isAsyncDropdown || f.isStaticDropdown)) {
      final modelClassName = f.entityClassName.replaceAll('Entity', 'Model');
      final snake = toSnakeCase(modelClassName);
      buf.writeln("import '../../data/model/$snake.dart';");
    }

    buf.writeln();
    buf.writeln('class $entityName extends Equatable {');
    buf.writeln('  const $entityName({');
    for (final f in submitFields) {
      final required = f.isRequired ? 'required ' : '';
      buf.writeln('    ${required}this.${f.fieldName},');
    }
    buf.writeln('  });');
    buf.writeln();

    for (final f in submitFields) {
      buf.writeln('  final ${f.dartType} ${f.fieldName};');
    }
    buf.writeln();

    // fromJson
    buf.writeln('  factory $entityName.fromJson(Map<String, dynamic> j) =>');
    buf.writeln('      $entityName(');
    for (final f in submitFields) {
      buf.writeln('        ${f.fieldName}: ${_fromJsonExpr(f)},');
    }
    buf.writeln('      );');
    buf.writeln();

    // toJson
    buf.writeln('  Map<String, dynamic> toJson() => {');
    for (final f in submitFields) {
      final jsonKey = _jsonKeyForField(f);
      buf.writeln("        '$jsonKey': ${_toJsonExpr(f)},");
    }
    buf.writeln('      };');
    buf.writeln();

    // copyWith sentinel
    buf.writeln('  $entityName copyWith({');
    for (final f in submitFields) {
      buf.writeln('    Object? ${f.fieldName} = _unset,');
    }
    buf.writeln('  }) {');
    buf.writeln('    return $entityName(');
    for (final f in submitFields) {
      buf.writeln(
          '      ${f.fieldName}: identical(${f.fieldName}, _unset) ? this.${f.fieldName} : ${f.fieldName} as ${f.dartType},');
    }
    buf.writeln('    );');
    buf.writeln('  }');
    buf.writeln();

    buf.writeln('  @override');
    buf.writeln(
        '  List<Object?> get props => [${submitFields.map((f) => f.fieldName).join(', ')}];');
    buf.writeln('  @override');
    buf.writeln('  bool get stringify => true;');
    buf.writeln('  static const Object _unset = Object();');
    buf.writeln('}');

    return buf.toString();
  }

  String _jsonKeyForField(FieldSchema f) =>
      fieldJsonKeyOverrides[f.fieldName] ?? toSnakeCase(f.fieldName);

  String _fromJsonExpr(FieldSchema f) {
    final key = "'${_jsonKeyForField(f)}'";
    switch (f.fieldType) {
      case FieldType.number:
        return "(j[$key] as num?)?.toInt()";
      case FieldType.decimal:
        return "(j[$key] as num?)?.toDouble()";
      case FieldType.checkbox:
        return "j[$key] as bool? ?? false";
      case FieldType.asyncDropdown:
      case FieldType.dropdown:
        // Use Model class (not Entity) for deserialization
        final modelClassName = f.entityClassName.replaceAll('Entity', 'Model');
        return "j[$key] != null ? $modelClassName.fromJson(j[$key] as Map<String, dynamic>) : null";
      case FieldType.date:
        return "j[$key] != null ? DateTime.parse(j[$key] as String) : null";
      default:
        switch (stringFallbackStrategy) {
          case StringFallback.emptyString:
            return "j[$key] as String? ?? ''";
          case StringFallback.nullValue:
            return "j[$key] as String?";
          case StringFallback.throwOnNull:
            return "j[$key] as String";
        }
    }
  }

  String _toJsonExpr(FieldSchema f) {
    final name = f.fieldName;
    switch (f.fieldType) {
      case FieldType.asyncDropdown:
      case FieldType.dropdown:
        // Serialize only the foreign key (e.g., .id)
        return "$name?.${f.dropdownValueKey}";
      case FieldType.date:
        return "$name?.toIso8601String()";
      default:
        return name;
    }
  }
}

// // lib/bloc/generators/feature_entity_generator.dart
// //
// // Generates the feature-level domain Entity used as the submit payload.
// // FIXED: copyWith sentinel pattern, JSON key preservation, null safety,
// // and corrected enum usage.

// import 'field_schema.dart';

// // This enum must be defined before use (or imported).
// enum StringFallback { emptyString, nullValue, throwOnNull }

// class FeatureEntityGenerator {
//   FeatureEntityGenerator({
//     required this.featureName,
//     required this.fields,
//     this.fieldJsonKeyOverrides = const {},
//     this.stringFallbackStrategy = StringFallback.emptyString,
//   });

//   final String featureName;
//   final List<FieldSchema> fields;
//   final Map<String, String> fieldJsonKeyOverrides;
//   final StringFallback stringFallbackStrategy;

//   String generate() {
//     final entityName = '${featureName}Entity';
//     final submitFields = fields
//         .where((f) => f.fieldType != FieldType.file &&
//                       f.fieldType != FieldType.image)
//         .toList();
//     final buf = StringBuffer();

//     buf.writeln('// AUTO-GENERATED — do not edit');
//     buf.writeln("import 'package:equatable/equatable.dart';");
//     for (final f in submitFields.where((f) => f.isAsyncDropdown || f.isStaticDropdown)) {
//       final snake = toSnakeCase(f.entityClassName.replaceAll('Entity', ''));
//       buf.writeln("import '${snake}_entity.dart';");
//     }
//     buf.writeln();
//     buf.writeln('class $entityName extends Equatable {');
//     buf.writeln('  const $entityName({');
//     for (final f in submitFields) {
//       final required = f.isRequired ? 'required ' : '';
//       buf.writeln('    ${required}this.${f.fieldName},');
//     }
//     buf.writeln('  });');
//     buf.writeln();

//     for (final f in submitFields) {
//       buf.writeln('  final ${f.dartType} ${f.fieldName};');
//     }
//     buf.writeln();

//     // fromJson
//     buf.writeln('  factory $entityName.fromJson(Map<String, dynamic> j) =>');
//     buf.writeln('      $entityName(');
//     for (final f in submitFields) {
//       buf.writeln('        ${f.fieldName}: ${_fromJsonExpr(f)},');
//     }
//     buf.writeln('      );');
//     buf.writeln();

//     // toJson
//     buf.writeln('  Map<String, dynamic> toJson() => {');
//     for (final f in submitFields) {
//       final jsonKey = _jsonKeyForField(f);
//       buf.writeln("        '$jsonKey': ${_toJsonExpr(f)},");
//     }
//     buf.writeln('      };');
//     buf.writeln();

//     // copyWith sentinel
//     buf.writeln('  $entityName copyWith({');
//     for (final f in submitFields) {
//       buf.writeln('    Object? ${f.fieldName} = _unset,');
//     }
//     buf.writeln('  }) {');
//     buf.writeln('    return $entityName(');
//     for (final f in submitFields) {
//       buf.writeln(
//           '      ${f.fieldName}: identical(${f.fieldName}, _unset) ? this.${f.fieldName} : ${f.fieldName} as ${f.dartType},');
//     }
//     buf.writeln('    );');
//     buf.writeln('  }');
//     buf.writeln();

//     buf.writeln('  @override');
//     buf.writeln('  List<Object?> get props => [${submitFields.map((f) => f.fieldName).join(', ')}];');
//     buf.writeln('  @override');
//     buf.writeln('  bool get stringify => true;');
//     buf.writeln('  static const Object _unset = Object();');
//     buf.writeln('}');

//     return buf.toString();
//   }

//   // Returns the JSON key for a field – first from overrides, then fallback to snake_case.
//   // (We no longer rely on f.jsonKey because FieldSchema may not have it.)
//   String _jsonKeyForField(FieldSchema f) =>
//       fieldJsonKeyOverrides[f.fieldName] ?? toSnakeCase(f.fieldName);

//   String _fromJsonExpr(FieldSchema f) {
//     final key = "'${_jsonKeyForField(f)}'";
//     switch (f.fieldType) {
//       case FieldType.number:
//         return "(j[$key] as num?)?.toInt()";
//       case FieldType.decimal:
//         return "(j[$key] as num?)?.toDouble()";
//       case FieldType.checkbox:
//         return "j[$key] as bool? ?? false";
//       case FieldType.asyncDropdown:
//       case FieldType.dropdown:
//         return "j[$key] != null ? ${f.entityClassName}.fromJson(j[$key] as Map<String, dynamic>) : null";
//       case FieldType.date:
//         return "j[$key] != null ? DateTime.parse(j[$key] as String) : null";
//       default:
//         // Exhaustive switch over StringFallback enum
//         switch (stringFallbackStrategy) {
//           case StringFallback.emptyString:
//             return "j[$key] as String? ?? ''";
//           case StringFallback.nullValue:
//             return "j[$key] as String?";
//           case StringFallback.throwOnNull:
//             return "j[$key] as String";
//     } }
//   }

//   String _toJsonExpr(FieldSchema f) {
//     final name = f.fieldName;
//     switch (f.fieldType) {
//       case FieldType.asyncDropdown:
//       case FieldType.dropdown:
//         return "$name?.${f.dropdownValueKey}";
//       case FieldType.date:
//         return "$name?.toIso8601String()";
//       default:
//         return name;
//     }
//   }
// }
