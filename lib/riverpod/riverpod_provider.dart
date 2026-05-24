import 'dart:core';

String generateProviderInterface(
  String className,
  List<dynamic> configList,
  String fileName,
) {
  final buffer = StringBuffer();
  final entityImports = <String>{};

  final fields = configList
      .expand((e) => e is Iterable ? e : [e])
      .whereType<Map<String, dynamic>>();

  for (final item in fields) {
    final type = item['type']?.toString() ?? '';
    final rawLabel = item['label']?.toString().trim() ?? '';
    if (rawLabel.isEmpty) continue;

    final label = rawLabel.replaceAll(RegExp(r'\s+'), '');
    final capital = _capitalize(label);

    switch (type) {
      case 'TextField':
        buffer.writeln(_textProvider(capital));
        break;

      case 'Date':
      case 'DateTime':
        buffer.writeln(_dateProvider(capital));
        break;

      case 'Checkbox':
      case 'Switch':
        buffer.writeln(_boolProvider(capital));
        break;

      case 'Dropdown':
        final staticOptions = item['staticOptions'] as List<dynamic>?;
        if (staticOptions != null && staticOptions.isNotEmpty) {
          buffer.writeln(_staticDropdownProvider(capital, staticOptions));
        } else {
          // entityImports.add(
          //     "import '../../domain/entity/${_toSnakeCase(label)}_entity.dart';");
            entityImports.add("import '../../domain/entity/${_toSnakeCase(label)}_entity.dart';");

          buffer.writeln(_apiDropdownProvider(capital, item));
        }
        break;

      case 'Multiselect':
        buffer.writeln(_multiSelectProvider(capital));
        break;

      case 'Slider':
        buffer.writeln(_sliderProvider(capital, item));
        break;

      default:
        buffer.writeln(_textProvider(capital));
    }
  }
  final uniqueEntityFiles = <String>{};

  for (final entityFile in uniqueEntityFiles) {
    buffer.writeln(
        "import '../../domain/entity/${entityFile}_entity.dart';");
  }
  final full = StringBuffer();
  full.writeln("import 'package:riverpod_annotation/riverpod_annotation.dart';");
  for (final imp in entityImports) {
    full.writeln(imp);
  }
   final fileNames = fileName.toLowerCase().replaceAll(" ", "_");
     
   
  full.writeln("part '${fileNames}_provider.g.dart';\n");
  full.write(buffer.toString());

  return full.toString();
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

String _textProvider(String capital) {
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

String _staticDropdownProvider(String capital, List<dynamic> options) {
  final list = options.map((e) => "'$e'").join(',');

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
  final dropdowndata = item['dropdowndata'] as Map<String, dynamic>?;

  if (dropdowndata == null || dropdowndata.isEmpty) {
    throw Exception(
      "API Dropdown '$capital' requires 'dropdowndata' in config."
    );
  }

  // Find JSON key that contains List
  final listKey = dropdowndata.entries
      .firstWhere(
        (entry) => entry.value is List,
        orElse: () => throw Exception(
          "API Dropdown '$capital' requires a List inside 'dropdowndata'."
        ),
      )
      .key;

  // Convert json key -> Entity name
  // posts -> PostEntity
  final singular = listKey.endsWith('s')
      ? listKey.substring(0, listKey.length - 1)
      : listKey;

  final entityName =
      '${singular[0].toUpperCase()}${singular.substring(1)}Entity';

  final primaryKey =
      item['dropdownkey']?.toString().trim().isNotEmpty == true
          ? item['dropdownkey']
          : 'id';

  final lower = _lowerFirst(capital);

  return '''
@riverpod
class ${capital}Dropdown extends _\$${capital}Dropdown {
  @override
  List<$entityName> build() => const [];

  void setFromResponse(dynamic response) {
    List<$entityName> parsed = [];

    if (response is Map<String, dynamic>) {
      final dynamicList = response['$listKey'];

      if (dynamicList is List) {
        parsed = dynamicList
            .whereType<Map<String, dynamic>>()
            .map((e) => $entityName.fromJson(e))
            .toList();
      }
    }

    state = parsed;
  }

  void setItems(List<$entityName> items) {
    state = items;
  }

  void clear() {
    state = const [];
  }
}

@riverpod
class Selected$capital extends _\$Selected$capital {
  @override
  $entityName? build() => null;

  void select($entityName value) {
    state = value;
  }

  void selectById(int id) {
    final items = ref.read(${lower}DropdownProvider);

    try {
      state = items.firstWhere((e) => e.$primaryKey == id);
    } catch (_) {
      state = null;
    }
  }

  void clear() {
    state = null;
  }
}
''';
}


/*
String _apiDropdownProvider(String capital, Map<String, dynamic> item) {
  final wrapperEntity = '${capital}Entity';

  final listEntity =
      item['listEntity']?.toString().trim().isNotEmpty == true
          ? item['listEntity']
          : 'PostEntity'; // default fallback

  final primaryKey =
      item['dropdownkey']?.toString().trim().isNotEmpty == true
          ? item['dropdownkey']
          : 'id';

  final wrapperKey =
      item['responseListKey']?.toString().trim().isNotEmpty == true
          ? item['responseListKey']
          : _lowerFirst(capital) + 's';

  return '''
@riverpod
class ${capital}Dropdown extends _\$${capital}Dropdown {
  @override
  List<$listEntity> build() => [];

  void setFromResponse(Map<String, dynamic> response) {
    final wrapper = $wrapperEntity.fromJson(response);

    state = wrapper.$wrapperKey ?? [];
  }

  void setItems(List<$listEntity> items) {
    state = items;
  }

  void clear() => state = [];
}

@riverpod
class Selected$capital extends _\$Selected$capital {
  @override
  $listEntity? build() => null;

  void select($listEntity value) => state = value;

  void selectById(int id) {
    final items = ref.read(${_lowerFirst(capital)}DropdownProvider);

    state = items.where((e) => e.$primaryKey == id).isNotEmpty
        ? items.firstWhere((e) => e.$primaryKey == id)
        : null;
  }

  void clear() => state = null;
}
''';
}

*/

String _lowerFirst(String s) =>
    s.isEmpty ? s : '${s[0].toLowerCase()}${s.substring(1)}';

String _multiSelectProvider(String capital) {
  return '''
@riverpod
class $capital extends _\$$capital {
  @override
  Set<String> build() => {};

  void toggle(String value) {
    if (state.contains(value)) {
      state = {...state}..remove(value);
    } else {
      state = {...state, value};
    }
  }

  void clear() => state = {};
}
''';
}


String _sliderProvider(String capital, Map<String, dynamic> item) {
  final min = item['min'] ?? 0.0;
  final max = item['max'] ?? 100.0;

  return '''
@riverpod
class $capital extends _\$$capital {
  @override
  double build() => $min;

  void set(double value) {
    if (value >= $min && value <= $max) {
      state = value;
    }
  }

  void reset() => state = $min;
}
''';
}
String _toSnakeCase(String text) {
  if (text.isEmpty) return '';
  return text.trim().replaceAll(RegExp(r'\s+'), '_').toLowerCase();
}


String _capitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

// String _toSnakeCase(String text) =>
//     text.trim().replaceAll(RegExp(r'\s+'), '_').toLowerCase();