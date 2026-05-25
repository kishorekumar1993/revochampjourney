// lib/blocnew/bloc_generator.dart

// ─── Recursive flatten — same as all other generators ─────────────
List<Map<String, dynamic>> flattenBlocFields(dynamic source) {
  final result = <Map<String, dynamic>>[];
  void traverse(dynamic node) {
    if (node == null) return;
    if (node is List) {
      for (final item in node) {
        traverse(item);
      }
      return;
    }
    if (node is! Map<String, dynamic>) return;
    if (node.containsKey('steps')) {
      traverse(node['steps']);
      return;
    }
    if (node.containsKey('fields')) {
      traverse(node['fields']);
      return;
    }
    if (node.containsKey('type')) {
      result.add(node);
      traverse(node['nestedFields']);
      final config = node['componentConfig'];
      if (config is Map) {
        traverse(config['fields']);
        traverse(config['columns']);
      }
    }
  }
  traverse(source);
  return result;
}

// ─── isApiDropdown guard — same as all other generators ───────────
bool _isApiDropdown(Map<String, dynamic> field) {
  final type = (field['type'] ?? '').toString().toLowerCase();
  if (type != 'dropdown' && type != 'api_dropdown') return false;
  final useStatic = field['useStaticOptions'] == true;
  final hasApiUrl = field['dropdownApiUrl'] != null;
  final staticOpts = (field['options'] as List<dynamic>?) ??
      (field['staticOptions'] as List<dynamic>?);
  if (!useStatic && hasApiUrl) return true;
  if (!useStatic && (staticOpts == null || staticOpts.isEmpty)) return true;
  return false;
}

// ─── Resolve names from JSON field ────────────────────────────────
String _fieldName(Map<String, dynamic> f) {
  final raw =
      (f['label'] ?? f['id'] ?? f['fieldId'] ?? 'field').toString().trim();
  final n = raw.replaceAll(RegExp(r'\s+'), '');
  return n.isEmpty ? 'field' : n[0].toLowerCase() + n.substring(1);
}

String _fieldPascal(Map<String, dynamic> f) {
  final n = _fieldName(f);
  return n.isEmpty ? 'Field' : n[0].toUpperCase() + n.substring(1);
}

String _resolveEntityClass(Map<String, dynamic> field) {
  final dropdowndata = field['dropdowndata'];
  if (dropdowndata is Map<String, dynamic>) {
    for (final entry in dropdowndata.entries) {
      final v = entry.value;
      if (v is List && v.isNotEmpty && v.first is Map<String, dynamic>) {
        return '${_cap(_singularize(entry.key))}Entity';
      }
    }
  }
  return '${_fieldPascal(field)}Entity';
}

String _resolveEntityFile(Map<String, dynamic> field) {
  final dropdowndata = field['dropdowndata'];
  if (dropdowndata is Map<String, dynamic>) {
    for (final entry in dropdowndata.entries) {
      final v = entry.value;
      if (v is List && v.isNotEmpty && v.first is Map<String, dynamic>) {
        return _snake(_singularize(entry.key));
      }
    }
  }
  return _snake(_fieldName(field));
}

String _snake(String s) {
  if (s.isEmpty) return s;
  final out = s.replaceAllMapped(
      RegExp(r'[A-Z]'), (m) => '_${m.group(0)!.toLowerCase()}');
  return out.startsWith('_') ? out.substring(1) : out;
}

String _cap(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

String _esc(String s) => s.replaceAll("'", "\\'");

String _lit(dynamic v) {
  if (v == null) return 'null';
  if (v is String) return v.isEmpty ? "''" : "'${_esc(v)}'";
  if (v is bool || v is num) return '$v';
  return 'null';
}

String _singularize(String text) {
  if (text.endsWith('ies')) {
    return '${text.substring(0, text.length - 3)}y';
  }
  if (text.endsWith('s') && text.length > 1) {
    return text.substring(0, text.length - 1);
  }
  return text;
}

// ─── No double-s guard ────────────────────────────────────────────
String _withS(String name) {
  return name.toLowerCase().endsWith('s') ? name : '${name}s';
}

// ══════════════════════════════════════════════════════════════════
// BlocGenerator
// ══════════════════════════════════════════════════════════════════
class BlocGenerator {
  BlocGenerator({
    required this.featureName,
    // ✅ FIX 1: accept raw JSON configList instead of FieldSchema list
    required this.configList,
    // ✅ FIX 3: hasSubmit driven by caller — not always generated
    this.hasSubmit = false,
    // ✅ FIX 7: honour the flag
    this.generateAsyncValueSeparately = false,
  });

  final String featureName;
  final List<dynamic> configList;
  final bool hasSubmit;
  final bool generateAsyncValueSeparately;

  // ── derived from JSON ──────────────────────────────────────────
  late final List<Map<String, dynamic>> _flatFields =
      flattenBlocFields(configList);

  late final List<Map<String, dynamic>> _asyncFields =
      _flatFields.where((f) => _isApiDropdown(f)).toList();

  bool get _hasAsync => _asyncFields.isNotEmpty;

  // ── public API ─────────────────────────────────────────────────
  Map<String, String> generateAll() {
    final snake = _snake(featureName);
    final files = <String, String>{
      '${snake}_bloc.dart': generateBloc(),
      '${snake}_event.dart': generateEvent(),
      '${snake}_state.dart': generateState(),
    };
    // ✅ FIX 7: only emit async_value.dart when NOT separate
    if (!generateAsyncValueSeparately) {
      files['async_value.dart'] = generateAsyncValue();
    }
    return files;
  }

  // ════════════════════════════════════════════════════════════════
  // 1. BLOC
  // ════════════════════════════════════════════════════════════════
  String generateBloc() {
    final b = StringBuffer();
    final snake = _snake(featureName);

    b.writeln("import 'package:flutter_bloc/flutter_bloc.dart';");
    b.writeln("import '${snake}_event.dart';");
    b.writeln("import '${snake}_state.dart';");
    b.writeln("import 'async_value.dart';");
    // ✅ FIX 6: single shared usecases import — not one per field
    b.writeln(
        "import '../../domain/usecases/${snake}_usecases.dart';");

    if (hasSubmit) {
      b.writeln(
          "import '../../domain/entities/${snake}_entity.dart';");
    }

    // ✅ FIX 1: entity imports derived from JSON dropdowndata keys
    final importedEntityFiles = <String>{};
    for (final f in _asyncFields) {
      final eFile = _resolveEntityFile(f);
      if (importedEntityFiles.add(eFile)) {
        b.writeln(
            "import '../../domain/entities/${eFile}_entity.dart';");
      }
    }
    b.writeln();

    // class declaration
    b.writeln(
        'class ${featureName}Bloc extends Bloc<${featureName}Event, ${featureName}State> {');
    b.writeln('  final ${featureName}Usecases usecases;');
    b.writeln();

    // constructor — single usecases param; no per-field use case injection
    // ✅ FIX 6: usecases facade handles all operations
    b.writeln(
        '  ${featureName}Bloc({required this.usecases})');
    b.writeln(
        '      : super(${featureName}State.initial()) {');

    b.writeln(
        '    on<${featureName}FieldChangedEvent>(_onFieldChanged);');
    b.writeln(
        '    on<${featureName}BatchUpdateEvent>(_onBatchUpdate);');
    if (_hasAsync) {
      b.writeln(
          '    on<Load${featureName}DataEvent>(_onLoadData);');
    }
    // ✅ FIX 3: submit handler only when hasSubmit
    if (hasSubmit) {
      b.writeln(
          '    on<Submit${featureName}Event>(_onSubmit);');
    }
    b.writeln(
        '    on<Reset${featureName}Event>(_onReset);');
    b.writeln('  }');
    b.writeln();

    // _onFieldChanged
    b.writeln('  void _onFieldChanged(');
    b.writeln(
        '    ${featureName}FieldChangedEvent event,');
    b.writeln(
        '    Emitter<${featureName}State> emit,');
    b.writeln('  ) {');
    b.writeln(
        '    emit(state.copyWithValue(event.fieldName, event.value));');
    b.writeln('  }');
    b.writeln();

    // _onBatchUpdate
    b.writeln('  void _onBatchUpdate(');
    b.writeln(
        '    ${featureName}BatchUpdateEvent event,');
    b.writeln(
        '    Emitter<${featureName}State> emit,');
    b.writeln('  ) {');
    b.writeln('    var s = state;');
    b.writeln(
        '    event.updates.forEach((key, val) {');
    b.writeln('      s = s.copyWithValue(key, val);');
    b.writeln('    });');
    b.writeln('    emit(s);');
    b.writeln('  }');
    b.writeln();

    // _onLoadData — ✅ FIX 6: calls usecases.load*() not separate use cases
    if (_hasAsync) {
      b.writeln('  Future<void> _onLoadData(');
      b.writeln(
          '    Load${featureName}DataEvent event,');
      b.writeln(
          '    Emitter<${featureName}State> emit,');
      b.writeln('  ) async {');

      for (final f in _asyncFields) {
        final fName = _fieldName(f);
        final fPascal = _fieldPascal(f);
        final method = _withS('load${fPascal}');

        b.writeln(
            '    emit(state.copyWith(${fName}Async: const AsyncValue.loading()));');
        b.writeln(
            '    final ${fName}Result = await usecases.$method();');
        b.writeln('    ${fName}Result.fold(');
        b.writeln(
            '      (failure) => emit(state.copyWith(');
        b.writeln(
            '        ${fName}Async: AsyncValue.error(failure),');
        b.writeln('      )),');
        b.writeln(
            '      (data) => emit(state.copyWith(');
        b.writeln(
            '        ${fName}Async: AsyncValue.data(data),');
        b.writeln('      )),');
        b.writeln('    );');
      }
      b.writeln('  }');
      b.writeln();
    }

    // _onSubmit — ✅ FIX 3 + FIX 5: only when hasSubmit
    if (hasSubmit) {
      b.writeln('  Future<void> _onSubmit(');
      b.writeln(
          '    Submit${featureName}Event event,');
      b.writeln(
          '    Emitter<${featureName}State> emit,');
      b.writeln('  ) async {');
      b.writeln(
          '    emit(state.copyWith(submissionAsync: const AsyncValue.loading()));');
      b.writeln(
          '    final payload = ${featureName}Entity.fromJson(state.formValues);');
      b.writeln(
          '    final result = await usecases.execute(payload);');
      b.writeln('    result.fold(');
      b.writeln('      (failure) => emit(state.copyWith(');
      b.writeln(
          '        submissionAsync: AsyncValue.error(failure),');
      b.writeln('      )),');
      b.writeln('      (data) => emit(state.copyWith(');
      b.writeln(
          '        submissionAsync: AsyncValue.data(data),');
      b.writeln('      )),');
      b.writeln('    );');
      b.writeln('  }');
      b.writeln();
    }

    // _onReset
    b.writeln('  void _onReset(');
    b.writeln(
        '    Reset${featureName}Event event,');
    b.writeln(
        '    Emitter<${featureName}State> emit,');
    b.writeln('  ) {');
    b.writeln(
        '    emit(${featureName}State.initial());');
    b.writeln('  }');
    b.writeln('}');

    return b.toString();
  }

  // ════════════════════════════════════════════════════════════════
  // 2. EVENT
  // ════════════════════════════════════════════════════════════════
  String generateEvent() {
    final b = StringBuffer();

    b.writeln("import 'package:equatable/equatable.dart';");
    b.writeln();

    // abstract base
    b.writeln(
        'abstract class ${featureName}Event extends Equatable {');
    b.writeln('  const ${featureName}Event();');
    b.writeln('  @override');
    b.writeln('  List<Object?> get props => [];');
    b.writeln('}');
    b.writeln();

    // ✅ renamed: ComponentUpdated → FieldChanged (cleaner)
    b.writeln(
        'class ${featureName}FieldChangedEvent extends ${featureName}Event {');
    b.writeln('  final String fieldName;');
    b.writeln('  final dynamic value;');
    b.writeln(
        '  const ${featureName}FieldChangedEvent({');
    b.writeln('    required this.fieldName,');
    b.writeln('    required this.value,');
    b.writeln('  });');
    b.writeln('  @override');
    b.writeln(
        '  List<Object?> get props => [fieldName, value];');
    b.writeln('}');
    b.writeln();

    // BatchUpdate
    b.writeln(
        'class ${featureName}BatchUpdateEvent extends ${featureName}Event {');
    b.writeln('  final Map<String, dynamic> updates;');
    b.writeln(
        '  const ${featureName}BatchUpdateEvent({');
    b.writeln('    required this.updates,');
    b.writeln('  });');
    b.writeln('  @override');
    b.writeln('  List<Object?> get props => [updates];');
    b.writeln('}');
    b.writeln();

    // LoadData
    if (_hasAsync) {
      b.writeln(
          'class Load${featureName}DataEvent extends ${featureName}Event {');
      b.writeln(
          '  const Load${featureName}DataEvent();');
      b.writeln('}');
      b.writeln();
    }

    // Submit — ✅ FIX 3: only when hasSubmit
    if (hasSubmit) {
      b.writeln(
          'class Submit${featureName}Event extends ${featureName}Event {');
      b.writeln(
          '  const Submit${featureName}Event();');
      b.writeln('}');
      b.writeln();
    }

    // Reset
    b.writeln(
        'class Reset${featureName}Event extends ${featureName}Event {');
    b.writeln(
        '  const Reset${featureName}Event();');
    b.writeln('}');

    return b.toString();
  }

  // ════════════════════════════════════════════════════════════════
  // 3. STATE
  // ════════════════════════════════════════════════════════════════
  String generateState() {
    final b = StringBuffer();
    final snake = _snake(featureName);

    b.writeln("import 'package:equatable/equatable.dart';");
    b.writeln("import 'async_value.dart';");

    // ✅ FIX 8: no FieldSchema in state — use plain Map<String, dynamic>
    // Entity imports for async dropdown types
    final importedEntityFiles = <String>{};
    for (final f in _asyncFields) {
      final eFile = _resolveEntityFile(f);
      if (importedEntityFiles.add(eFile)) {
        b.writeln(
            "import '../../domain/entities/${eFile}_entity.dart';");
      }
    }
    if (hasSubmit) {
      b.writeln(
          "import '../../domain/entities/${snake}_entity.dart';");
    }
    b.writeln();

    b.writeln(
        'class ${featureName}State extends Equatable {');

    // async slots for dropdowns
    for (final f in _asyncFields) {
      final fName = _fieldName(f);
      final entityClass = _resolveEntityClass(f);
      b.writeln(
          '  final AsyncValue<List<$entityClass>> ${fName}Async;');
    }

    // submission slot — only when hasSubmit
    if (hasSubmit) {
      b.writeln(
          '  final AsyncValue<${featureName}Entity?> submissionAsync;');
    }

    // ✅ FIX 8: plain Map<String, dynamic> instead of FieldSchema
    b.writeln(
        '  final Map<String, dynamic> formValues;');
    b.writeln();

    // const constructor
    b.writeln('  const ${featureName}State({');
    for (final f in _asyncFields) {
      final fName = _fieldName(f);
      b.writeln('    required this.${fName}Async,');
    }
    if (hasSubmit) {
      b.writeln('    required this.submissionAsync,');
    }
    b.writeln('    required this.formValues,');
    b.writeln('  });');
    b.writeln();

    // factory initial
    b.writeln('  factory ${featureName}State.initial() {');
    b.writeln('    return ${featureName}State(');
    for (final f in _asyncFields) {
      final fName = _fieldName(f);
      // ✅ FIX 4: initial state is idle not loading
      b.writeln(
          '      ${fName}Async: const AsyncValue.idle(),');
    }
    if (hasSubmit) {
      b.writeln(
          '      submissionAsync: const AsyncValue.idle(),');
    }

    // ✅ FIX 1: formValues derived from JSON flatFields — includes nested
    b.writeln('      formValues: {');
    for (final f in _flatFields) {
      final fName = _fieldName(f);
      final type = (f['type'] ?? '').toString().toLowerCase();
      final defaultVal = _resolveDefault(f, type);
      b.writeln("        '$fName': $defaultVal,");
    }
    b.writeln('      },');
    b.writeln('    );');
    b.writeln('  }');
    b.writeln();

    // copyWith
    b.writeln('  ${featureName}State copyWith({');
    for (final f in _asyncFields) {
      final fName = _fieldName(f);
      final entityClass = _resolveEntityClass(f);
      b.writeln(
          '    AsyncValue<List<$entityClass>>? ${fName}Async,');
    }
    if (hasSubmit) {
      b.writeln(
          '    AsyncValue<${featureName}Entity?>? submissionAsync,');
    }
    b.writeln(
        '    Map<String, dynamic>? formValues,');
    b.writeln('  }) {');
    b.writeln('    return ${featureName}State(');
    for (final f in _asyncFields) {
      final fName = _fieldName(f);
      b.writeln(
          '      ${fName}Async: ${fName}Async ?? this.${fName}Async,');
    }
    if (hasSubmit) {
      b.writeln(
          '      submissionAsync: submissionAsync ?? this.submissionAsync,');
    }
    b.writeln(
        '      formValues: formValues ?? this.formValues,');
    b.writeln('    );');
    b.writeln('  }');
    b.writeln();

    // ✅ copyWithValue — clean helper used by _onFieldChanged
    b.writeln(
        '  ${featureName}State copyWithValue(String key, dynamic value) {');
    b.writeln(
        '    final updated = Map<String, dynamic>.from(formValues)..[key] = value;');
    b.writeln('    return copyWith(formValues: updated);');
    b.writeln('  }');
    b.writeln();

    // props
    b.writeln('  @override');
    b.writeln('  List<Object?> get props => [');
    for (final f in _asyncFields) {
      b.writeln('    ${_fieldName(f)}Async,');
    }
    if (hasSubmit) b.writeln('    submissionAsync,');
    b.writeln('    formValues,');
    b.writeln('  ];');
    b.writeln('}');

    return b.toString();
  }

  // ════════════════════════════════════════════════════════════════
  // 4. ASYNC VALUE — ✅ FIX 4: added idle() factory
  // ════════════════════════════════════════════════════════════════
  String generateAsyncValue() => """
import 'package:equatable/equatable.dart';

sealed class AsyncValue<T> extends Equatable {
  const AsyncValue();

  const factory AsyncValue.idle()              = AsyncIdle<T>;
  const factory AsyncValue.loading()           = AsyncLoading<T>;
  const factory AsyncValue.data(T value)       = AsyncData<T>;
  const factory AsyncValue.error(Object error) = AsyncError<T>;

  bool get isIdle    => this is AsyncIdle<T>;
  bool get isLoading => this is AsyncLoading<T>;
  bool get isData    => this is AsyncData<T>;
  bool get isError   => this is AsyncError<T>;

  T?      get data  => (this is AsyncData<T>)  ? (this as AsyncData<T>).value  : null;
  Object? get error => (this is AsyncError<T>) ? (this as AsyncError<T>).error : null;

  R when<R>({
    required R Function() idle,
    required R Function() loading,
    required R Function(T value) data,
    required R Function(Object error) error,
  }) {
    if (this is AsyncIdle<T>)    return idle();
    if (this is AsyncLoading<T>) return loading();
    if (this is AsyncData<T>)    return data((this as AsyncData<T>).value);
    if (this is AsyncError<T>)   return error((this as AsyncError<T>).error);
    throw StateError('Unknown AsyncValue subtype');
  }

  @override
  List<Object?> get props => [];
}

class AsyncIdle<T> extends AsyncValue<T> {
  const AsyncIdle();
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

  // ── Default value resolver ─────────────────────────────────────
  String _resolveDefault(Map<String, dynamic> field, String type) {
    final defaultVal = field['defaultValue'];
    if (defaultVal != null) return _lit(defaultVal);

    switch (type) {
      case 'text':
      case 'textfield':
      case 'textarea':
      case 'email':
      case 'password':
      case 'phone':
      case 'otp':
      case 'date':
      case 'datetime':
      case 'date time':
      case 'time':
      case 'formula':
        return "''";
      case 'number':
      case 'integer':
      case 'int':
        return '0';
      case 'decimal':
      case 'double':
      case 'float':
      case 'slider':
      case 'range slider':
        return '0.0';
      case 'checkbox':
      case 'switch':
        return 'false';
      case 'multiselect':
      case 'multi select':
      case 'multi_select':
        return '<String>[]';
      case 'dropdown':
      case 'api_dropdown':
      case 'radio':
      case 'radio buttons':
        return 'null';
      default:
        return 'null';
    }
  }
}