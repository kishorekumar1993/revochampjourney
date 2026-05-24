// lib/bloc/generators/bloc_generator.dart

import 'field_schema.dart';

class BlocGenerator {
  BlocGenerator({
    required this.featureName,
    required this.fields,
    required this.stateName,
    required this.mapperName,
    required this.validatorsName,
    required this.resultDataClass,
    this.runtimeImportPrefix = '../../../../core/runtime',
  });

  final String featureName;
  final List<FieldSchema> fields;
  final String stateName;
  final String mapperName;
  final String validatorsName;
  final String resultDataClass;
  final String runtimeImportPrefix;

  String generate() {
    final blocName = '${featureName}Bloc';
    final snakeName = _toSnakeCase(featureName);
    final keysClass = '${featureName}ComponentKeys';
    final asyncDropdowns = fields.where((f) => f.isAsyncDropdown).toList();
    final hasAsync = asyncDropdowns.isNotEmpty;
    final hasFile = fields.any((f) => f.isFileUpload);
    final buf = StringBuffer();

    // ── Imports ──────────────────────────────────────────────────────────
    buf.writeln("import 'package:flutter_bloc/flutter_bloc.dart';");
    if (hasFile) buf.writeln("import 'dart:io';");
    buf.writeln("import '$runtimeImportPrefix/base_reactive_bloc.dart';");
    buf.writeln("import '$runtimeImportPrefix/reactive_value.dart';");
    buf.writeln("import '$runtimeImportPrefix/async_state.dart';");
    buf.writeln("import '$runtimeImportPrefix/failure.dart';");
    buf.writeln("import '../events/${snakeName}_event.dart';");
    buf.writeln("import '../state/${snakeName}_feature_state.dart';");
    buf.writeln("import '../mapper/${snakeName}_mapper.dart';");
    buf.writeln("import '../../domain/usecases/${snakeName}_usecases.dart';");
    buf.writeln("import '../validation/${snakeName}_validators.dart';");
    for (final f in fields.where((f) => f.hasDropdownData)) {
      final es = _toSnakeCase(f.entityClassName.replaceAll('Entity', ''));
      buf.writeln("import '../../domain/entities/${es}_entity.dart';");
    }
    buf.writeln();

    // ── Class declaration ────────────────────────────────────────────────
    buf.writeln('class $blocName extends BaseReactiveBloc<${featureName}Event, $stateName> {');
    buf.writeln('  $blocName({');
    for (final f in asyncDropdowns) {
      buf.writeln('    required this.load${_toCap(f.fieldName)}ListUseCase,');
    }
    buf.writeln('    required this.submit${featureName}UseCase,');
    buf.writeln('  }) : super(const $stateName()) {');
    if (hasAsync) {
      buf.writeln('    registerSequentialEvent<Load${featureName}DataEvent>(_onLoadData);');
    }
    buf.writeln('    registerInputEvent<ComponentUpdatedEvent>(_onComponentUpdated);');
    buf.writeln('    on<BatchComponentUpdatedEvent>(_onBatchUpdated);');
    buf.writeln('    registerSubmitEvent<Submit${featureName}FormEvent>(_onSubmit);');
    buf.writeln('    on<Reset${featureName}FormEvent>(_onReset);');
    buf.writeln('  }');
    buf.writeln();

    for (final f in asyncDropdowns) {
      buf.writeln('  final Load${_toCap(f.fieldName)}ListUseCase load${_toCap(f.fieldName)}ListUseCase;');
    }
    buf.writeln('  final Submit${featureName}UseCase submit${featureName}UseCase;');
    buf.writeln();

    // ── componentValidators (returns full ValidationError?) ───────────────
    buf.writeln('  @override');
    buf.writeln('  Map<String, FunctionValidator<dynamic>> get componentValidators => {');
    for (final f in fields) {
      buf.writeln(
        "    $keysClass.${f.fieldName}: FunctionValidator<dynamic>("
        "(v) => $validatorsName.validate${_toCap(f.fieldName)}(v), "
        "code: '${_toSnakeCase(f.fieldName)}'),",
      );
    }
    buf.writeln('  };');
    buf.writeln();

    // ── componentUpdaters ─────────────────────────────────────────────────
    buf.writeln('  @override');
    buf.writeln('  Map<String, StateUpdater<$stateName>> get componentUpdaters => {');
    for (final f in fields) {
      final castStr = _castValue(f);
      buf.writeln(
        "    $keysClass.${f.fieldName}: (s, v, e) => "
        "s.copyWith(${f.fieldName}: ReactiveValue.dirty($castStr, error: e)),",
      );
    }
    buf.writeln('  };');
    buf.writeln();

    // ── allFields ────────────────────────────────────────────────────────
    buf.writeln('  @override');
    buf.writeln('  Iterable<ReactiveValue<dynamic>> get allFields => state.allFields;');
    buf.writeln();

    // ── _onLoadData ──────────────────────────────────────────────────────
    if (hasAsync) {
      buf.writeln('  Future<void> _onLoadData(Load${featureName}DataEvent event, Emitter<$stateName> emit) async {');
      final loadingArgs = asyncDropdowns.map((f) => '${f.fieldName}List: const AsyncLoading()').join(', ');
      buf.writeln('    emit(state.copyWith($loadingArgs));');
      buf.writeln();
      for (final f in asyncDropdowns) {
        buf.writeln('    final ${f.fieldName}Result = await load${_toCap(f.fieldName)}ListUseCase();');
        buf.writeln('    emit(state.copyWith(');
        buf.writeln('      ${f.fieldName}List: ${f.fieldName}Result.fold(');
        buf.writeln('        (failure) => AsyncFailure(Failure(message: failure.message, code: failure.code)),');
        buf.writeln('        (data) => data.isEmpty ? const AsyncEmpty() : AsyncSuccess(data),');
        buf.writeln('      ),');
        buf.writeln('    ));');
        buf.writeln();
      }
      buf.writeln('  }');
      buf.writeln();
    }

    // ── Event handlers ───────────────────────────────────────────────────
    buf.writeln('  void _onComponentUpdated(ComponentUpdatedEvent e, Emitter<$stateName> emit) =>');
    buf.writeln('      updateComponent(emit, e.componentKey, e.value);');
    buf.writeln();
    buf.writeln('  void _onBatchUpdated(BatchComponentUpdatedEvent e, Emitter<$stateName> emit) =>');
    buf.writeln('      batchUpdateComponents(emit, e.updates);');
    buf.writeln();
    buf.writeln('  Future<void> _onSubmit(Submit${featureName}FormEvent event, Emitter<$stateName> emit) async {');
    buf.writeln('    if (state.isSubmitting) return;');
    buf.writeln('    emit(_touchAllFields(state));');
    buf.writeln('    if (!isAllValid) return;');
    buf.writeln('    emit(state.copyWith(submission: const AsyncLoading()));');
    buf.writeln('    final entity = $mapperName.toEntity(state);');
    buf.writeln('    final result = await submit${featureName}UseCase(entity);');
    buf.writeln('    result.fold(');
    buf.writeln('      (f) => emit(state.copyWith(submission: AsyncFailure(Failure(message: f.message, code: f.code)))),');
    buf.writeln('      (d) => emit(state.copyWith(submission: AsyncSuccess($resultDataClass(message: d.message, id: d.id)))),');
    buf.writeln('    );');
    buf.writeln('  }');
    buf.writeln();
    if (hasAsync) {
      final copyArgs = asyncDropdowns.map((f) => '${f.fieldName}List: state.${f.fieldName}List').join(', ');
      buf.writeln('  void _onReset(Reset${featureName}FormEvent e, Emitter<$stateName> emit) => emit($stateName($copyArgs));');
    } else {
      buf.writeln('  void _onReset(Reset${featureName}FormEvent e, Emitter<$stateName> emit) => emit(const $stateName());');
    }
    buf.writeln();

    // ── _touchAllFields ──────────────────────────────────────────────────
    buf.writeln('  $stateName _touchAllFields($stateName s) {');
    buf.writeln('    var updated = s;');
    buf.writeln('    for (final entry in componentUpdaters.entries) {');
    buf.writeln('      final current = s.componentRegistry[entry.key];');
    buf.writeln('      if (current == null) continue;');
    buf.writeln('      final error = validateComponent(entry.key, current.value);');
    buf.writeln('      updated = entry.value(updated, current.value, error);');
    buf.writeln('    }');
    buf.writeln('    return updated;');
    buf.writeln('  }');
    buf.writeln('}');

    return buf.toString();
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  String _castValue(FieldSchema f) {
    if (f.isFileUpload) return 'v as File?';
    if (f.fieldType == FieldType.checkbox) return 'v as bool';
    if (f.fieldType == FieldType.date) return 'v as DateTime?';
    if (f.fieldType == FieldType.multiSelect) return 'v as List<String>';
    if (f.fieldType == FieldType.dropdown || f.fieldType == FieldType.asyncDropdown) {
      final cls = f.entityClassName.isNotEmpty ? f.entityClassName : 'String';
      return 'v as $cls?';
    }
    return 'v as String';
  }

  String _toSnakeCase(String input) {
    if (input.isEmpty) return input;
    final buffer = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final char = input[i];
      if (char.toUpperCase() == char && char.toLowerCase() != char) {
        if (i != 0) buffer.write('_');
        buffer.write(char.toLowerCase());
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  String _toCap(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }
}

// // lib/bloc/generators/bloc/bloc_generator.dart
// // v3: Fixes all Dart analysis errors in the generated BLoC:
// //   - componentValidators correctly typed as Map<String, FunctionValidator<dynamic>>
// //   - All required imports present (reactive_value, async_state subclasses, failure)
// //   - submit param name consistent with DI (submit${featureName}UseCase)
// //   - explicit .call tearoff to silence implicit_call_tearoffs lint

// import 'package:revojourneytryone/blocnew/field_schema.dart';

// class BlocGenerator {
//   BlocGenerator({
//     required this.featureName,
//     required this.fields,
//     required this.stateName,
//     required this.mapperName,
//     required this.validatorsName,
//     required this.resultDataClass,
//     this.runtimeImportPrefix = '../../../../core/runtime',
//   });

//   final String featureName;
//   final List<FieldSchema> fields;
//   final String stateName;
//   final String mapperName;
//   final String validatorsName;
//   final String resultDataClass;
//   final String runtimeImportPrefix;

//   String generate() {
//     final blocName       = '${featureName}Bloc';
//     final eventBase      = '${featureName}Event';
//     final keysClass      = '${featureName}ComponentKeys';
//     final snakeName      = toSnakeCase(featureName);
//     final asyncDropdowns = fields.where((f) => f.isAsyncDropdown).toList();
//     final hasAsync       = asyncDropdowns.isNotEmpty;
//     final hasFile        = fields.any((f) => f.isFileUpload);
//     final buf            = StringBuffer();

//     // ── Imports ──────────────────────────────────────────────────────────────
//     buf.writeln("import 'package:flutter_bloc/flutter_bloc.dart';");
//     if (hasFile) buf.writeln("import 'dart:io';");
//     buf.writeln("import '$runtimeImportPrefix/base_reactive_bloc.dart';");
//     // FIX: explicitly import ReactiveValue — used in componentUpdaters map
//     buf.writeln("import '$runtimeImportPrefix/reactive_value.dart';");
//     // FIX: explicitly import async_state subclasses used in _onLoadData/_onSubmit
//     buf.writeln("import '$runtimeImportPrefix/async_state.dart';");
//     // FIX: Failure class used in AsyncFailure(Failure(...))
//     buf.writeln("import '$runtimeImportPrefix/failure.dart';");
//     // ValidationError is used only in validators file, not in the BLoC directly
//     buf.writeln("import '../events/${snakeName}_event.dart';");
//     buf.writeln("import '../state/${snakeName}_feature_state.dart';");
//     buf.writeln("import '../mapper/${snakeName}_mapper.dart';");
//     buf.writeln("import '../../domain/usecases/${snakeName}_usecases.dart';");
//     buf.writeln("import '../validation/${snakeName}_validators.dart';");
//     for (final f in fields.where((f) => f.hasDropdownData)) {
//       final es = toSnakeCase(f.entityClassName.replaceAll('Entity', ''));
//       buf.writeln("import '../../domain/entities/${es}_entity.dart';");
//     }
//     buf.writeln();

//     // ── Class declaration ────────────────────────────────────────────────────
//     buf.writeln('class $blocName extends BaseReactiveBloc<$eventBase, $stateName> {');
//     buf.writeln('  $blocName({');
//     for (final f in asyncDropdowns) {
//       buf.writeln('    required this.load${toCap(f.fieldName)}ListUseCase,');
//     }
//     // FIX: param name is submit${featureName}UseCase (matches DI generator)
//     buf.writeln('    required this.submit${featureName}UseCase,');
//     buf.writeln('  }) : super(const $stateName()) {');
//     if (hasAsync) {
//       buf.writeln(
//         '    registerSequentialEvent<Load${featureName}DataEvent>(_onLoadData);');
//     }
//     buf.writeln('    registerInputEvent<ComponentUpdatedEvent>(_onComponentUpdated);');
//     buf.writeln('    on<BatchComponentUpdatedEvent>(_onBatchUpdated);');
//     buf.writeln('    registerSubmitEvent<Submit${featureName}FormEvent>(_onSubmit);');
//     buf.writeln('    on<Reset${featureName}FormEvent>(_onReset);');
//     buf.writeln('  }');
//     buf.writeln();

//     for (final f in asyncDropdowns) {
//       buf.writeln(
//         '  final Load${toCap(f.fieldName)}ListUseCase '
//         'load${toCap(f.fieldName)}ListUseCase;');
//     }
//     buf.writeln('  final Submit${featureName}UseCase submit${featureName}UseCase;');
//     buf.writeln();

//     // ── componentValidators ──────────────────────────────────────────────────
//     // FIX: return type must match base: Map<String, FunctionValidator<dynamic>>
//     // FIX: explicit .call tearoff silences implicit_call_tearoffs lint
//     buf.writeln('  @override');
//     buf.writeln('  Map<String, FunctionValidator<dynamic>> get componentValidators => {');
//     for (final f in fields) {
//       final paramType = _validatorParamType(f);
//       buf.writeln(
//         "    $keysClass.${f.fieldName}: FunctionValidator<$paramType>("
//         "(v) => $validatorsName.validate${toCap(f.fieldName)}(v), "
//         "code: '${f.snakeFieldName}'),",
//       );
//     }
//     buf.writeln('  };');
//     buf.writeln();

//     // ── componentUpdaters ────────────────────────────────────────────────────
//     buf.writeln('  @override');
//     buf.writeln('  Map<String, StateUpdater<$stateName>> get componentUpdaters => {');
//     for (final f in fields) {
//       final castStr = _castValue(f);
//       buf.writeln(
//         "    $keysClass.${f.fieldName}: (s, v, e) => "
//         "s.copyWith(${f.fieldName}: ReactiveValue.dirty($castStr, error: e)),",
//       );
//     }
//     buf.writeln('  };');
//     buf.writeln();

//     // ── allFields ────────────────────────────────────────────────────────────
//     buf.writeln('  @override');
//     buf.writeln('  Iterable<ReactiveValue<dynamic>> get allFields => state.allFields;');
//     buf.writeln();

//     // ── _onLoadData ──────────────────────────────────────────────────────────
//     if (hasAsync) {
//       buf.writeln('  Future<void> _onLoadData(');
//       buf.writeln(
//         '    Load${featureName}DataEvent event, Emitter<$stateName> emit) async {');
//       final loadingArgs = asyncDropdowns
//           .map((f) => '${f.fieldName}List: const AsyncLoading()')
//           .join(', ');
//       buf.writeln('    emit(state.copyWith($loadingArgs));');
//       buf.writeln();
//       for (final f in asyncDropdowns) {
//         buf.writeln(
//           '    final ${f.fieldName}Result = '
//           'await load${toCap(f.fieldName)}ListUseCase();');
//         buf.writeln('    emit(state.copyWith(');
//         buf.writeln('      ${f.fieldName}List: ${f.fieldName}Result.fold(');
//         buf.writeln(
//           '        (failure) => AsyncFailure(Failure('
//           "message: failure.message, code: failure.code)),");
//         buf.writeln(
//           '        (data) => data.isEmpty '
//           '? const AsyncEmpty() : AsyncSuccess(data),');
//         buf.writeln('      ),');
//         buf.writeln('    ));');
//         buf.writeln();
//       }
//       buf.writeln('  }');
//       buf.writeln();
//     }

//     // ── _onComponentUpdated ───────────────────────────────────────────────────
//     buf.writeln(
//       '  void _onComponentUpdated('
//       'ComponentUpdatedEvent e, Emitter<$stateName> emit) =>');
//     buf.writeln('      updateComponent(emit, e.componentKey, e.value);');
//     buf.writeln();

//     // ── _onBatchUpdated ───────────────────────────────────────────────────────
//     buf.writeln(
//       '  void _onBatchUpdated('
//       'BatchComponentUpdatedEvent e, Emitter<$stateName> emit) =>');
//     buf.writeln('      batchUpdateComponents(emit, e.updates);');
//     buf.writeln();

//     // ── _onSubmit ─────────────────────────────────────────────────────────────
//     buf.writeln('  Future<void> _onSubmit(');
//     buf.writeln(
//       '    Submit${featureName}FormEvent event, Emitter<$stateName> emit) async {');
//     buf.writeln('    if (state.isSubmitting) return;');
//     buf.writeln('    emit(_touchAllFields(state));');
//     buf.writeln('    if (!isAllValid) return;');
//     buf.writeln('    emit(state.copyWith(submission: const AsyncLoading()));');
//     buf.writeln('    final entity = $mapperName.toEntity(state);');
//     // FIX: param name matches constructor
//     buf.writeln('    final result = await submit${featureName}UseCase(entity);');
//     buf.writeln('    result.fold(');
//     buf.writeln(
//       '      (f) => emit(state.copyWith(submission: AsyncFailure('
//       'Failure(message: f.message, code: f.code)))),');
//     buf.writeln(
//       '      (d) => emit(state.copyWith(submission: AsyncSuccess('
//       '$resultDataClass(message: d.message, id: d.id)))),');
//     buf.writeln('    );');
//     buf.writeln('  }');
//     buf.writeln();

//     // ── _onReset ──────────────────────────────────────────────────────────────
//     if (hasAsync) {
//       final copyArgs = asyncDropdowns
//           .map((f) => '${f.fieldName}List: state.${f.fieldName}List')
//           .join(', ');
//       buf.writeln(
//         '  void _onReset(Reset${featureName}FormEvent e, '
//         'Emitter<$stateName> emit) =>');
//       buf.writeln('      emit($stateName($copyArgs));');
//     } else {
//       buf.writeln(
//         '  void _onReset(Reset${featureName}FormEvent e, '
//         'Emitter<$stateName> emit) =>');
//       buf.writeln('      emit(const $stateName());');
//     }
//     buf.writeln();

//     // ── _touchAllFields ───────────────────────────────────────────────────────
//     buf.writeln('  $stateName _touchAllFields($stateName s) {');
//     buf.writeln('    var updated = s;');
//     buf.writeln('    for (final entry in componentUpdaters.entries) {');
//     buf.writeln('      final current = s.componentRegistry[entry.key];');
//     buf.writeln('      if (current == null) continue;');
//     buf.writeln('      final error = validateComponent(entry.key, current.value);');
//     buf.writeln('      updated = entry.value(updated, current.value, error);');
//     buf.writeln('    }');
//     buf.writeln('    return updated;');
//     buf.writeln('  }');
//     buf.writeln('}');

//     return buf.toString();
//   }

//   // ── Helpers ───────────────────────────────────────────────────────────────

//   String _castValue(FieldSchema f) {
//     if (f.isFileUpload) return 'v as File?';
//     if (f.fieldType == FieldType.checkbox) return 'v as bool';
//     if (f.fieldType == FieldType.date) return 'v as DateTime?';
//     if (f.fieldType == FieldType.multiSelect) return 'v as List<String>';
//     if (f.fieldType == FieldType.dropdown ||
//         f.fieldType == FieldType.asyncDropdown) {
//       final cls =
//           f.entityClassName.isNotEmpty ? f.entityClassName : 'String';
//       return 'v as $cls?';
//     }
//     return 'v as String';
//   }

//   // _validatorParamType: the type T in FunctionValidator<T> must match
//   // the runtime type of the value stored in ReactiveValue<T>.
//   // For dropdown/asyncDropdown fields the value is an Entity?, not String?.
//   // Using 'dynamic' for those avoids a type-mismatch between the
//   // FunctionValidator's inner function signature and the validator method
//   // which accepts the entity (or null).
//   String _validatorParamType(FieldSchema f) {
//     if (f.isFileUpload) return 'dynamic';
//     if (f.fieldType == FieldType.checkbox) return 'bool';
//     if (f.fieldType == FieldType.date) return 'DateTime?';
//     if (f.fieldType == FieldType.multiSelect) return 'List<String>';
//     // FIX: dropdown/asyncDropdown values are entity objects, not strings.
//     // Use dynamic so FunctionValidator<dynamic> accepts any entity type.
//     if (f.fieldType == FieldType.dropdown ||
//         f.fieldType == FieldType.asyncDropdown) {
//       return 'dynamic';
//     }
//     return 'String?';
//   }
// }
