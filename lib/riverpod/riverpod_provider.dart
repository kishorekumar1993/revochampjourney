import 'dart:core';

// ═══════════════════════════════════════════════════════════════════
//  Public generator function
// ═══════════════════════════════════════════════════════════════════

String generateProviderInterface(
  String className, // e.g., "UserJourneyForm"
  List<dynamic> configList,
  String fileName, {
  int depthToDomain = 2, // 2 = '../../domain'
}) {
  final buffer = StringBuffer();
  final entityImports = <String>{};

  // ─── Recursive flatten (unchanged) ──────────────────────────────
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

  // ─── Generate providers for each field ──────────────────────────
  for (final item in flatFields) {
    final type = (item['type']?.toString() ?? '').toLowerCase();
    final rawLabel = (item['label'] ?? item['id'] ?? item['fieldId'] ?? '')
        .toString()
        .trim();
    if (rawLabel.isEmpty) continue;

    // Convert label to PascalCase for class names, e.g. "Post Title" → "PostTitle"
    final pascal = _toPascalCase(rawLabel);
    final lower = _lowerFirst(pascal);

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
        buffer.writeln(_textProvider(pascal));
        break;

      case 'date':
      case 'datetime':
      case 'date time':
      case 'time':
        buffer.writeln(_dateProvider(pascal));
        break;

      case 'checkbox':
      case 'switch':
        buffer.writeln(_boolProvider(pascal));
        break;

      case 'dropdown':
      case 'api_dropdown':
        if (isApiDropdown) {
          // ✅ Entity file name = snake_case of label + "_entity"
          final entitySnake = _toSnakeCase(rawLabel);
          final prefix = '../' * depthToDomain;
          entityImports.add(
            "import '${prefix}domain/entity/${entitySnake}_entity.dart';",
          );
          buffer.writeln(_apiDropdownNotifier(pascal, lower, item, className));
        } else if (staticOpts != null && staticOpts.isNotEmpty) {
          buffer.writeln(_staticDropdownProvider(pascal, staticOpts));
        } else {
          buffer.writeln(_textProvider(pascal));
        }
        break;

      case 'multiselect':
      case 'multi select':
      case 'multi_select':
        buffer.writeln(_multiSelectProvider(pascal));
        break;

      case 'slider':
      case 'range slider':
        buffer.writeln(_sliderProvider(pascal, item));
        break;

      case 'file':
      case 'fileupload':
      case 'file upload':
      case 'image':
        buffer.writeln(_fileProvider(pascal));
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
        buffer.writeln(_textProvider(pascal));
    }
  }

  // ─── Assemble final output ─────────────────────────────────────
  final full = StringBuffer();
  full.writeln(
    "import 'package:riverpod_annotation/riverpod_annotation.dart';",
  );
  full.writeln("import 'package:flutter_riverpod/flutter_riverpod.dart';");
  for (final imp in entityImports) {
    full.writeln(imp);
  }
  final fileSnake = fileName.toLowerCase().replaceAll(' ', '_');
  full.writeln("import '../../domain/locator/${fileSnake}_locator.dart';");

  full.writeln("part '${fileSnake}_provider.g.dart';\n");
  full.write(buffer.toString());

  return full.toString();
}

// ═══════════════════════════════════════════════════════════════════
//  Top‑level helper functions
// ═══════════════════════════════════════════════════════════════════

String _pluralize(String word) {
  if (word.endsWith('y') && !word.endsWith('ey')) {
    return word.substring(0, word.length - 1) + 'ies';
  }
  if (word.endsWith('s')) return word;
  return word + 's';
}

String _toSnakeCase(String text) =>
    text.trim().replaceAll(RegExp(r'\s+'), '_').toLowerCase();

String _toPascalCase(String text) => text
    .split(RegExp(r'\s+'))
    .where((s) => s.isNotEmpty)
    .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
    .join();

String _lowerFirst(String s) =>
    s.isEmpty ? s : s[0].toLowerCase() + s.substring(1);

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

String _singularize(String text) {
  if (text.endsWith('ies')) return '${text.substring(0, text.length - 3)}y';
  if (text.endsWith('s') && text.length > 1)
    return text.substring(0, text.length - 1);
  return text;
}

// ═══════════════════════════════════════════════════════════════════
//  Simple field providers (Riverpod 3.0 Notifier)
// ═══════════════════════════════════════════════════════════════════

String _textProvider(String capital) =>
    '''
@riverpod
class $capital extends Notifier<String> {
  @override
  String build() => '';
  void set(String value) => state = value;
  void clear() => state = '';
}
''';

String _dateProvider(String capital) =>
    '''
@riverpod
class $capital extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;
  void set(DateTime value) => state = value;
  void clear() => state = null;
}
''';

String _boolProvider(String capital) =>
    '''
@riverpod
class $capital extends Notifier<bool> {
  @override
  bool build() => false;
  void toggle() => state = !state;
  void set(bool value) => state = value;
}
''';

String _fileProvider(String capital) =>
    '''
@riverpod
class $capital extends Notifier<String> {
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
class $capital extends Notifier<String?> {
  @override
  String? build() => null;
  static const options = [$list];
  void select(String value) => state = value;
  void clear() => state = null;
}
''';
}

String _multiSelectProvider(String capital) =>
    '''
@riverpod
class $capital extends Notifier<Set<String>> {
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
class $capital extends Notifier<double> {
  @override
  double build() => $min;
  void set(double value) {
    if (value >= $min && value <= $max) state = value;
  }
  void reset() => state = $min;
}
''';
}

// ═══════════════════════════════════════════════════════════════════
//  API dropdown notifier (Riverpod 3.0 AsyncNotifier)
// ═══════════════════════════════════════════════════════════════════

String _apiDropdownNotifier(
  String capital,
  String lower,
  Map<String, dynamic> item,
  String className,
) {
  final rootEntityClass = '${capital}Entity';

  String itemEntityClass = rootEntityClass;

  String responseField = '';

  final dropdownData = item['dropdowndata'];

  if (dropdownData is Map<String, dynamic>) {
    for (final entry in dropdownData.entries) {
      if (entry.value is List) {
        responseField = entry.key;

        itemEntityClass = '${_capitalize(_singularize(entry.key))}Entity';

        break;
      }
    }
  }

  final notifierType = responseField.isEmpty
      ? rootEntityClass
      : 'List<$itemEntityClass>';

  final fetchReturnType = responseField.isEmpty
      ? rootEntityClass
      : 'List<$itemEntityClass>';

  String apiMethod = item['apiMethod']?.toString().trim() ?? '';

  if (apiMethod.isEmpty) {
apiMethod = 'getAll${_pluralize(capital)}';
  }

  final repoProviderName = '${_lowerFirst(className)}RepositoryProvider';
  final notifierProviderName = '${lower}Provider';

  return '''
@riverpod
class ${capital}Notifier
    extends _\$${capital}Notifier {

  @override
  Future<$fetchReturnType> build() async {
    ref.watch($repoProviderName);
    return await _fetchData();
  }

  Future<$fetchReturnType> _fetchData() async {
    final result = await ref
        .read($repoProviderName)
        .$apiMethod();

    return result.fold(
      (failure) => throw Exception(
        failure.toString(),
      ),
      (data) {
        ${responseField.isEmpty ? 'return data;' : 'return data.$responseField;'}
      },
    );
  }
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

@riverpod
class Selected$capital
    extends _\$Selected$capital {

  @override
  $itemEntityClass? build() => null;

  void select($itemEntityClass value) {
    state = value;
  }

  void selectById(int id) {
    final items =
        ref.read($notifierProviderName).value;

    if (items == null) {
      state = null;
      return;
    }

    try {
      state = items.firstWhere(
        (e) => e.id == id,
      );
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



// import 'dart:core';

// // ═══════════════════════════════════════════════════════════════════
// //  Public generator function
// // ═══════════════════════════════════════════════════════════════════

// String generateProviderInterface(
//   String className, // e.g., "UserJourneyForm"
//   List<dynamic> configList,
//   String fileName, {
//   int depthToDomain = 2, // 2 = '../../domain'
// }) {
//   final buffer = StringBuffer();
//   final entityImports = <String>{};

//   // ─── Recursive flatten (unchanged) ──────────────────────────────
//   void flattenFields(dynamic source, List<Map<String, dynamic>> result) {
//     if (source == null) return;
//     if (source is List) {
//       for (final item in source) flattenFields(item, result);
//       return;
//     }
//     if (source is! Map<String, dynamic>) return;
//     if (source.containsKey('steps')) {
//       flattenFields(source['steps'], result);
//       return;
//     }
//     if (source.containsKey('fields')) {
//       flattenFields(source['fields'], result);
//       return;
//     }
//     if (source.containsKey('type')) {
//       result.add(source);
//       flattenFields(source['nestedFields'], result);
//       final config = source['componentConfig'];
//       if (config is Map) {
//         flattenFields(config['fields'], result);
//         flattenFields(config['columns'], result);
//       }
//     }
//   }

//   final flatFields = <Map<String, dynamic>>[];
//   flattenFields(configList, flatFields);

//   // ─── Generate providers for each field ──────────────────────────
//   for (final item in flatFields) {
//     final type = (item['type']?.toString() ?? '').toLowerCase();
//     final rawLabel = (item['label'] ?? item['id'] ?? item['fieldId'] ?? '')
//         .toString()
//         .trim();
//     if (rawLabel.isEmpty) continue;

//     // Convert label to PascalCase for class names, e.g. "Post Title" → "PostTitle"
//     final pascal = _toPascalCase(rawLabel);
//     final lower = _lowerFirst(pascal);

//     // Determine if it's an API dropdown
//     final useStatic = item['useStaticOptions'] == true;
//     final hasApiUrl = item['dropdownApiUrl'] != null;
//     final staticOpts =
//         (item['options'] as List<dynamic>?) ??
//         (item['staticOptions'] as List<dynamic>?);
//     final isApiDropdown =
//         (type == 'dropdown' || type == 'api_dropdown') &&
//         !useStatic &&
//         hasApiUrl;

//     switch (type) {
//       case 'text':
//       case 'textfield':
//       case 'textarea':
//       case 'email':
//       case 'password':
//       case 'phone':
//       case 'otp':
//       case 'number':
//       case 'integer':
//       case 'int':
//       case 'decimal':
//       case 'double':
//       case 'float':
//         buffer.writeln(_textProvider(pascal));
//         break;

//       case 'date':
//       case 'datetime':
//       case 'date time':
//       case 'time':
//         buffer.writeln(_dateProvider(pascal));
//         break;

//       case 'checkbox':
//       case 'switch':
//         buffer.writeln(_boolProvider(pascal));
//         break;

//       case 'dropdown':
//       case 'api_dropdown':
//         if (isApiDropdown) {
//           // ✅ Entity file name = snake_case of label + "_entity"
//           final entitySnake = _toSnakeCase(rawLabel);
//           final prefix = '../' * depthToDomain;
//           entityImports.add(
//             "import '${prefix}domain/entity/${entitySnake}_entity.dart';",
//           );
//           buffer.writeln(_apiDropdownNotifier(pascal, lower, item, className));
//         } else if (staticOpts != null && staticOpts.isNotEmpty) {
//           buffer.writeln(_staticDropdownProvider(pascal, staticOpts));
//         } else {
//           buffer.writeln(_textProvider(pascal));
//         }
//         break;

//       case 'multiselect':
//       case 'multi select':
//       case 'multi_select':
//         buffer.writeln(_multiSelectProvider(pascal));
//         break;

//       case 'slider':
//       case 'range slider':
//         buffer.writeln(_sliderProvider(pascal, item));
//         break;

//       case 'file':
//       case 'fileupload':
//       case 'file upload':
//       case 'image':
//         buffer.writeln(_fileProvider(pascal));
//         break;

//       // Layout types – no provider needed
//       case 'label':
//       case 'divider':
//       case 'section':
//       case 'card':
//       case 'tabs':
//       case 'accordion':
//       case 'hidden':
//       case 'row':
//         break;

//       default:
//         buffer.writeln(_textProvider(pascal));
//     }
//   }

//   // ─── Assemble final output ─────────────────────────────────────
//   final full = StringBuffer();
//   full.writeln(
//     "import 'package:riverpod_annotation/riverpod_annotation.dart';",
//   );
//   full.writeln("import 'package:flutter_riverpod/flutter_riverpod.dart';");
//   for (final imp in entityImports) {
//     full.writeln(imp);
//   }
//   final fileSnake = fileName.toLowerCase().replaceAll(' ', '_');
//   full.writeln("import '../../domain/locator/${fileSnake}_locator.dart';");

//   full.writeln("part '${fileSnake}_provider.g.dart';\n");
//   full.write(buffer.toString());

//   return full.toString();
// }

// // ═══════════════════════════════════════════════════════════════════
// //  Top‑level helper functions
// // ═══════════════════════════════════════════════════════════════════

// String _pluralize(String word) {
//   if (word.endsWith('y') && !word.endsWith('ey')) {
//     return word.substring(0, word.length - 1) + 'ies';
//   }
//   if (word.endsWith('s')) return word;
//   return word + 's';
// }

// String _toSnakeCase(String text) =>
//     text.trim().replaceAll(RegExp(r'\s+'), '_').toLowerCase();

// String _toPascalCase(String text) => text
//     .split(RegExp(r'\s+'))
//     .where((s) => s.isNotEmpty)
//     .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
//     .join();

// String _lowerFirst(String s) =>
//     s.isEmpty ? s : s[0].toLowerCase() + s.substring(1);

// String _capitalize(String s) =>
//     s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

// String _singularize(String text) {
//   if (text.endsWith('ies')) return '${text.substring(0, text.length - 3)}y';
//   if (text.endsWith('s') && text.length > 1)
//     return text.substring(0, text.length - 1);
//   return text;
// }

// // ═══════════════════════════════════════════════════════════════════
// //  Simple field providers (Riverpod 3.0 Notifier)
// // ═══════════════════════════════════════════════════════════════════

// String _textProvider(String capital) =>
//     '''
// @riverpod
// class $capital extends Notifier<String> {
//   @override
//   String build() => '';
//   void set(String value) => state = value;
//   void clear() => state = '';
// }
// ''';

// String _dateProvider(String capital) =>
//     '''
// @riverpod
// class $capital extends Notifier<DateTime?> {
//   @override
//   DateTime? build() => null;
//   void set(DateTime value) => state = value;
//   void clear() => state = null;
// }
// ''';

// String _boolProvider(String capital) =>
//     '''
// @riverpod
// class $capital extends Notifier<bool> {
//   @override
//   bool build() => false;
//   void toggle() => state = !state;
//   void set(bool value) => state = value;
// }
// ''';

// String _fileProvider(String capital) =>
//     '''
// @riverpod
// class $capital extends Notifier<String> {
//   @override
//   String build() => '';
//   void set(String path) => state = path;
//   void clear() => state = '';
// }
// ''';

// String _staticDropdownProvider(String capital, List<dynamic> options) {
//   final list = options
//       .map((e) {
//         if (e is Map) {
//           final val = (e['value'] ?? e['key'] ?? e['label'] ?? e.toString())
//               .toString()
//               .replaceAll("'", "\\'");
//           return "'$val'";
//         }
//         return "'${e.toString().replaceAll("'", "\\'")}'";
//       })
//       .join(', ');
//   return '''
// @riverpod
// class $capital extends Notifier<String?> {
//   @override
//   String? build() => null;
//   static const options = [$list];
//   void select(String value) => state = value;
//   void clear() => state = null;
// }
// ''';
// }

// String _multiSelectProvider(String capital) =>
//     '''
// @riverpod
// class $capital extends Notifier<Set<String>> {
//   @override
//   Set<String> build() => const {};
//   void toggle(String value) {
//     if (state.contains(value)) {
//       state = {...state}..remove(value);
//     } else {
//       state = {...state, value};
//     }
//   }
//   void selectAll(List<String> values) => state = values.toSet();
//   void clear() => state = const {};
// }
// ''';

// String _sliderProvider(String capital, Map<String, dynamic> item) {
//   final min = item['minValue'] ?? item['min'] ?? 0.0;
//   final max = item['maxValue'] ?? item['max'] ?? 100.0;
//   return '''
// @riverpod
// class $capital extends Notifier<double> {
//   @override
//   double build() => $min;
//   void set(double value) {
//     if (value >= $min && value <= $max) state = value;
//   }
//   void reset() => state = $min;
// }
// ''';
// }

// // ═══════════════════════════════════════════════════════════════════
// //  API dropdown notifier (Riverpod 3.0 AsyncNotifier)
// // ═══════════════════════════════════════════════════════════════════

// String _apiDropdownNotifier(
//   String capital,
//   String lower,
//   Map<String, dynamic> item,
//   String className,
// ) {
//   final rootEntityClass = '${capital}Entity';

//   String itemEntityClass = rootEntityClass;

//   String responseField = '';

//   final dropdownData = item['dropdowndata'];

//   if (dropdownData is Map<String, dynamic>) {
//     for (final entry in dropdownData.entries) {
//       if (entry.value is List) {
//         responseField = entry.key;

//         itemEntityClass = '${_capitalize(_singularize(entry.key))}Entity';

//         break;
//       }
//     }
//   }

//   final notifierType = responseField.isEmpty
//       ? rootEntityClass
//       : 'List<$itemEntityClass>';

//   final fetchReturnType = responseField.isEmpty
//       ? rootEntityClass
//       : 'List<$itemEntityClass>';

//   String apiMethod = item['apiMethod']?.toString().trim() ?? '';

//   if (apiMethod.isEmpty) {
// apiMethod = 'getAll${_pluralize(capital)}';
//   }

//   final repoProviderName = '${_lowerFirst(className)}RepositoryProvider';
//   final notifierProviderName = '${lower}Provider';

//   return '''
// @riverpod
// class ${capital}Notifier
//     extends AsyncNotifier<$notifierType> {

//   @override
//   Future<$fetchReturnType> build() async {
//     ref.watch($repoProviderName);
//     return await _fetchData();
//   }

//   Future<$fetchReturnType> _fetchData() async {
//     final result = await ref
//         .read($repoProviderName)
//         .$apiMethod();

//     return result.fold(
//       (failure) => throw Exception(
//         failure.toString(),
//       ),
//       (data) {
//         ${responseField.isEmpty ? 'return data;' : 'return data.$responseField;'}
//       },
//     );
//   }
//   Future<void> refresh() async {
//     ref.invalidateSelf();
//     await future;
//   }
// }

// @riverpod
// class Selected$capital
//     extends Notifier<$itemEntityClass?> {

//   @override
//   $itemEntityClass? build() => null;

//   void select($itemEntityClass value) {
//     state = value;
//   }

//   void selectById(int id) {
//     final items =
//         ref.read($notifierProviderName).valueOrNull;

//     if (items == null) {
//       state = null;
//       return;
//     }

//     try {
//       state = items.firstWhere(
//         (e) => e.id == id,
//       );
//     } catch (_) {
//       state = null;
//     }
//   }

//   void clear() {
//     state = null;
//   }
// }
// ''';

// }
