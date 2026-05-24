// lib/blocnew/bloc_generator.dart
//
// Generates 4 Dart source files for any feature:
//   1. <snake>_bloc.dart
//   2. <snake>_event.dart
//   3. <snake>_state.dart
//   4. async_value.dart   (shared – written once per bloc folder)
//
// ALL code is aligned to the REAL FieldSchema API in field_schema.dart:
//   field.fieldName, field.fieldType, field.label,
//   field.isRequired, field.pureDefault, field.dropdownValue,
//   field.staticStringValues, field.dropdownApiUrl, field.apiEnabled,
//   field.isAsyncDropdown, field.entityClassName

import 'field_schema.dart';

class BlocGenerator {
  BlocGenerator({
    required this.featureName,
    required this.fields,
  });

  final String featureName;
  final List<FieldSchema> fields;

  // ── derived ─────────────────────────────────────────────────────────────
  bool get _hasAsync => fields.any((f) => f.isAsyncDropdown);
  List<FieldSchema> get _asyncFields =>
      fields.where((f) => f.isAsyncDropdown).toList();

  // ════════════════════════════════════════════════════════════════════════
  // PUBLIC API  — call generateAll() to get every file at once
  // ════════════════════════════════════════════════════════════════════════

  /// Returns a map of  filename → file content  for every file that must be
  /// written to the bloc folder.
  ///
  ///   {
  ///     'personal_form_bloc.dart'  : '...',
  ///     'personal_form_event.dart' : '...',
  ///     'personal_form_state.dart' : '...',
  ///     'async_value.dart'         : '...',
  ///   }
  Map<String, String> generateAll() {
    final snake = _snake(featureName);
    return {
      '${snake}_bloc.dart':  generateBloc(),
      '${snake}_event.dart': generateEvent(),
      '${snake}_state.dart': generateState(),
      'async_value.dart':    generateAsyncValue(),
    };
  }

  // ════════════════════════════════════════════════════════════════════════
  // 1. BLOC
  // ════════════════════════════════════════════════════════════════════════
  String generateBloc() {
    final b = StringBuffer();
    final snake = _snake(featureName);

    b.writeln("import 'package:flutter_bloc/flutter_bloc.dart';");
    b.writeln("import '${snake}_event.dart';");
    b.writeln("import '${snake}_state.dart';");
    b.writeln("import 'async_value.dart';");
    b.writeln("import '../../domain/usecases/${snake}_usecases.dart';");
    b.writeln("import '../../domain/entities/${snake}_entity.dart';");

    for (final f in _asyncFields) {
      final ucFile = _snake('Load${_cap(f.fieldName)}ListUseCase');
      b.writeln("import '../../domain/usecases/$ucFile.dart';");
    }
    for (final f in _asyncFields) {
      final eFile = _snake(f.entityClassName.replaceAll('Entity', ''));
      b.writeln("import '../../domain/entities/${eFile}_entity.dart';");
    }
    b.writeln();

    // class declaration
    b.writeln('class ${featureName}Bloc'
        ' extends Bloc<${featureName}Event, ${featureName}State> {');
    b.writeln('  final ${featureName}Usecases usecases;');
    for (final f in _asyncFields) {
      b.writeln(
          '  final Load${_cap(f.fieldName)}ListUseCase _${f.fieldName}ListUseCase;');
    }
    b.writeln();

    // constructor
    b.write('  ${featureName}Bloc({required this.usecases');
    for (final f in _asyncFields) {
      b.write(
          ',\n    required Load${_cap(f.fieldName)}ListUseCase ${f.fieldName}ListUseCase');
    }
    b.writeln('\n  })');
    if (_asyncFields.isNotEmpty) {
      final inits = _asyncFields
          .map((f) =>
              '      _${f.fieldName}ListUseCase = ${f.fieldName}ListUseCase')
          .join(',\n');
      b.writeln('      : $inits,');
      b.writeln('        super(${featureName}State.initial()) {');
    } else {
      b.writeln('      : super(${featureName}State.initial()) {');
    }

    // event handlers
    b.writeln(
        '    on<${featureName}ComponentUpdatedEvent>(_onComponentUpdated);');
    b.writeln(
        '    on<${featureName}BatchComponentUpdatedEvent>(_onBatchComponentUpdated);');
    if (_hasAsync) {
      b.writeln('    on<Load${featureName}DataEvent>(_onLoadData);');
    }
    b.writeln('    on<Submit${featureName}Event>(_onSubmit);');
    b.writeln('    on<Reset${featureName}Event>(_onReset);');
    b.writeln('  }');
    b.writeln();

    // _onComponentUpdated
    b.writeln('  void _onComponentUpdated(');
    b.writeln('    ${featureName}ComponentUpdatedEvent event,');
    b.writeln('    Emitter<${featureName}State> emit,');
    b.writeln('  ) {');
    b.writeln(
        '    final updated = state.componentRegistry[event.fieldName]!');
    b.writeln('        .copyWith(defaultValue: event.value);');
    b.writeln(
        '    emit(state.copyWithField(event.fieldName, updated));');
    b.writeln('  }');
    b.writeln();

    // _onBatchComponentUpdated
    b.writeln('  void _onBatchComponentUpdated(');
    b.writeln('    ${featureName}BatchComponentUpdatedEvent event,');
    b.writeln('    Emitter<${featureName}State> emit,');
    b.writeln('  ) {');
    b.writeln('    var s = state;');
    b.writeln('    event.updates.forEach((key, val) {');
    b.writeln('      final updated = s.componentRegistry[key]!');
    b.writeln('          .copyWith(defaultValue: val);');
    b.writeln('      s = s.copyWithField(key, updated);');
    b.writeln('    });');
    b.writeln('    emit(s);');
    b.writeln('  }');
    b.writeln();

    // _onLoadData
    if (_hasAsync) {
      b.writeln('  Future<void> _onLoadData(');
      b.writeln('    Load${featureName}DataEvent event,');
      b.writeln('    Emitter<${featureName}State> emit,');
      b.writeln('  ) async {');
      for (final f in _asyncFields) {
        b.writeln(
            '    final ${f.fieldName}Result = await _${f.fieldName}ListUseCase();');
        b.writeln('    ${f.fieldName}Result.fold(');
        b.writeln('      (failure) => emit(state.copyWith(');
        b.writeln('        ${f.fieldName}Async: AsyncValue.error(failure),');
        b.writeln('      )),');
        b.writeln('      (data) => emit(state.copyWith(');
        b.writeln('        ${f.fieldName}Async: AsyncValue.data(data),');
        b.writeln('      )),');
        b.writeln('    );');
      }
      b.writeln('  }');
      b.writeln();
    }

    // _onSubmit
    b.writeln('  Future<void> _onSubmit(');
    b.writeln('    Submit${featureName}Event event,');
    b.writeln('    Emitter<${featureName}State> emit,');
    b.writeln('  ) async {');
    b.writeln(
        '    emit(state.copyWith(submissionAsync: const AsyncValue.loading()));');
    b.writeln('    final formData = <String, dynamic>{');
    for (final f in fields) {
      b.writeln(
          "      '${f.fieldName}': state.componentRegistry['${f.fieldName}']!.defaultValue,");
    }
    b.writeln('    };');
    b.writeln('    final payload = ${featureName}Entity.fromJson(formData);');
    b.writeln('    final result = await usecases.execute(payload);');
    b.writeln('    result.fold(');
    b.writeln('      (failure) => emit(state.copyWith(');
    b.writeln('        submissionAsync: AsyncValue.error(failure),');
    b.writeln('      )),');
    b.writeln('      (data) => emit(state.copyWith(');
    b.writeln('        submissionAsync: AsyncValue.data(data),');
    b.writeln('      )),');
    b.writeln('    );');
    b.writeln('  }');
    b.writeln();

    // _onReset
    b.writeln('  void _onReset(');
    b.writeln('    Reset${featureName}Event event,');
    b.writeln('    Emitter<${featureName}State> emit,');
    b.writeln('  ) {');
    b.writeln('    emit(${featureName}State.initial());');
    b.writeln('  }');
    b.writeln('}');

    return b.toString();
  }

  // ════════════════════════════════════════════════════════════════════════
  // 2. EVENT
  // ════════════════════════════════════════════════════════════════════════
  String generateEvent() {
    final b = StringBuffer();

    b.writeln("import 'package:equatable/equatable.dart';");
    b.writeln();

    // abstract base
    b.writeln('abstract class ${featureName}Event extends Equatable {');
    b.writeln('  const ${featureName}Event();');
    b.writeln('  @override');
    b.writeln('  List<Object?> get props => [];');
    b.writeln('}');
    b.writeln();

    // ComponentUpdated
    b.writeln(
        'class ${featureName}ComponentUpdatedEvent extends ${featureName}Event {');
    b.writeln('  final String fieldName;');
    b.writeln('  final dynamic value;');
    b.writeln('  const ${featureName}ComponentUpdatedEvent({');
    b.writeln('    required this.fieldName,');
    b.writeln('    required this.value,');
    b.writeln('  });');
    b.writeln('  @override');
    b.writeln('  List<Object?> get props => [fieldName, value];');
    b.writeln('}');
    b.writeln();

    // BatchComponentUpdated
    b.writeln(
        'class ${featureName}BatchComponentUpdatedEvent extends ${featureName}Event {');
    b.writeln('  final Map<String, dynamic> updates;');
    b.writeln('  const ${featureName}BatchComponentUpdatedEvent({');
    b.writeln('    required this.updates,');
    b.writeln('  });');
    b.writeln('  @override');
    b.writeln('  List<Object?> get props => [updates];');
    b.writeln('}');
    b.writeln();

    // LoadData (only when async dropdowns exist)
    if (_hasAsync) {
      b.writeln(
          'class Load${featureName}DataEvent extends ${featureName}Event {');
      b.writeln('  const Load${featureName}DataEvent();');
      b.writeln('}');
      b.writeln();
    }

    // Submit
    b.writeln(
        'class Submit${featureName}Event extends ${featureName}Event {');
    b.writeln('  const Submit${featureName}Event();');
    b.writeln('}');
    b.writeln();

    // Reset
    b.writeln(
        'class Reset${featureName}Event extends ${featureName}Event {');
    b.writeln('  const Reset${featureName}Event();');
    b.writeln('}');

    return b.toString();
  }

  // ════════════════════════════════════════════════════════════════════════
  // 3. STATE
  // ════════════════════════════════════════════════════════════════════════
  String generateState() {
    final b = StringBuffer();
    final snake = _snake(featureName);

    b.writeln("import 'package:equatable/equatable.dart';");
    b.writeln("import 'async_value.dart';");
    // FieldSchema import — adjust path to where field_schema.dart lives in your project
    b.writeln("import 'package:revojourneytryone/blocnew/field_schema.dart';");
    b.writeln(
        "import '../../domain/entities/${snake}_entity.dart';");
    b.writeln();

    b.writeln('class ${featureName}State extends Equatable {');

    // async slots
    for (final f in _asyncFields) {
      b.writeln(
          '  final AsyncValue<List<${f.entityClassName}>> ${f.fieldName}Async;');
    }
    b.writeln(
        '  final AsyncValue<${featureName}Entity?> submissionAsync;');
    b.writeln('  final Map<String, FieldSchema> componentRegistry;');
    b.writeln();

    // const constructor
    b.writeln('  const ${featureName}State({');
    for (final f in _asyncFields) {
      b.writeln('    required this.${f.fieldName}Async,');
    }
    b.writeln('    required this.submissionAsync,');
    b.writeln('    required this.componentRegistry,');
    b.writeln('  });');
    b.writeln();

    // factory initial
    b.writeln('  factory ${featureName}State.initial() {');
    b.writeln('    return ${featureName}State(');
    for (final f in _asyncFields) {
      b.writeln(
          '      ${f.fieldName}Async: const AsyncValue.loading(),');
    }
    b.writeln('      submissionAsync: const AsyncValue.loading(),');
    b.writeln('      componentRegistry: {');
    for (final f in fields) {
      b.writeln("        '${f.fieldName}': FieldSchema(");
      b.writeln("          fieldName: '${f.fieldName}',");
      b.writeln('          fieldType: FieldType.${f.fieldType.name},');
      b.writeln("          label: '${_esc(f.label)}',");
      b.writeln(
          "          validationPattern: '${_esc(f.validationPattern)}',");
      b.writeln("          errorMessage: '${_esc(f.errorMessage)}',");
      b.writeln('          dropdownValue: ${_lit(f.dropdownValue)},');
      b.writeln('          isRequired: ${f.isRequired},');
      b.writeln('          defaultValue: ${f.pureDefault},');
      if (f.staticStringValues.isNotEmpty) {
        final list = f.staticStringValues.map((s) => "'${_esc(s)}'").join(', ');
        b.writeln('          staticStringValues: [$list],');
      }
      if (f.dropdownApiUrl.isNotEmpty) {
        b.writeln("          dropdownApiUrl: '${_esc(f.dropdownApiUrl)}',");
      }
      if (f.apiEnabled) {
        b.writeln('          apiEnabled: true,');
      }
      b.writeln('        ),');
    }
    b.writeln('      },');
    b.writeln('    );');
    b.writeln('  }');
    b.writeln();

    // copyWith
    b.writeln('  ${featureName}State copyWith({');
    for (final f in _asyncFields) {
      b.writeln(
          '    AsyncValue<List<${f.entityClassName}>>? ${f.fieldName}Async,');
    }
    b.writeln(
        '    AsyncValue<${featureName}Entity?>? submissionAsync,');
    b.writeln('    Map<String, FieldSchema>? componentRegistry,');
    b.writeln('  }) {');
    b.writeln('    return ${featureName}State(');
    for (final f in _asyncFields) {
      b.writeln(
          '      ${f.fieldName}Async: ${f.fieldName}Async ?? this.${f.fieldName}Async,');
    }
    b.writeln(
        '      submissionAsync: submissionAsync ?? this.submissionAsync,');
    b.writeln(
        '      componentRegistry: componentRegistry ?? this.componentRegistry,');
    b.writeln('    );');
    b.writeln('  }');
    b.writeln();

    // copyWithField
    b.writeln(
        '  ${featureName}State copyWithField(String fieldName, FieldSchema updated) {');
    b.writeln(
        '    final newReg = Map<String, FieldSchema>.from(componentRegistry)');
    b.writeln('      ..[fieldName] = updated;');
    b.writeln('    return copyWith(componentRegistry: newReg);');
    b.writeln('  }');
    b.writeln();

    // props
    b.writeln('  @override');
    b.writeln('  List<Object?> get props => [');
    for (final f in _asyncFields) {
      b.writeln('    ${f.fieldName}Async,');
    }
    b.writeln('    submissionAsync,');
    b.writeln('    componentRegistry,');
    b.writeln('  ];');
    b.writeln('}');

    return b.toString();
  }

  // ════════════════════════════════════════════════════════════════════════
  // 4. ASYNC VALUE  (shared utility — one copy per bloc folder)
  // ════════════════════════════════════════════════════════════════════════
  String generateAsyncValue() => """
import 'package:equatable/equatable.dart';

sealed class AsyncValue<T> extends Equatable {
  const AsyncValue();

  const factory AsyncValue.loading() = AsyncLoading<T>;
  const factory AsyncValue.data(T value) = AsyncData<T>;
  const factory AsyncValue.error(Object error) = AsyncError<T>;

  bool get isLoading => this is AsyncLoading<T>;
  bool get isData    => this is AsyncData<T>;
  bool get isError   => this is AsyncError<T>;

  T?      get data  => (this is AsyncData<T>)  ? (this as AsyncData<T>).value  : null;
  Object? get error => (this is AsyncError<T>) ? (this as AsyncError<T>).error : null;

  @override
  List<Object?> get props => [];
}

class AsyncLoading<T> extends AsyncValue<T> {
  const AsyncLoading();
}

class AsyncData<T> extends AsyncValue<T> {
  final T value;
  const AsyncData(this.value);
  @override
  List<Object?> get props => [value];
}

class AsyncError<T> extends AsyncValue<T> {
  final Object error;
  const AsyncError(this.error);
  @override
  List<Object?> get props => [error];
}
""";

  // legacy shim
  String generate() => generateBloc();

  // ── private helpers ──────────────────────────────────────────────────────

  String _snake(String s) {
    if (s.isEmpty) return s;
    final out = s.replaceAllMapped(
        RegExp(r'[A-Z]'), (m) => '_${m.group(0)!.toLowerCase()}');
    return out.startsWith('_') ? out.substring(1) : out;
  }

  String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  /// Escape single quotes inside string literals
  String _esc(String s) => s.replaceAll("'", "\\'");

  /// Dart literal for any runtime value (used in codegen output)
  String _lit(dynamic v) {
    if (v == null) return 'null';
    if (v is String) return v.isEmpty ? "''" : "'${_esc(v)}'";
    if (v is bool || v is num) return '$v';
    return 'null';
  }
}
