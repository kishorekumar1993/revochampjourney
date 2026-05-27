// lib/blocnew/bloc_generator.dart

import 'package:revojourneytryone/filegegnerator/journey_step_codegen.dart';

// ─── Recursive flatten ─────────────────────────────────────────────
List<Map<String, dynamic>> flattenBlocFields(dynamic source) {
  final result = <Map<String, dynamic>>[];
  void traverse(dynamic node) {
    if (node == null) return;
    if (node is List) {
      for (final item in node) traverse(item);
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

// ─── isApiDropdown guard ──────────────────────────────────────────
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
// When id is an auto-generated slug like "field_1779698673548" we fall back
// to the human-readable label so the Dart identifier stays meaningful.
bool _isAutoId(String? id) {
  if (id == null) return true;
  return RegExp(r'^field_\d+$').hasMatch(id.trim());
}

String _fieldName(Map<String, dynamic> f) {
  final id = f['id']?.toString().trim();
  final label = (f['label'] ?? f['fieldId'] ?? 'field').toString().trim();

  if (_isAutoId(id)) {
    // label-derived camelCase: "Post Title" → "postTitle"
    return _labelToCamel(label);
  }

  // id-derived: preserve camelCase / strip spaces
  final raw = (id ?? label);
  final n = raw.replaceAll(RegExp(r'\s+'), '');
  return n.isEmpty ? 'field' : n[0].toLowerCase() + n.substring(1);
}

/// "Full Name" → "fullName", "vehicleNum" → "vehicleNum" (already camel)
String _labelToCamel(String label) {
  final parts = label.trim().split(RegExp(r'[\s_\-]+'));
  if (parts.isEmpty) return 'field';
  final first = parts.first;
  final rest = parts.skip(1).map((p) {
    if (p.isEmpty) return '';
    return p[0].toUpperCase() + p.substring(1);
  }).join();
  final camel = first[0].toLowerCase() + first.substring(1) + rest;
  final n = camel.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  return n.isEmpty ? 'field' : n[0].toLowerCase() + n.substring(1);
}

String _fieldPascal(Map<String, dynamic> f) {
  final n = _fieldName(f);
  return n.isEmpty ? 'Field' : n[0].toUpperCase() + n.substring(1);
}

String _toPascalCase(String raw) {
  return raw
      .split(RegExp(r'[\s_-]+'))
      .where((e) => e.isNotEmpty)
      .map((e) => e[0].toUpperCase() + e.substring(1).toLowerCase())
      .join();
}

String _singularize(String text) {
  final lower = text.toLowerCase();
  if (lower.endsWith('ies')) {
    return '${text.substring(0, text.length - 3)}y';
  }
  if (lower.endsWith('s') && !lower.endsWith('ss')) {
    return text.substring(0, text.length - 1);
  }
  return text;
}

/// Resolve entity class name – correctly handles "Post Title" → "PostTitleEntity"
// String _resolveEntityClass(Map<String, dynamic> field) {
//   // 1. Explicit entityName override (best practice)
//   final explicit = field['entityName'] ?? field['referenceEntity'];
//   if (explicit != null && explicit.toString().trim().isNotEmpty) {
//     var value = explicit.toString().trim();
//     if (!value.endsWith('Entity')) value = '${value}Entity';
//     return value;
//   }

//   // 2. Derive from dropdowndata (if present)
//   final dropdowndata = field['dropdowndata'];
//   if (dropdowndata is Map<String, dynamic>) {
//     for (final entry in dropdowndata.entries) {
//       final v = entry.value;
//       if (v is List && v.isNotEmpty && v.first is Map<String, dynamic>) {
//         String name = _singularize(entry.key);
//         return '${_toPascalCase(name)}Entity';
//       }
//     }
//   }

//   // 3. Derive from label or id – do NOT singularize, keep full name
//   String raw = (field['label'] ?? field['id'] ?? field['fieldId'] ?? 'Item')
//       .toString()
//       .trim();
//   if (raw.isEmpty) raw = 'Item';
//   final pascal = _toPascalCase(raw); // "User Details" → "UserDetails"
//   return '${pascal}Entity';
// }


String _resolveEntityClass(Map<String, dynamic> field) {
  final explicit = field['entityName'] ?? field['referenceEntity'];

  if (explicit != null && explicit.toString().trim().isNotEmpty) {
    var value = explicit.toString().trim();

    if (!value.endsWith('Entity')) {
      value = '${value}Entity';
    }

    return value;
  }

  String raw = (
    field['label'] ??
    field['id'] ??
    field['fieldId'] ??
    'Item'
  ).toString().trim();

  if (raw.isEmpty) {
    raw = 'Item';
  }

  return '${_toPascalCase(raw)}Entity';
}


/// Returns snake_case file name (e.g., "user_details")
String _resolveEntityFile(Map<String, dynamic> field) {
  final entity = _resolveEntityClass(field);
  final clean = entity.replaceAll('Entity', '');
  return _toSnakeCase(clean);
}

String _toSnakeCase(String input) {
  return input
      .replaceAllMapped(
        RegExp(r'([a-z0-9])([A-Z])'),
        (m) => '${m.group(1)}_${m.group(2)}',
      )
      .replaceAll(' ', '_')
      .replaceAll('-', '_')
      .toLowerCase();
}

String _snake(String s) {
  if (s.isEmpty) return s;
  final out = s.replaceAllMapped(
      RegExp(r'[A-Z]'), (m) => '_${m.group(0)!.toLowerCase()}');
  return out.startsWith('_') ? out.substring(1) : out;
}

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

String _esc(String s) => s.replaceAll("'", "\\'");

String _lit(dynamic v) {
  if (v == null) return 'null';
  if (v is String) return v.isEmpty ? "''" : "'${_esc(v)}'";
  if (v is bool || v is num) return '$v';
  return 'null';
}

String _withS(String name) {
  return name.toLowerCase().endsWith('s') ? name : '${name}s';
}

String _listFieldName(Map<String, dynamic> field) {
  final explicit = field['listFieldName'];
  if (explicit != null && explicit.toString().isNotEmpty) {
    return explicit.toString();
  }
  final entityClass = _resolveEntityClass(field);
  final base = entityClass.replaceAll('Entity', '');
  return _snake(_withS(base));
}

bool _returnsList(Map<String, dynamic> field) {
  return field['returnsList'] == true;
}

// ══════════════════════════════════════════════════════════════════
// BlocGenerator
// ══════════════════════════════════════════════════════════════════
class BlocGenerator {
  BlocGenerator({
    required this.featureName,
    required this.configList,
    this.stepJson,
    this.generateAsyncValueSeparately = false,
    this.entityImportPrefix = '../../domain/entity/',
    this.usecaseImportPrefix = '../../domain/usecases/',
    this.asyncValueImportPath = './async_value.dart',
  });

  final String featureName;
  final List<dynamic> configList;
  final Map<String, dynamic>? stepJson;
  final bool generateAsyncValueSeparately;
  final String entityImportPrefix;
  final String usecaseImportPrefix;
  final String asyncValueImportPath;

  late final List<Map<String, dynamic>> _flatFields = flattenBlocFields(configList);

  List<Map<String, dynamic>> get _uniqueAsyncFields {
    final seen = <String>{};
    return _flatFields.where(_isApiDropdown).where((f) {
      final name = _fieldName(f);
      if (seen.contains(name)) return false;
      seen.add(name);
      return true;
    }).toList();
  }

  bool get _hasAsync => _uniqueAsyncFields.isNotEmpty;

  Map<String, String> generateAll() {
    final snake = _snake(featureName);
    final files = <String, String>{
      '${snake}_bloc.dart': generateBloc(),
      '${snake}_event.dart': generateEvent(),
      '${snake}_state.dart': generateState(),
      'async_value.dart': generateAsyncValue(),
    };
    return files;
  }

  String generateBloc() {
    final b = StringBuffer();
    final snake = _snake(featureName);
    final stepMeta = JourneyStepCodegen.fromJson(stepJson ?? {});

    b.writeln("import 'package:flutter_bloc/flutter_bloc.dart';");
    b.writeln("import '${snake}_event.dart';");
    b.writeln("import '${snake}_state.dart';");
    b.writeln("import '$asyncValueImportPath';");
    b.writeln("import '$usecaseImportPrefix${snake}_usecases.dart';");

    final importedEntityFiles = <String>{};
    for (final f in _uniqueAsyncFields) {
      final eFile = _resolveEntityFile(f);
      final importPath = '$entityImportPrefix${eFile}_entity.dart';
      if (importedEntityFiles.add(importPath)) {
        b.writeln("import '$importPath';");
      }
    }
    b.writeln();

    b.writeln("class ${featureName}Bloc extends Bloc<${featureName}Event, ${featureName}State> {");
    b.writeln("  final ${featureName}Usecases? usecases;");
    b.writeln();
    b.writeln("  ${featureName}Bloc({this.usecases})");
    b.writeln("      : super(${featureName}State.initial()) {");
    b.writeln("    on<${featureName}FieldChangedEvent>(_onFieldChanged);");
    b.writeln("    on<${featureName}BatchUpdateEvent>(_onBatchUpdate);");
    if (_hasAsync) {
      b.writeln("    on<Load${featureName}DataEvent>(_onLoadData);");
    }
    b.writeln("    on<Reset${featureName}Event>(_onReset);");
    b.writeln("    on<${featureName}PrimaryActionEvent>(_onPrimaryAction);");
    if (_hasAsync) {
      b.writeln("    add(Load${featureName}DataEvent());");
    }
    b.writeln("  }");
    stepMeta.writeStepConstants(b);
    b.writeln();
    b.writeln();

    b.writeln("  void _onFieldChanged(");
    b.writeln("    ${featureName}FieldChangedEvent event,");
    b.writeln("    Emitter<${featureName}State> emit,");
    b.writeln("  ) {");
    b.writeln("    emit(state.copyWithValue(event.fieldName, event.value));");
    b.writeln("  }");
    b.writeln();

    b.writeln("  void _onBatchUpdate(");
    b.writeln("    ${featureName}BatchUpdateEvent event,");
    b.writeln("    Emitter<${featureName}State> emit,");
    b.writeln("  ) {");
    b.writeln("    final updated = Map<String, dynamic>.from(state.formValues)");
    b.writeln("      ..addAll(event.updates);");
    b.writeln("    emit(state.copyWith(formValues: updated));");
    b.writeln("  }");
    b.writeln();

    if (_hasAsync) {
      b.writeln("  Future<void> _onLoadData(");
      b.writeln("    Load${featureName}DataEvent event,");
      b.writeln("    Emitter<${featureName}State> emit,");
      b.writeln("  ) async {");
      for (final f in _uniqueAsyncFields) {
        final fName = _fieldName(f);
        final fPascal = _fieldPascal(f);
        final method = _withS('load$fPascal');
        b.writeln("    emit(state.copyWith(${fName}Async: const AsyncValue.loading()));");
        b.writeln("    final ${fName}Result = await usecases.$method();");
        b.writeln("    ${fName}Result.fold(");
        b.writeln("      (failure) => emit(state.copyWith(");
        b.writeln("        ${fName}Async: AsyncValue.error(failure),");
        b.writeln("      )),");
        b.writeln("      (data) => emit(state.copyWith(");
        b.writeln("        ${fName}Async: AsyncValue.data(data),");
        b.writeln("      )),");
        b.writeln("    );");
      }
      b.writeln("  }");
      b.writeln();
    }

    b.writeln("  void _onReset(");
    b.writeln("    Reset${featureName}Event event,");
    b.writeln("    Emitter<${featureName}State> emit,");
    b.writeln("  ) {");
    b.writeln("    emit(${featureName}State.initial());");
    b.writeln("  }");
    b.writeln();
    b.writeln("  Future<void> _onPrimaryAction(");
    b.writeln("    ${featureName}PrimaryActionEvent event,");
    b.writeln("    Emitter<${featureName}State> emit,");
    b.writeln("  ) async {");
    b.writeln("    if (state.isExecuting) return;");
    b.writeln("    emit(state.copyWith(isExecuting: true, errorMessage: null));");
    b.writeln("    try {");
    b.writeln("      final result = await usecases.submitStep(");
    b.writeln("        stepId: stepKey,");
    b.writeln("        formData: state.formValues,");
    b.writeln("        trigger: '${stepMeta.hasNextStep ? 'onNext' : 'onSubmit'}',");
    b.writeln("      );");
    b.writeln("      final nextStep = result?.nextStepId ?? nextStepId;");
    b.writeln("      emit(state.copyWith(");
    b.writeln("        isExecuting: false,");
    b.writeln("        navigationTargetStepId: nextStep,");
    b.writeln("        errorMessage: null,");
    b.writeln("      ));");
    b.writeln("    } catch (e) {");
    b.writeln("      emit(state.copyWith(isExecuting: false, errorMessage: e.toString()));");
    b.writeln("    }");
    b.writeln("  }");
    b.writeln("}");

    return b.toString();
  }

  String generateEvent() {
    final b = StringBuffer();
    b.writeln("import 'package:equatable/equatable.dart';");
    b.writeln();
    b.writeln("abstract class ${featureName}Event extends Equatable {");
    b.writeln("  const ${featureName}Event();");
    b.writeln("  @override");
    b.writeln("  List<Object?> get props => [];");
    b.writeln("}");
    b.writeln();
    b.writeln("class ${featureName}FieldChangedEvent extends ${featureName}Event {");
    b.writeln("  final String fieldName;");
    b.writeln("  final dynamic value;");
    b.writeln("  const ${featureName}FieldChangedEvent({");
    b.writeln("    required this.fieldName,");
    b.writeln("    required this.value,");
    b.writeln("  });");
    b.writeln("  @override");
    b.writeln("  List<Object?> get props => [fieldName, value];");
    b.writeln("}");
    b.writeln();
    b.writeln("class ${featureName}BatchUpdateEvent extends ${featureName}Event {");
    b.writeln("  final Map<String, dynamic> updates;");
    b.writeln("  const ${featureName}BatchUpdateEvent({");
    b.writeln("    required this.updates,");
    b.writeln("  });");
    b.writeln("  @override");
    b.writeln("  List<Object?> get props => [updates];");
    b.writeln("}");
    b.writeln();
    if (_hasAsync) {
      b.writeln("class Load${featureName}DataEvent extends ${featureName}Event {");
      b.writeln("  const Load${featureName}DataEvent();");
      b.writeln("}");
      b.writeln();
    }
    b.writeln("class Reset${featureName}Event extends ${featureName}Event {");
    b.writeln("  const Reset${featureName}Event();");
    b.writeln("}");
    b.writeln();
    b.writeln("class ${featureName}PrimaryActionEvent extends ${featureName}Event {");
    b.writeln("  const ${featureName}PrimaryActionEvent();");
    b.writeln("}");
    return b.toString();
  }

  String generateState() {
    final b = StringBuffer();
    b.writeln("import 'dart:convert';");
    b.writeln("import 'package:equatable/equatable.dart';");
    b.writeln("import '$asyncValueImportPath';");

    final importedEntityFiles = <String>{};
    for (final f in _uniqueAsyncFields) {
      final entityFile = _resolveEntityFile(f);
      final importPath = '$entityImportPrefix${entityFile}_entity.dart';
      if (importedEntityFiles.add(importPath)) {
        b.writeln("import '$importPath';");
      }
    }
    b.writeln();

    b.writeln("class ${featureName}State extends Equatable {");
    for (final f in _uniqueAsyncFields) {
      final fName = _fieldName(f);
      final entityClass = _resolveEntityClass(f);
      final returnsList = _returnsList(f);
      if (returnsList) {
        b.writeln("  final AsyncValue<List<$entityClass>> ${fName}Async;");
      } else {
        b.writeln("  final AsyncValue<$entityClass> ${fName}Async;");
      }
    }
    b.writeln("  final Map<String, dynamic> formValues;");
    b.writeln("  final bool isExecuting;");
    b.writeln("  final String? navigationTargetStepId;");
    b.writeln("  final String? errorMessage;");
    b.writeln();

    b.writeln("  const ${featureName}State({");
    for (final f in _uniqueAsyncFields) {
      final fName = _fieldName(f);
      b.writeln("    required this.${fName}Async,");
    }
    b.writeln("    required this.formValues,");
    b.writeln("    this.isExecuting = false,");
    b.writeln("    this.navigationTargetStepId,");
    b.writeln("    this.errorMessage,");
    b.writeln("  });");
    b.writeln();

    b.writeln("  factory ${featureName}State.initial() {");
    b.writeln("    return ${featureName}State(");
    for (final f in _uniqueAsyncFields) {
      final fName = _fieldName(f);
      b.writeln("      ${fName}Async: const AsyncValue.idle(),");
    }
    b.writeln("      formValues: {");
    final seenKeys = <String>{};
    for (final f in _flatFields.where(_isFormField)) {
      final key = _fieldName(f);
      if (seenKeys.contains(key)) continue;
      seenKeys.add(key);
      final type = (f['type'] ?? '').toString().toLowerCase();
      final defaultVal = _resolveDefault(f, type);
      b.writeln("        '$key': $defaultVal,");
    }
    b.writeln("      },");
    b.writeln("    );");
    b.writeln("  }");
    b.writeln();

    b.writeln("  ${featureName}State copyWith({");
    for (final f in _uniqueAsyncFields) {
      final fName = _fieldName(f);
      final entityClass = _resolveEntityClass(f);
      final returnsList = _returnsList(f);
      if (returnsList) {
        b.writeln("    AsyncValue<List<$entityClass>>? ${fName}Async,");
      } else {
        b.writeln("    AsyncValue<$entityClass>? ${fName}Async,");
      }
    }
    b.writeln("    Map<String, dynamic>? formValues,");
    b.writeln("    bool? isExecuting,");
    b.writeln("    String? navigationTargetStepId,");
    b.writeln("    String? errorMessage,");
    b.writeln("  }) {");
    b.writeln("    return ${featureName}State(");
    for (final f in _uniqueAsyncFields) {
      final fName = _fieldName(f);
      b.writeln("      ${fName}Async: ${fName}Async ?? this.${fName}Async,");
    }
    b.writeln("      formValues: formValues ?? this.formValues,");
    b.writeln("      isExecuting: isExecuting ?? this.isExecuting,");
    b.writeln(
      "      navigationTargetStepId: navigationTargetStepId ?? this.navigationTargetStepId,",
    );
    b.writeln("      errorMessage: errorMessage,");
    b.writeln("    );");
    b.writeln("  }");
    b.writeln();

    b.writeln("  ${featureName}State copyWithValue(String key, dynamic value) {");
    b.writeln("    final updated = Map<String, dynamic>.from(formValues)..[key] = value;");
    b.writeln("    return copyWith(formValues: updated);");
    b.writeln("  }");
    b.writeln();

    b.writeln("  @override");
    b.writeln("  List<Object?> get props => [");
    for (final f in _uniqueAsyncFields) {
      b.writeln("    ${_fieldName(f)}Async,");
    }
    b.writeln("    jsonEncode(formValues),");
    b.writeln("    isExecuting,");
    b.writeln("    navigationTargetStepId,");
    b.writeln("    errorMessage,");
    b.writeln("  ];");
    b.writeln("}");

    return b.toString();
  }

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

  bool _isFormField(Map<String, dynamic> field) {
    final type = (field['type'] ?? '').toString().toLowerCase();
    final hidden = field['hidden'] == true;
    final visible = field['visible'] != false;
    const skipTypes = {
      'card',
      'group',
      'section',
      'step',
      'tab',
      'tabs',
      'container',
      'row',
      'column',
      'accordion',
      'timeline',
      'repeater',
      'divider',
    };
    if (hidden || !visible) return false;
    return !skipTypes.contains(type);
  }

  String _resolveDefault(Map<String, dynamic> field, String type) {
    final defaultVal = field['defaultValue'];
    if (defaultVal != null) return _lit(defaultVal);
    switch (type) {
      case 'text': case 'textfield': case 'textarea': case 'email':
      case 'password': case 'phone': case 'otp': case 'formula':
        return "''";
      case 'number': case 'integer': case 'int':
        return '0';
      case 'decimal': case 'double': case 'float':
        return '0.0';
      case 'checkbox': case 'switch':
        return 'false';
      case 'multiselect': case 'multi_select':
        return '<String>[]';
      case 'table_grid': case 'data_grid':
        return '<Map<String, dynamic>>[]';
      default:
        return 'null';
    }
  }
}
