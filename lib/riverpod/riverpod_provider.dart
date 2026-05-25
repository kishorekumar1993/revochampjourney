import 'dart:core';

String generateProviderInterface(
  String className, // Not directly used, kept for signature consistency
  List<dynamic> configList,
  String fileName, {
  int depthToDomain =
      2, // from presentation/provider → domain/entity (default '../..')
}) {
  final buffer = StringBuffer();
  final entityImports = <String>{};

  // ─── Recursive flatten (same pattern as all other generators) ──
  void flattenFields(dynamic source, List<Map<String, dynamic>> result) {
    if (source == null) return;
    if (source is List) {
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

  final flatFields = <Map<String, dynamic>>[];
  flattenFields(configList, flatFields);

  // Collect entity imports and generate providers
  for (final item in flatFields) {
    final type = (item['type']?.toString() ?? '').toLowerCase();
    final rawLabel = (item['label'] ?? item['id'] ?? item['fieldId'] ?? '')
        .toString()
        .trim();
    if (rawLabel.isEmpty) continue;

    final label = rawLabel.replaceAll(RegExp(r'\s+'), '');
    final capital = _capitalize(label);

    // Determine if it's an API dropdown
    final useStatic = item['useStaticOptions'] == true;
    final hasApiUrl = item['dropdownApiUrl'] != null;
    final staticOpts =
        (item['options'] as List<dynamic>?) ??
        (item['staticOptions'] as List<dynamic>?);
    final isApiDropdown =
        (type == 'dropdown' || type == 'api_dropdown') &&
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
        if (isApiDropdown) {
          final entityFile = _resolveEntityFile(item, rawLabel);
          entityImports.add(
            "import '${'../' * depthToDomain}domain/entity/${entityFile}_entity.dart';",
          );
          buffer.writeln(_apiDropdownProvider(capital, item));
        } else if (staticOpts != null && staticOpts.isNotEmpty) {
          buffer.writeln(_staticDropdownProvider(capital, staticOpts));
        } else {
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

      // Layout types – no provider needed
      case 'label':
      case 'divider':
      case 'section':
      case 'card':
      case 'tabs':
      case 'accordion':
      case 'hidden':
      case 'row':
        break;

      default:
        buffer.writeln(_textProvider(capital));
    }
  }

  // ─── Assemble final output ─────────────────────────────────────
  final full = StringBuffer();
  full.writeln(
    "import 'package:riverpod_annotation/riverpod_annotation.dart';",
  );
  for (final imp in entityImports) {
    full.writeln(imp);
  }
  final fileSnake = fileName.toLowerCase().replaceAll(' ', '_');
  full.writeln("part '${fileSnake}_provider.g.dart';\n");
  full.write(buffer.toString());

  return full.toString();
}

// ─── Helper functions (same as before, but improved) ──────────────

String _resolveEntityFile(Map<String, dynamic> item, String rawLabel) {
  final dropdowndata = item['dropdowndata'];
  if (dropdowndata is Map<String, dynamic>) {
    for (final entry in dropdowndata.entries) {
      if (entry.value is List &&
          (entry.value as List).isNotEmpty &&
          (entry.value as List).first is Map) {
        return _toSnakeCase(_singularize(entry.key));
      }
    }
  }
  return _toSnakeCase(rawLabel);
}

String _resolveEntityClass(Map<String, dynamic> item, String capital) {
  final dropdowndata = item['dropdowndata'];
  if (dropdowndata is Map<String, dynamic>) {
    for (final entry in dropdowndata.entries) {
      if (entry.value is List &&
          (entry.value as List).isNotEmpty &&
          (entry.value as List).first is Map) {
        return '${_capitalize(_singularize(entry.key))}Entity';
      }
    }
  }
  return '${capital}Entity';
}

String _textProvider(String capital) =>
    '''
@riverpod
class $capital extends _\$$capital {
  @override
  String build() => '';
  void set(String value) => state = value;
  void clear() => state = '';
}
''';

String _dateProvider(String capital) =>
    '''
@riverpod
class $capital extends _\$$capital {
  @override
  DateTime? build() => null;
  void set(DateTime value) => state = value;
  void clear() => state = null;
}
''';

String _boolProvider(String capital) =>
    '''
@riverpod
class $capital extends _\$$capital {
  @override
  bool build() => false;
  void toggle() => state = !state;
  void set(bool value) => state = value;
}
''';

String _fileProvider(String capital) =>
    '''
@riverpod
class $capital extends _\$$capital {
  @override
  String build() => '';
  void set(String path) => state = path;
  void clear() => state = '';
}
''';

String _staticDropdownProvider(String capital, List<dynamic> options) {
  final list = options
      .map((e) {
        if (e is Map) {
          final val = (e['value'] ?? e['key'] ?? e['label'] ?? e.toString())
              .toString()
              .replaceAll("'", "\\'");
          return "'$val'";
        }
        return "'${e.toString().replaceAll("'", "\\'")}'";
      })
      .join(', ');
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
  final entityClass = _resolveEntityClass(item, capital);
  final dropdowndata = item['dropdowndata'];
  String listKey = 'data';
  if (dropdowndata is Map<String, dynamic>) {
    for (final entry in dropdowndata.entries) {
      if (entry.value is List) {
        listKey = entry.key;
        break;
      }
    }
  }
  final primaryKey = (item['dropdownkey']?.toString().trim().isNotEmpty == true)
      ? item['dropdownkey'].toString()
      : 'id';
  final lower = _lowerFirst(capital);
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

String _multiSelectProvider(String capital) =>
    '''
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

String _capitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

String _lowerFirst(String s) =>
    s.isEmpty ? s : '${s[0].toLowerCase()}${s.substring(1)}';

String _singularize(String text) {
  if (text.endsWith('ies')) return '${text.substring(0, text.length - 3)}y';
  if (text.endsWith('s') && text.length > 1)
    return text.substring(0, text.length - 1);
  return text;
}
