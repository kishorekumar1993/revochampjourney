// lib/bloc/generators/state/state_generator.dart
import 'package:revojourneytryone/blocnew/field_schema.dart';

class StateGenerator {
  StateGenerator({
    required this.featureName,
    required this.fields,
    required this.resultDataClass,
    this.runtimeImportPrefix = '../../../core/runtime',
  });

  final String featureName;
  final List<FieldSchema> fields;
  final String resultDataClass;
  final String runtimeImportPrefix;

  String generate() {
    final stateName = '${featureName}State';   // No "Feature"!
    final asyncDropdowns = fields.where((f) => f.isAsyncDropdown).toList();
    final buf = StringBuffer();

    buf.writeln("import 'package:equatable/equatable.dart';");
    buf.writeln("import '$runtimeImportPrefix/reactive_value.dart';");
    buf.writeln("import '$runtimeImportPrefix/async_state.dart';");

    // dart:io for file fields
    if (fields.any((f) => f.isFileUpload || f.fieldType == FieldType.image)) {
      buf.writeln("import 'dart:io';");
    }
    // Entity imports for dropdowns
    for (final f in asyncDropdowns) {
      final snake = _toSnakeCase(f.entityClassName.replaceAll('Entity', ''));
      buf.writeln("import '../../domain/entities/${snake}_entity.dart';");
    }
    buf.writeln();

    buf.writeln('class $stateName extends Equatable {');
    buf.writeln('  const $stateName({');
    for (final f in fields) {
      buf.writeln('    this.${f.fieldName} = const ReactiveValue.pure(${_pureDefault(f)}),');
    }
    for (final f in asyncDropdowns) {
      buf.writeln('    this.${f.fieldName}List = const AsyncIdle(),');
    }
    buf.writeln('    this.submission = const AsyncIdle(),');
    buf.writeln('  });');
    buf.writeln();

    // Field declarations
    for (final f in fields) {
      buf.writeln('  final ReactiveValue<${_reactiveType(f)}> ${f.fieldName};');
    }
    buf.writeln();
    for (final f in asyncDropdowns) {
      buf.writeln('  final AsyncState<List<${f.entityClassName}>> ${f.fieldName}List;');
    }
    buf.writeln('  final AsyncState<$resultDataClass> submission;');
    buf.writeln();

    // Getters
    buf.writeln('  Iterable<ReactiveValue<dynamic>> get allFields => [${fields.map((f) => f.fieldName).join(', ')}];');
    buf.writeln('  Map<String, ReactiveValue<dynamic>> get componentRegistry => {');
    for (final f in fields) {
      buf.writeln("    '${f.fieldName}': ${f.fieldName},");
    }
    buf.writeln('  };');
    buf.writeln('  bool get isFormValid => allFields.every((f) => f.isValid);');
    buf.writeln('  bool get isSubmitting => submission.isBusy;');
    buf.writeln();

    // copyWith
    buf.writeln('  $stateName copyWith({');
    for (final f in fields) {
      buf.writeln('    ReactiveValue<${_reactiveType(f)}>? ${f.fieldName},');
    }
    for (final f in asyncDropdowns) {
      buf.writeln('    AsyncState<List<${f.entityClassName}>>? ${f.fieldName}List,');
    }
    buf.writeln('    AsyncState<$resultDataClass>? submission,');
    buf.writeln('  }) {');
    buf.writeln('    return $stateName(');
    for (final f in fields) {
      buf.writeln('      ${f.fieldName}: ${f.fieldName} ?? this.${f.fieldName},');
    }
    for (final f in asyncDropdowns) {
      buf.writeln('      ${f.fieldName}List: ${f.fieldName}List ?? this.${f.fieldName}List,');
    }
    buf.writeln('      submission: submission ?? this.submission,');
    buf.writeln('    );');
    buf.writeln('  }');
    buf.writeln();

    // Equatable props
    buf.writeln('  @override List<Object?> get props => [');
    for (final f in fields) {
      buf.writeln('    ${f.fieldName},');
    }
    for (final f in asyncDropdowns) {
      buf.writeln('    ${f.fieldName}List,');
    }
    buf.writeln('    submission,');
    buf.writeln('  ];');
    buf.writeln('}');
    buf.writeln();

    // Result data class
    buf.writeln('class $resultDataClass extends Equatable {');
    buf.writeln('  const $resultDataClass({required this.message, this.id});');
    buf.writeln('  final String message;');
    buf.writeln('  final int? id;');
    buf.writeln('  @override List<Object?> get props => [message, id];');
    buf.writeln('}');

    return buf.toString();
  }

  String _reactiveType(FieldSchema f) {
    if (f.reactiveValueType.isNotEmpty) return f.reactiveValueType;
    switch (f.fieldType) {
      case FieldType.checkbox: return 'bool';
      case FieldType.date: case FieldType.dateTime: return 'DateTime?';
      case FieldType.multiSelect: return 'List<String>';
      case FieldType.dropdown: case FieldType.asyncDropdown: return f.entityClassName;
      case FieldType.file: case FieldType.image: return 'File?';
      case FieldType.number: return 'int';
      case FieldType.decimal: return 'double';
      default: return 'String';
    }
  }

  String _pureDefault(FieldSchema f) {
    if (f.pureDefault.isNotEmpty) return f.pureDefault;
    switch (f.fieldType) {
      case FieldType.checkbox: return 'false';
      case FieldType.date: case FieldType.dateTime: return 'null';
      case FieldType.multiSelect: return 'const []';
      case FieldType.dropdown: case FieldType.asyncDropdown: return 'null';
      case FieldType.file: case FieldType.image: return 'null';
      case FieldType.number: return '0';
      case FieldType.decimal: return '0.0';
      default: return "''";
    }
  }

  String _toSnakeCase(String input) {
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
}