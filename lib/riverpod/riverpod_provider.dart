import 'dart:core';

String generateProviderInterface(
  String className,
  List<dynamic> configList,
  String fileName,
) {
  final buffer = StringBuffer();
  final entityImports = <String>{};

  // ─── Recursive flatten (same pattern as all other generators) ──
  void flattenFields(dynamic source, List<Map<String, dynamic>> result) {
    if (source == null) return;
    if (source is List) {
      // ignore: curly_braces_in_flow_control_structures
      for (final item in source) flattenFields(item, result);
      return;
    }
    if (source is! Map<String, dynamic>) return;

    if (source.containsKey('steps')) {
      flattenFields(source['steps'], result);
      return;
    }
    if (source.containsKey('fields')) {
      flattenFields(source['fields'], result);
      return;
    }
    if (source.containsKey('type')) {
      result.add(source);
      flattenFields(source['nestedFields'], result);
      final config = source['componentConfig'];
      if (config is Map) {
        flattenFields(config['fields'], result);
        flattenFields(config['columns'], result);
      }
    }
  }

  // ✅ FIX 1: flattenFields instead of configList.expand
  final flatFields = <Map<String, dynamic>>[];
  flattenFields(configList, flatFields);

  for (final item in flatFields) {
    // ✅ FIX 2: lowercase type check
    final type = (item['type']?.toString() ?? '').toLowerCase();
    final rawLabel =
        (item['label'] ?? item['id'] ?? item['fieldId'] ?? '')
            .toString()
            .trim();
    if (rawLabel.isEmpty) continue;

    final label = rawLabel.replaceAll(RegExp(r'\s+'), '');
    final capital = _capitalize(label);

    // ✅ FIX 3: isApiDropdown guard — same logic as controller/view
    final useStatic = item['useStaticOptions'] == true;
    final hasApiUrl = item['dropdownApiUrl'] != null;
    final staticOpts = (item['options'] as List<dynamic>?) ??
        (item['staticOptions'] as List<dynamic>?);
    final isApiDropdown = (type == 'dropdown' || type == 'api_dropdown') &&
        !useStatic &&
        hasApiUrl;

    switch (type) {
      case 'text':
      case 'textfield':
      case 'textarea':
      case 'email':
      case 'password':
      case 'phone':
      case 'otp':
        buffer.writeln(_textProvider(capital));
        break;

      case 'number':
      case 'integer':
      case 'int':
      case 'decimal':
      case 'double':
      case 'float':
        buffer.writeln(_textProvider(capital));
        break;

      case 'date':
      case 'datetime':
      case 'date time':
      case 'time':
        buffer.writeln(_dateProvider(capital));
        break;

      case 'checkbox':
      case 'switch':
        buffer.writeln(_boolProvider(capital));
        break;

      case 'dropdown':
      case 'api_dropdown':
        // ✅ FIX 4: check isApiDropdown FIRST — prevents static fallback
        //           for dropdowns that have dummy options[] but also have a URL
        if (isApiDropdown) {
          final entityFile = _resolveEntityFile(item, rawLabel);
          entityImports.add(
              "import '../../domain/entity/${entityFile}_entity.dart';");
          buffer.writeln(_apiDropdownProvider(capital, item));
        } else if (staticOpts != null && staticOpts.isNotEmpty) {
          buffer.writeln(_staticDropdownProvider(capital, staticOpts));
        } else {
          // No URL, no static opts — still generate a basic text provider
          buffer.writeln(_textProvider(capital));
        }
        break;

      case 'multiselect':
      case 'multi select':
      case 'multi_select':
        buffer.writeln(_multiSelectProvider(capital));
        break;

      case 'slider':
      case 'range slider':
        buffer.writeln(_sliderProvider(capital, item));
        break;

      case 'file':
      case 'fileupload':
      case 'file upload':
      case 'image':
        buffer.writeln(_fileProvider(capital));
        break;

      case 'label':
      case 'divider':
      case 'section':
      case 'card':
      case 'tabs':
      case 'accordion':
      case 'hidden':
      case 'row':
        // Layout types — no provider needed
        break;

      default:
        buffer.writeln(_textProvider(capital));
    }
  }

  // ─── Assemble final output ─────────────────────────────────────
  final full = StringBuffer();

  // ✅ Riverpod 3.0: riverpod_annotation import is still correct
  full.writeln(
      "import 'package:riverpod_annotation/riverpod_annotation.dart';");

  // ✅ FIX 5: entityImports is now correctly populated (was dead code before)
  for (final imp in entityImports) {
    full.writeln(imp);
  }

  final fileSnake = fileName.toLowerCase().replaceAll(' ', '_');
  full.writeln("part '${fileSnake}_provider.g.dart';\n");
  full.write(buffer.toString());

  return full.toString();
}

// ─── Resolve entity file name from dropdowndata key or label ──────
String _resolveEntityFile(Map<String, dynamic> item, String rawLabel) {
  final dropdowndata = item['dropdowndata'];
  if (dropdowndata is Map<String, dynamic>) {
    for (final entry in dropdowndata.entries) {
      final v = entry.value;
      if (v is List && v.isNotEmpty && v.first is Map<String, dynamic>) {
        return _toSnakeCase(_singularize(entry.key)); // e.g. "posts" → "post"
      }
    }
  }
  return _toSnakeCase(rawLabel); // fallback to label
}

// ─── Resolve entity class name from dropdowndata key or label ─────
String _resolveEntityClass(Map<String, dynamic> item, String capital) {
  final dropdowndata = item['dropdowndata'];
  if (dropdowndata is Map<String, dynamic>) {
    for (final entry in dropdowndata.entries) {
      final v = entry.value;
      if (v is List && v.isNotEmpty && v.first is Map<String, dynamic>) {
        // e.g. "posts" → "PostEntity"
        return '${_capitalize(_singularize(entry.key))}Entity';
      }
    }
  }
  return '${capital}Entity'; // fallback
}

// ─── Providers ────────────────────────────────────────────────────

String _textProvider(String capital) {
  // ✅ Riverpod 3.0: @riverpod on class, extends _$ClassName, no change needed
  return '''
@riverpod
class $capital extends _\$$capital {
  @override
  String build() => '';

  void set(String value) => state = value;
  void clear() => state = '';
}
''';
}

String _dateProvider(String capital) {
  return '''
@riverpod
class $capital extends _\$$capital {
  @override
  DateTime? build() => null;

  void set(DateTime value) => state = value;
  void clear() => state = null;
}
''';
}

String _boolProvider(String capital) {
  return '''
@riverpod
class $capital extends _\$$capital {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void set(bool value) => state = value;
}
''';
}

String _fileProvider(String capital) {
  return '''
@riverpod
class $capital extends _\$$capital {
  @override
  String build() => '';

  void set(String path) => state = path;
  void clear() => state = '';
}
''';
}

String _staticDropdownProvider(String capital, List<dynamic> options) {
  final list = options.map((e) {
    if (e is Map) {
      final val = (e['value'] ?? e['key'] ?? e['label'] ?? e.toString())
          .toString()
          .replaceAll("'", "\\'");
      return "'$val'";
    }
    return "'${e.toString().replaceAll("'", "\\'")}'";
  }).join(', ');

  return '''
@riverpod
class $capital extends _\$$capital {
  @override
  String? build() => null;

  static const options = [$list];

  void select(String value) => state = value;
  void clear() => state = null;
}
''';
}

String _apiDropdownProvider(String capital, Map<String, dynamic> item) {
  // ✅ FIX 6: no more exception throwing — graceful fallback
  final entityClass = _resolveEntityClass(item, capital);

  // Find list key from dropdowndata
  String listKey = 'data';
  final dropdowndata = item['dropdowndata'];
  if (dropdowndata is Map<String, dynamic>) {
    for (final entry in dropdowndata.entries) {
      if (entry.value is List) {
        listKey = entry.key;
        break;
      }
    }
  }

  final primaryKey =
      (item['dropdownkey']?.toString().trim().isNotEmpty == true)
          ? item['dropdownkey'].toString()
          : 'id';

  final lower = _lowerFirst(capital);

  // ✅ Riverpod 3.0:
  //   - AsyncLoading() → const AsyncLoading()  (still valid in 3.0)
  //   - AsyncValue.guard() still valid
  //   - ref.invalidateSelf() preferred over state = AsyncLoading() in some cases
  //     but guard pattern is still fully supported
  return '''
@riverpod
class ${capital}Dropdown extends _\$${capital}Dropdown {
  @override
  List<$entityClass> build() => const [];

  void setFromResponse(dynamic response) {
    List<$entityClass> parsed = [];

    if (response is Map<String, dynamic>) {
      final dynamicList = response['$listKey'];
      if (dynamicList is List) {
        parsed = dynamicList
            .whereType<Map<String, dynamic>>()
            .map((e) => $entityClass.fromJson(e))
            .toList();
      }
    }
    state = parsed;
  }

  void setItems(List<$entityClass> items) => state = items;

  void clear() => state = const [];
}

@riverpod
class Selected$capital extends _\$Selected$capital {
  @override
  $entityClass? build() => null;

  void select($entityClass value) => state = value;

  void selectById(int id) {
    final items = ref.read(${lower}DropdownProvider);
    try {
      state = items.firstWhere((e) => e.$primaryKey == id);
    } catch (_) {
      state = null;
    }
  }

  void clear() => state = null;
}
''';
}

String _multiSelectProvider(String capital) {
  return '''
@riverpod
class $capital extends _\$$capital {
  @override
  Set<String> build() => const {};

  void toggle(String value) {
    if (state.contains(value)) {
      state = {...state}..remove(value);
    } else {
      state = {...state, value};
    }
  }

  void selectAll(List<String> values) => state = values.toSet();

  void clear() => state = const {};
}
''';
}

String _sliderProvider(String capital, Map<String, dynamic> item) {
  final min = item['minValue'] ?? item['min'] ?? 0.0;
  final max = item['maxValue'] ?? item['max'] ?? 100.0;

  return '''
@riverpod
class $capital extends _\$$capital {
  @override
  double build() => $min;

  void set(double value) {
    if (value >= $min && value <= $max) state = value;
  }

  void reset() => state = $min;
}
''';
}

// ─── Helpers ──────────────────────────────────────────────────────
String _toSnakeCase(String text) =>
    text.trim().replaceAll(RegExp(r'\s+'), '_').toLowerCase();

String _toPascalCase(String text) {
  return text
      .split(RegExp(r'\s+'))
      .where((s) => s.isNotEmpty)
      .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
      .join();
}

String _lowerFirst(String s) =>
    s.isEmpty ? s : '${s[0].toLowerCase()}${s.substring(1)}';

String _capitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

String _singularize(String text) {
  if (text.endsWith('ies')) {
    return '${text.substring(0, text.length - 3)}y';
  }
  if (text.endsWith('s') && text.length > 1) {
    return text.substring(0, text.length - 1);
  }
  return text;
}