String generateNotifierImplInterface(
  String className,
  List<dynamic> configList,
  String fileName,
) {
  final buffer = StringBuffer();

  final dynamicDropdowns =
      configList.whereType<Map<String, dynamic>>().where((item) {
    final type = item['type'];
    final staticOptions = item['staticOptions'] as List<dynamic>?;
    return type == 'Dropdown' &&
        (staticOptions == null || staticOptions.isEmpty);
  }).toList();

  if (dynamicDropdowns.isEmpty) {
    return '// No dynamic dropdown notifiers to generate.';
  }

  /// Base imports
  buffer.writeln(
      "import 'package:riverpod_annotation/riverpod_annotation.dart';");
  buffer.writeln(
      "import '../../domain/locator/${_toSnakeCase(fileName)}_locator.dart';");

  /// Unique entity imports using listEntity
  final entityImports = <String>{};

  for (final item in dynamicDropdowns) {
    final listEntity = item['listEntity']?.toString().trim();
    if (listEntity == null || listEntity.isEmpty) {
      throw Exception(
          "Dropdown '${item['label']}' requires listEntity");
    }

    final fileName =
        _toSnakeCase(listEntity.replaceAll('Entity', ''));

    entityImports.add(
        "import '../../domain/entity/${fileName}_entity.dart';");
  }

  for (final imp in entityImports) {
    buffer.writeln(imp);
  }

  buffer.writeln(
      "part '${_toSnakeCase(fileName)}_notifier.g.dart';\n");

  /// Generate notifier per dropdown
  for (final item in dynamicDropdowns) {
    final label = (item['label'] ?? '').toString().trim();
    if (label.isEmpty) continue;

    final pascal = _toPascalCase(label);
    final entityClass = item['listEntity'];
    final camelClass = _lowerFirst(className);

    final apiMethod =
        item['apiMethod']?.toString().trim();

    if (apiMethod == null || apiMethod.isEmpty) {
      throw Exception(
          "Dropdown '$label' requires apiMethod in config");
    }

    buffer.writeln('''
/// ===============================================
/// $pascal NOTIFIER
/// ===============================================
@riverpod
class ${pascal}Notifier extends _\$${pascal}Notifier {

  @override
  Future<List<$entityClass>> build() async {
    return fetch();
  }

  Future<List<$entityClass>> fetch() async {
    final result =
        await ref.read(${camelClass}ViewProvider).$apiMethod();

    return result.fold(
      (failure) => throw failure,
      (data) => data,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(fetch);
  }
}
''');
  }

  return buffer.toString();
}


String _toSnakeCase(String text) {
  return text
      .trim()
      .replaceAll(RegExp(r'\s+'), '_')
      .toLowerCase();
}

String _toPascalCase(String text) {
  return text
      .split(RegExp(r'\s+'))
      .where((s) => s.isNotEmpty)
      .map((word) =>
          word[0].toUpperCase() +
          word.substring(1).toLowerCase())
      .join();
}

String _lowerFirst(String s) {
  if (s.isEmpty) return s;
  return s[0].toLowerCase() + s.substring(1);
}


// // notifier_generator.dart

// String generateNotifierImplInterface(
//   String className,
//   List<dynamic> configList,
//   String fileName,
// ) {
//   final buffer = StringBuffer();

//   /// 1️⃣ Filter only API-based dropdowns
//   final dynamicDropdowns =
//       configList.whereType<Map<String, dynamic>>().where((item) {
//     final type = item['type'];
//     final staticOptions = item['staticOptions'] as List<dynamic>?;
//     return type == 'Dropdown' &&
//         (staticOptions == null || staticOptions.isEmpty);
//   }).toList();

//   if (dynamicDropdowns.isEmpty) {
//     return '// No dynamic dropdown notifiers to generate.';
//   }

//   /// 2️⃣ Base imports
//   buffer.writeln(
//       "import 'package:riverpod_annotation/riverpod_annotation.dart';");
//   buffer.writeln(
//       "import '../../domain/locator/${_toSnakeCase(fileName)}_locator.dart';");

//   /// 3️⃣ Unique entity imports
//   final uniqueEntityFiles = <String>{};

//   for (final item in dynamicDropdowns) {
//     final label = (item['label'] ?? '').toString().trim();
//     if (label.isNotEmpty) {
//       uniqueEntityFiles.add(_toSnakeCase(label));
//     }
//   }

//   for (final entityFile in uniqueEntityFiles) {
//     buffer.writeln(
//         "import '../../domain/entity/${entityFile}_entity.dart';");
//   }

//   buffer.writeln(
//       "part '${_toSnakeCase(fileName)}_notifier.g.dart';\n");

//   /// 4️⃣ Generate notifier per dropdown
//   for (final item in dynamicDropdowns) {
//     final label = (item['label'] ?? '').toString().trim();
//     if (label.isEmpty) continue;

//     final pascal = _toPascalCase(label);
//     final entityClass = '${pascal}Entity';
//     final camelClass = _lowerFirst(className);
//  final name = label.toLowerCase().replaceAll(RegExp(r'\s+'), '');
   
//     /// Default API method based on dropdown label
//     final apiMethod =
//         item['apiMethod'] ?? 'getAll${name}s';

//     buffer.writeln('''
// /// ===============================================
// /// $pascal NOTIFIER
// /// ===============================================
// @riverpod
// class ${pascal}Notifier extends _\$${pascal}Notifier {

//   @override
//   Future<List<$entityClass>> build() async {
//     return _fetch();
//   }

//   /// Fetch API Data
//   Future<List<$entityClass>> _fetch() async {
//     final result =
//         await ref.read(${camelClass}ViewProvider).$apiMethod();

//     return result.fold(
//       (failure) => throw Exception(failure.toString()),
//       (data) => data as List<$entityClass>,
//     );
//   }

//   /// Manual Refresh
//   Future<void> refresh() async {
//     state = const AsyncLoading();
//     state = await AsyncValue.guard(_fetch);
//   }
// }
// ''');
//   }

//   return buffer.toString();
// }

// /// ===================================================
// /// HELPER FUNCTIONS
// /// ===================================================

// String _toSnakeCase(String text) {
//   return text
//       .trim()
//       .replaceAll(RegExp(r'\s+'), '_')
//       .toLowerCase();
// }

// String _toPascalCase(String text) {
//   return text
//       .split(RegExp(r'\s+'))
//       .where((s) => s.isNotEmpty)
//       .map((word) =>
//           word[0].toUpperCase() +
//           word.substring(1).toLowerCase())
//       .join();
// }

// String _lowerFirst(String s) {
//   if (s.isEmpty) return s;
//   return s[0].toLowerCase() + s.substring(1);
// }