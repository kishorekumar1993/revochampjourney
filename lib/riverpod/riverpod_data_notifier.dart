// import 'dart:core';

// // ═══════════════════════════════════════════════════════════════════
// //  Helper functions (must be top-level)
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
//   if (text.endsWith('s') && text.length > 1) {
//     return text.substring(0, text.length - 1);
//   }
//   return text;
// }

// // ═══════════════════════════════════════════════════════════════════
// //  Notifier generator (fixed)
// // ═══════════════════════════════════════════════════════════════════

// String generateNotifierImplInterface(
//   String className,
//   List<dynamic> configList,
//   String fileName, {
//   int depthToDomain = 2,   // ✅ default changed to 2 (../../)
//   int depthToCore = 5,
// }) {
//   final buffer = StringBuffer();

//   // ─── Recursive flatten ──────────────────────────────────────────
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

//   // ─── Collect dynamic dropdown fields ──────────────────────────
//   final dynamicDropdowns = <Map<String, dynamic>>[];
//   for (final field in flatFields) {
//     final type = (field['type'] ?? '').toString().toLowerCase();
//     if (type == 'dropdown' || type == 'api_dropdown') {
//       final useStatic = field['useStaticOptions'] == true;
//       final hasApiUrl = field['dropdownApiUrl'] != null;
//       final staticOpts = (field['options'] as List<dynamic>?) ??
//           (field['staticOptions'] as List<dynamic>?);
//       if (!useStatic && hasApiUrl) {
//         dynamicDropdowns.add(field);
//       } else if (!useStatic && (staticOpts == null || staticOpts.isEmpty)) {
//         dynamicDropdowns.add(field);
//       }
//     }
//   }

//   if (dynamicDropdowns.isEmpty) {
//     return '// No dynamic dropdown notifiers to generate.';
//   }

//   // ─── Base imports ──────────────────────────────────────────────
//   buffer.writeln(
//     "import 'package:riverpod_annotation/riverpod_annotation.dart';",
//   );
//   buffer.writeln(
//     "import 'package:flutter_riverpod/flutter_riverpod.dart';",
//   );
//   final prefix = '../' * depthToDomain;   // ✅ build relative path once
//   final safeFileName = fileName.trim().isEmpty ? 'userjourney_form' : _toSnakeCase(fileName);
//   buffer.writeln(
//     "import '${prefix}domain/locator/${safeFileName}_locator.dart';",
//   );

//   // ─── Unique entity imports (always based on raw label) ─────────
//   final entityImports = <String>{};
//   for (final item in dynamicDropdowns) {
//     final rawLabel = (item['label'] ?? item['id'] ?? item['fieldId'] ?? 'model')
//         .toString()
//         .trim();
//     if (rawLabel.isEmpty) continue;
//     final entityFile = _toSnakeCase(rawLabel);   // ✅ e.g., "post_title"
//     entityImports.add("import '${prefix}domain/entity/${entityFile}_entity.dart';");
//   }
//   for (final imp in entityImports) {
//     buffer.writeln(imp);
//   }

//   final notifierFileName = safeFileName;
//   buffer.writeln("part '${notifierFileName}_notifier.g.dart';\n");

//   // ─── Generate one notifier per API dropdown field ──────────────
//   for (final item in dynamicDropdowns) {
//     final rawLabel = (item['label'] ?? item['id'] ?? item['fieldId'] ?? 'field')
//         .toString()
//         .trim();
//     if (rawLabel.isEmpty) continue;

//     final pascal = _toPascalCase(rawLabel);   // e.g., "PostTitle"
//     if (pascal.isEmpty) continue;

// final camelClass = _lowerFirst(className);

// /// Root response entity
// final rootEntityClass = '${pascal}Entity';

// /// Actual dropdown item entity
// String itemEntityClass = rootEntityClass;

// /// Response field name
// String responseFieldName = '';

// final dropdowndata = item['dropdowndata'];

// /// Detect list response dynamically
// if (dropdowndata is Map<String, dynamic>) {
//   for (final entry in dropdowndata.entries) {
//     if (entry.value is List) {
//       responseFieldName = entry.key;

//       itemEntityClass =
//           '${_capitalize(_singularize(entry.key))}Entity';

//       break;
//     }
//   }
// }

// /// Determine if API returns single object or list
// final isSingleObject =
//     responseFieldName.isEmpty;

// /// Correct notifier generic type
// final notifierExtends = isSingleObject
//     ? 'AsyncNotifier<$rootEntityClass>'
//     : 'AsyncNotifier<List<$itemEntityClass>>';

// /// Correct fetch return type
// final fetchReturnType = isSingleObject
//     ? 'Future<$rootEntityClass>'
//     : 'Future<List<$itemEntityClass>>';

// /// API method name
// final apiMethod =
//     (item['apiMethod']?.toString().trim().isNotEmpty == true)
//         ? item['apiMethod'].toString().trim()
//        : 'getAll${_pluralize(pascal)}';
//         // : 'getAll$pascal';

// buffer.writeln('''
// /// ===============================================
// /// $pascal Notifier
// /// ===============================================
// @riverpod
// class ${pascal}Notifier extends $notifierExtends {

//   @override
//   $fetchReturnType build() async {
//     ref.watch(${camelClass}RepositoryProvider);
//     return await _fetchData();
//   }

//   $fetchReturnType _fetchData() async {
//     final result = await ref
//         .read(${camelClass}RepositoryProvider)
//         .$apiMethod();

//     return result.fold(
//       (failure) => throw Exception(failure.toString()),
//       (data) {
//         ${isSingleObject ? 'return data;' : 'return data.$responseFieldName;'}
//       },
//     );
//   }

//   Future<void> refresh() async {
//     state = const AsyncValue.loading();

//     state = await AsyncValue.guard(
//       () => _fetchData(),
//     );
//   }
// }
// ''');
//   }

//   return buffer.toString();
// }