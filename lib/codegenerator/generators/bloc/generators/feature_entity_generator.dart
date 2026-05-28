// lib/bloc/generators/feature_entity_generator.dart
//
// Generates the feature-level domain Entity used as the submit payload.
// FIXED: copyWith sentinel pattern, JSON key preservation, null safety,
//        enum usage, and now uses Model class for dropdown deserialization.

import '../engine/field_schema.dart';

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
    final buf = StringBuffer();

    buf.writeln('// AUTO-GENERATED — do not edit');
    buf.writeln("import 'package:equatable/equatable.dart';");

    // Import entity files for dropdown fields (type dependencies)
    final importedEntity = <String>{};
    final importedModel = <String>{};
    for (final f in fields.where((f) => f.isAsyncDropdown || f.isStaticDropdown)) {
      if (!f.hasDropdownData) continue;
      final entityBase = f.entityClassName.replaceAll('Entity', '');
      final entitySnake = toSnakeCase(entityBase);
      final entityImport = "${entitySnake}_entity.dart";
      if (importedEntity.add(entityImport)) {
        buf.writeln("import '$entityImport';");
      }

      final modelClass = f.entityClassName.replaceAll('Entity', 'Model');
      final modelSnake = toSnakeCase(modelClass);
      final modelImport = "../../data/model/$modelSnake.dart";
      if (importedModel.add(modelImport)) {
        buf.writeln("import '$modelImport';");
      }
    }

    buf.writeln();
    buf.writeln('class $entityName extends Equatable {');
    buf.writeln('  const $entityName({');
    for (final f in fields) {
      final required = f.isRequired ? 'required ' : '';
      buf.writeln('    ${required}this.${f.fieldName},');
    }
    buf.writeln('  });');
    buf.writeln();

    for (final f in fields) {
      final dartType = _dartType(f);
      buf.writeln('  final $dartType ${f.fieldName};');
    }
    buf.writeln();

    // fromJson
    buf.writeln('  factory $entityName.fromJson(Map<String, dynamic> json) =>');
    buf.writeln('      $entityName(');
    for (final f in fields) {
      buf.writeln('        ${f.fieldName}: ${_fromJsonExpr(f, 'json')},');
    }
    buf.writeln('      );');
    buf.writeln();

    // toJson
    buf.writeln('  Map<String, dynamic> toJson() => {');
    for (final f in fields) {
      final jsonKey = _jsonKeyForField(f);
      buf.writeln("        '$jsonKey': ${_toJsonExpr(f)},");
    }
    buf.writeln('      };');
    buf.writeln();

    // copyWith sentinel
    buf.writeln('  $entityName copyWith({');
    for (final f in fields) {
      buf.writeln('    Object? ${f.fieldName} = _unset,');
    }
    buf.writeln('  }) {');
    buf.writeln('    return $entityName(');
    for (final f in fields) {
      final dartType = _dartType(f);
      buf.writeln(
          '      ${f.fieldName}: identical(${f.fieldName}, _unset) ? this.${f.fieldName} : ${f.fieldName} as $dartType,');
    }
    buf.writeln('    );');
    buf.writeln('  }');
    buf.writeln();

    buf.writeln('  @override');
    buf.writeln('  List<Object?> get props => [${fields.map((f) => f.fieldName).join(', ')}];');
    buf.writeln('  @override');
    buf.writeln('  bool get stringify => true;');
    buf.writeln('  static const Object _unset = Object();');
    buf.writeln('}');

    return buf.toString();
  }

  String _jsonKeyForField(FieldSchema f) =>
      fieldJsonKeyOverrides[f.fieldName] ?? toSnakeCase(f.fieldName);

  String _fromJsonExpr(FieldSchema f, String jsonVar) {
    final key = "'${_jsonKeyForField(f)}'";
    switch (f.fieldType) {
      case FieldType.number:
        return "($jsonVar[$key] as num?)?.toInt()";
      case FieldType.decimal:
        return "($jsonVar[$key] as num?)?.toDouble()";
      case FieldType.checkbox:
        return "$jsonVar[$key] as bool? ?? false";
      case FieldType.asyncDropdown:
      case FieldType.dropdown:
        if (!f.hasDropdownData) {
          // If no dropdown data, treat as String (e.g., free-text dropdown)
          return "$jsonVar[$key] as String? ?? ''";
        }
        final modelClassName = f.entityClassName.replaceAll('Entity', 'Model');
        return "$jsonVar[$key] != null ? $modelClassName.fromJson($jsonVar[$key] as Map<String, dynamic>) : null";
      case FieldType.date:
        return "$jsonVar[$key] != null ? DateTime.parse($jsonVar[$key] as String) : null";
      default:
        switch (stringFallbackStrategy) {
          case StringFallback.emptyString:
            return "$jsonVar[$key] as String? ?? ''";
          case StringFallback.nullValue:
            return "$jsonVar[$key] as String?";
          case StringFallback.throwOnNull:
            return "$jsonVar[$key] as String";
        }
    }
  }

  String _toJsonExpr(FieldSchema f) {
    final fieldName = f.fieldName;
    switch (f.fieldType) {
      case FieldType.asyncDropdown:
      case FieldType.dropdown:
        if (!f.hasDropdownData) return fieldName;
        // Serialize only the foreign key (e.g., .id)
        return "$fieldName?.${f.dropdownValueKey}";
      case FieldType.date:
        return "$fieldName?.toIso8601String()";
      default:
        return fieldName;
    }
  }

  // ── Helper functions ──────────────────────────────────────────────────────
  String toSnakeCase(String input) {
    if (input.isEmpty) return input;
    final buffer = StringBuffer();
    buffer.write(input[0].toLowerCase());
    for (int i = 1; i < input.length; i++) {
      final char = input[i];
      if (char.toUpperCase() == char && char != char.toLowerCase()) {
        buffer.write('_${char.toLowerCase()}');
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  /// Returns the Dart type for the field.
  /// Assumes FieldSchema has a `dartType` getter; otherwise infers from fieldType.
  String _dartType(FieldSchema f) {
    if (f.dartType.isNotEmpty) return f.dartType;
    switch (f.fieldType) {
      case FieldType.checkbox:
        return 'bool';
      case FieldType.date:
      case FieldType.dateTime:
        return 'DateTime?';
      case FieldType.multiSelect:
        return 'List<String>';
      case FieldType.dropdown:
      case FieldType.asyncDropdown:
        return f.entityClassName;
      case FieldType.number:
        return 'int';
      case FieldType.decimal:
        return 'double';
      case FieldType.file:
      case FieldType.image:
        return 'dynamic'; // or 'File?' but we avoid dart:io in domain
      default:
        return 'String';
    }
  }
}
