// lib/bloc/generators/state/state_generator.dart
// v3: Fixes all Dart analysis errors in the generated state file:
//   - async_state.dart properly imported (AsyncState, AsyncIdle subclasses)
//   - ReactiveValue.pure() used as const default (requires named constructor)
//   - isBusy / dataOrNull come from AsyncState sealed class
//   - No more AsyncStatus enum references

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
    final stateName      = '${featureName}FeatureState';
    final asyncDropdowns = fields.where((f) => f.isAsyncDropdown).toList();
    final buf            = StringBuffer();

    buf.writeln("import 'package:equatable/equatable.dart';");
    buf.writeln("import '$runtimeImportPrefix/reactive_value.dart';");
    // FIX: import async_state.dart which defines AsyncState + all subclasses
    buf.writeln("import '$runtimeImportPrefix/async_state.dart';");

    // Conditional dart:io for file/image fields
    final seen = <String>{};
    for (final f in fields) {
      if (f.isFileUpload || f.fieldType == FieldType.image) {
        if (seen.add('dart:io')) buf.writeln("import 'dart:io';");
      }
      if (f.hasDropdownData && seen.add(f.entityClassName)) {
        final es = toSnakeCase(f.entityClassName.replaceAll('Entity', ''));
        buf.writeln("import '../../domain/entities/${es}_entity.dart';");
      }
    }
    buf.writeln();

    // ── Class ─────────────────────────────────────────────────────────────────
    buf.writeln('class $stateName extends Equatable {');
    buf.writeln('  const $stateName({');
    for (final f in fields) {
      // FIX: ReactiveValue.pure() is now a const named constructor
      buf.writeln(
        '    this.${f.fieldName} = const ReactiveValue.pure(${f.pureDefault}),');
    }
    for (final f in asyncDropdowns) {
      // FIX: AsyncIdle is a proper final class — const-constructable
      buf.writeln('    this.${f.fieldName}List = const AsyncIdle(),');
    }
    buf.writeln('    this.submission = const AsyncIdle(),');
    buf.writeln('  });');
    buf.writeln();

    // ── Field declarations ────────────────────────────────────────────────────
    for (final f in fields) {
      buf.writeln('  final ReactiveValue<${f.reactiveValueType}> ${f.fieldName};');
    }
    buf.writeln();

    for (final f in asyncDropdowns) {
      buf.writeln(
        '  final AsyncState<List<${f.entityClassName}>> ${f.fieldName}List;');
    }
    // FIX: submission is AsyncState<$resultDataClass>, not AsyncIdle typed separately
    buf.writeln('  final AsyncState<$resultDataClass> submission;');
    buf.writeln();

    // ── Derived getters ───────────────────────────────────────────────────────
    buf.writeln('  Iterable<ReactiveValue<dynamic>> get allFields => [');
    for (final f in fields) {
      buf.writeln('    ${f.fieldName},');
    }
    buf.writeln('  ];');
    buf.writeln();

    buf.writeln('  Map<String, ReactiveValue<dynamic>> get componentRegistry => {');
    for (final f in fields) {
      buf.writeln("    '${f.fieldName}': ${f.fieldName},");
    }
    buf.writeln('  };');
    buf.writeln();

    buf.writeln('  bool get isFormValid  => allFields.every((f) => f.isValid);');
    // FIX: isBusy is defined on AsyncState sealed base
    buf.writeln('  bool get isSubmitting => submission.isBusy;');
    buf.writeln();

    // ── BlocSelector-ready typed accessors ────────────────────────────────────
    for (final f in fields) {
      buf.writeln(
        '  ReactiveValue<${f.reactiveValueType}> '
        'get ${f.fieldName}Field => ${f.fieldName};');
    }
    for (final f in asyncDropdowns) {
      buf.writeln(
        '  AsyncState<List<${f.entityClassName}>> '
        'get ${f.fieldName}State => ${f.fieldName}List;');
      // FIX: dataOrNull is defined on AsyncState sealed base
      buf.writeln(
        '  List<${f.entityClassName}> get ${f.fieldName}Options => '
        '${f.fieldName}List.dataOrNull ?? const [];');
    }
    buf.writeln(
      '  AsyncState<$resultDataClass> get submissionState => submission;');
    buf.writeln();

    // ── copyWith ──────────────────────────────────────────────────────────────
    buf.writeln('  $stateName copyWith({');
    for (final f in fields) {
      buf.writeln(
        '    ReactiveValue<${f.reactiveValueType}>? ${f.fieldName},');
    }
    for (final f in asyncDropdowns) {
      buf.writeln(
        '    AsyncState<List<${f.entityClassName}>>? ${f.fieldName}List,');
    }
    buf.writeln('    AsyncState<$resultDataClass>? submission,');
    buf.writeln('  }) {');
    buf.writeln('    return $stateName(');
    for (final f in fields) {
      buf.writeln(
        '      ${f.fieldName}: ${f.fieldName} ?? this.${f.fieldName},');
    }
    for (final f in asyncDropdowns) {
      buf.writeln(
        '      ${f.fieldName}List: ${f.fieldName}List ?? this.${f.fieldName}List,');
    }
    buf.writeln('      submission: submission ?? this.submission,');
    buf.writeln('    );');
    buf.writeln('  }');
    buf.writeln();

    // ── Equatable ─────────────────────────────────────────────────────────────
    buf.writeln('  @override');
    buf.writeln('  List<Object?> get props => [');
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

    // ── ResultData value object ───────────────────────────────────────────────
    buf.writeln('class $resultDataClass extends Equatable {');
    buf.writeln(
      '  const $resultDataClass({required this.message, this.id});');
    buf.writeln('  final String message;');
    buf.writeln('  final int?   id;');
    buf.writeln('  @override List<Object?> get props => [message, id];');
    buf.writeln('}');

    return buf.toString();
  }
}

// // lib/bloc/generators/state/state_generator.dart
// // v2: Uses FieldSchema.reactiveValueType / pureDefault for all field types.
// //     Handles: String, DateTime?, bool, File?, List<String>, EntityClass?

// import 'package:revojourneytryone/blocnew/field_schema.dart';


// class StateGenerator {
//   StateGenerator({
//     required this.featureName,
//     required this.fields,
//     required this.resultDataClass,
//     this.runtimeImportPrefix = '../../../core/runtime',
//   });

//   final String featureName;
//   final List<FieldSchema> fields;
//   final String resultDataClass;
//   final String runtimeImportPrefix;

//   String generate() {
//     final stateName      = '${featureName}FeatureState';
//     final asyncDropdowns = fields.where((f) => f.isAsyncDropdown).toList();
//     final buf            = StringBuffer();

//     buf.writeln("import 'package:equatable/equatable.dart';");
//     buf.writeln("import '$runtimeImportPrefix/reactive_value.dart';");
//     buf.writeln("import '$runtimeImportPrefix/async_state.dart';");

//     // Entity imports
//     final seen = <String>{};
//     for (final f in fields) {
//       if (f.fieldType == FieldType.image) {
//         buf.writeln("import 'dart:io';");
//         seen.add('dart:io');
//       }
//       if (f.hasDropdownData && seen.add(f.entityClassName)) {
//         final es = toSnakeCase(f.entityClassName.replaceAll('Entity', ''));
//         buf.writeln("import '../../domain/entities/${es}_entity.dart';");
//       }
//     }
//     buf.writeln();

//     buf.writeln('class $stateName extends Equatable {');
//     buf.writeln('  const $stateName({');
//     for (final f in fields) {
//       buf.writeln('    this.${f.fieldName} = const ReactiveValue.pure(${f.pureDefault}),');
//     }
//     for (final f in asyncDropdowns) {
//       buf.writeln('    this.${f.fieldName}List = const AsyncIdle(),');
//     }
//     buf.writeln('    this.submission = const AsyncIdle(),');
//     buf.writeln('  });');
//     buf.writeln();

//     // Field declarations
//     for (final f in fields) {
//       final rvType = f.reactiveValueType;
//       buf.writeln('  final ReactiveValue<$rvType> ${f.fieldName};');
//     }
//     buf.writeln();

//     // Async dropdown declarations
//     for (final f in asyncDropdowns) {
//       buf.writeln('  final AsyncState<List<${f.entityClassName}>> ${f.fieldName}List;');
//     }
//     buf.writeln('  final AsyncState<$resultDataClass> submission;');
//     buf.writeln();

//     // allFields
//     buf.writeln('  Iterable<ReactiveValue<dynamic>> get allFields => [');
//     for (final f in fields) {
//       buf.writeln('    ${f.fieldName},');
//     }
//     buf.writeln('  ];');
//     buf.writeln();

//     // componentRegistry
//     buf.writeln('  Map<String, ReactiveValue<dynamic>> get componentRegistry => {');
//     for (final f in fields) {
//       buf.writeln("    '${f.fieldName}': ${f.fieldName},");
//     }
//     buf.writeln('  };');
//     buf.writeln();

//     // Derived
//     buf.writeln('  bool get isFormValid  => allFields.every((f) => f.isValid);');
//     buf.writeln('  bool get isSubmitting => submission.isBusy;');
//     buf.writeln();

//     // BlocSelector-ready selectors
//     for (final f in fields) {
//       final rvType = f.reactiveValueType;
//       buf.writeln('  ReactiveValue<$rvType> get ${f.fieldName}Field => ${f.fieldName};');
//     }
//     for (final f in asyncDropdowns) {
//       buf.writeln('  AsyncState<List<${f.entityClassName}>> get ${f.fieldName}State => ${f.fieldName}List;');
//       buf.writeln('  List<${f.entityClassName}> get ${f.fieldName}Options => ${f.fieldName}List.dataOrNull ?? const [];');
//     }
//     buf.writeln('  AsyncState<$resultDataClass> get submissionState => submission;');
//     buf.writeln();

//     // copyWith
//     buf.writeln('  $stateName copyWith({');
//     for (final f in fields) {
//       final rvType = f.reactiveValueType;
//       buf.writeln('    ReactiveValue<$rvType>? ${f.fieldName},');
//     }
//     for (final f in asyncDropdowns) {
//       buf.writeln('    AsyncState<List<${f.entityClassName}>>? ${f.fieldName}List,');
//     }
//     buf.writeln('    AsyncState<$resultDataClass>? submission,');
//     buf.writeln('  }) {');
//     buf.writeln('    return $stateName(');
//     for (final f in fields) {
//       buf.writeln('      ${f.fieldName}: ${f.fieldName} ?? this.${f.fieldName},');
//     }
//     for (final f in asyncDropdowns) {
//       buf.writeln('      ${f.fieldName}List: ${f.fieldName}List ?? this.${f.fieldName}List,');
//     }
//     buf.writeln('      submission: submission ?? this.submission,');
//     buf.writeln('    );');
//     buf.writeln('  }');
//     buf.writeln();

//     // Equatable
//     buf.writeln('  @override');
//     buf.writeln('  List<Object?> get props => [');
//     for (final f in fields) {
//       buf.writeln('    ${f.fieldName},');
//     }
//     for (final f in asyncDropdowns) {
//       buf.writeln('    ${f.fieldName}List,');
//     }
//     buf.writeln('    submission,');
//     buf.writeln('  ];');
//     buf.writeln('}');
//     buf.writeln();

//     // ResultData
//     buf.writeln('class $resultDataClass extends Equatable {');
//     buf.writeln('  const $resultDataClass({required this.message, this.id});');
//     buf.writeln('  final String message;');
//     buf.writeln('  final int? id;');
//     buf.writeln('  @override List<Object?> get props => [message, id];');
//     buf.writeln('}');

//     return buf.toString();
//   }
// }
