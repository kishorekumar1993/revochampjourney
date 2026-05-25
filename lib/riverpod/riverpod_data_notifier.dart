String generateNotifierImplInterface(
  String className,
  List<dynamic> configList,
  String fileName, {
  int depthToDomain = 3, // from presentation/notifier to domain folder
  int depthToCore = 5, // kept for consistency (not used here)
}) {
  final buffer = StringBuffer();

  // ─── Recursive flatten (same as other generators) ──────────────
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

  // ─── Collect dynamic dropdown fields ──────────────────────────
  final dynamicDropdowns = <Map<String, dynamic>>[];

  for (final field in flatFields) {
    final type = (field['type'] ?? '').toString().toLowerCase();
    if (type == 'dropdown' || type == 'api_dropdown') {
      final useStatic = field['useStaticOptions'] == true;
      final hasApiUrl = field['dropdownApiUrl'] != null;
      final staticOpts =
          (field['options'] as List<dynamic>?) ??
          (field['staticOptions'] as List<dynamic>?);

      if (!useStatic && hasApiUrl) {
        dynamicDropdowns.add(field);
      } else if (!useStatic && (staticOpts == null || staticOpts.isEmpty)) {
        dynamicDropdowns.add(field);
      }
    }
  }

  if (dynamicDropdowns.isEmpty) {
    return '// No dynamic dropdown notifiers to generate.';
  }

  // ─── Base imports ──────────────────────────────────────────────
  buffer.writeln(
    "import 'package:riverpod_annotation/riverpod_annotation.dart';",
  );
  // Build relative path to domain/locator
  final domainPath = '../' * depthToDomain + 'domain';
  buffer.writeln(
    "import '$domainPath/locator/${_toSnakeCase(fileName)}_locator.dart';",
  );

  // ─── Unique entity imports ─────────────────────────────────────
  final entityImports = <String>{};

  for (final item in dynamicDropdowns) {
    final listEntity = item['listEntity']?.toString().trim();
    if (listEntity != null && listEntity.isNotEmpty) {
      final entityFile = _toSnakeCase(listEntity.replaceAll('Entity', ''));
      entityImports.add("import '../domain/entity/${entityFile}_entity.dart';");
    } else {
      final rawLabel =
          (item['label'] ?? item['id'] ?? item['fieldId'] ?? 'model')
              .toString()
              .trim();
      final dropdowndata = item['dropdowndata'];
      String entityFile;
      if (dropdowndata is Map<String, dynamic>) {
        String? derived;
        for (final entry in dropdowndata.entries) {
          final v = entry.value;
          if (v is List && v.isNotEmpty && v.first is Map<String, dynamic>) {
            derived = _toSnakeCase(_singularize(entry.key));
            break;
          }
        }
        entityFile = derived ?? _toSnakeCase(rawLabel);
      } else {
        entityFile = _toSnakeCase(rawLabel);
      }
      entityImports.add("import '../domain/entity/${entityFile}_entity.dart';");
    }
  }

  for (final imp in entityImports) {
    buffer.writeln(imp);
  }

  final notifierFileName = _toSnakeCase(fileName);
  buffer.writeln("part '${notifierFileName}_notifier.g.dart';\n");

  // ─── Generate one notifier per API dropdown field ──────────────
  for (final item in dynamicDropdowns) {
    final rawLabel = (item['label'] ?? item['id'] ?? item['fieldId'] ?? 'field')
        .toString()
        .trim();
    if (rawLabel.isEmpty) continue;

    final pascal = _toPascalCase(rawLabel);
    final camelClass = _lowerFirst(className);
    final name = rawLabel.toLowerCase().replaceAll(RegExp(r'\s+'), '');

    // Resolve entity class name
    String entityClass;
    final listEntity = item['listEntity']?.toString().trim();
    if (listEntity != null && listEntity.isNotEmpty) {
      entityClass = listEntity;
    } else {
      final dropdowndata = item['dropdowndata'];
      if (dropdowndata is Map<String, dynamic>) {
        String? derived;
        for (final entry in dropdowndata.entries) {
          final v = entry.value;
          if (v is List && v.isNotEmpty && v.first is Map<String, dynamic>) {
            derived = '${_capitalize(_singularize(entry.key))}Entity';
            break;
          }
        }
        entityClass = derived ?? '${pascal}Entity';
      } else {
        entityClass = '${pascal}Entity';
      }
    }

    // API method name (configurable, else auto-generated)
    final apiMethod = (item['apiMethod']?.toString().trim().isNotEmpty == true)
        ? item['apiMethod'].toString().trim()
        : 'getAll${_capitalize(name)}s';

    // Determine if the response is a single object or a list
    final isSingleObject =
        item['dropdowndata'] is Map &&
        !(item['dropdowndata'] as Map).values.any((v) => v is List);
    final asyncType = isSingleObject
        ? 'AsyncValue<$entityClass>'
        : 'AsyncValue<List<$entityClass>>';
    final returnType = isSingleObject
        ? 'Future<$entityClass>'
        : 'Future<List<$entityClass>>';

    buffer.writeln('''
/// ===============================================
/// $pascal NOTIFIER
/// ===============================================
@riverpod
class ${pascal}Notifier extends _\$${pascal}Notifier {

  @override
  $asyncType build() async {
    return AsyncValue.data(await fetch());
  }

  $returnType fetch() async {
    // Use the repository provider from the locator
    final result = await ref.read(${camelClass}RepositoryProvider).$apiMethod();

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

// ─── Helpers ──────────────────────────────────────────────────────
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
