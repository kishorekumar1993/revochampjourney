String generateLocatorInterface(
  String className,
  List<dynamic> configList,
  String fileName, {
  int depthToCore = 5,
}) {
  final buffer = StringBuffer();

  // ─── Recursive flatten ─────────────────────────────────────────
  void flattenFields(dynamic source, List<Map<String, dynamic>> result) {
    if (source == null) return;
    if (source is List) {
      for (final item in source) {
        flattenFields(item, result);
      }
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

  // ─── Collect async dropdown fields ────────────────────────────
  final apiDropdownFields = <Map<String, dynamic>>[];
  for (final field in flatFields) {
    final type = (field['type'] ?? '').toString().toLowerCase();
    if (type == 'dropdown' || type == 'api_dropdown') {
      final useStatic = field['useStaticOptions'] == true;
      final hasApiUrl = (field['dropdownApiUrl'] ?? '').toString().isNotEmpty;
      if (!useStatic && hasApiUrl) {
        apiDropdownFields.add(field);
      }
    }
  }

  final fileSnake = fileName.toLowerCase().replaceAll(' ', '_');
  final classLower = _toCamelCase(className);

  // ─── Build relative paths ─────────────────────────────────────
  final corePath = '../' * depthToCore + 'core';

  // ─── Imports ──────────────────────────────────────────────────
  buffer.writeln("import 'package:flutter_riverpod/flutter_riverpod.dart';");
  buffer.writeln("import '/service/api_service.dart';");          // ✅ fixed path
  buffer.writeln("import '../../data/dataSource/${fileSnake}_data_source.dart';");
  buffer.writeln("import '../../data/repositoryimpl/${fileSnake}_repositoryimpl.dart';");
  buffer.writeln("import '../repository/${fileSnake}_repository.dart';");
  buffer.writeln("import '../usecases/${fileSnake}_usecases.dart';");      // ✅ plural 'usecases'
  buffer.writeln();

  // ─── apiServiceProvider (top-level) ───────────────────────────
  buffer.writeln("final apiServiceProvider = Provider<ApiService>((ref) {");
  buffer.writeln("  return ApiService(baseUrl: 'https://your-api-base-url.com');");
  buffer.writeln("});");
  buffer.writeln();

  // ─── DataSource provider ──────────────────────────────────────
  buffer.writeln("/// DataSource provider.");
  buffer.writeln("final ${classLower}DataSourceProvider = Provider.autoDispose<${className}DataSource>((ref) {");
  buffer.writeln("  final apiService = ref.watch(apiServiceProvider);");
  buffer.writeln("  return ${className}DataSourceImpl(apiService);");
  buffer.writeln("});");
  buffer.writeln();

  // ─── Repository provider ──────────────────────────────────────
  buffer.writeln("/// Repository provider.");
  buffer.writeln("final ${classLower}RepositoryProvider = Provider.autoDispose<${className}Repository>((ref) {");
  buffer.writeln("  final dataSource = ref.watch(${classLower}DataSourceProvider);");
  buffer.writeln("  return ${className}RepoImpl(dataSource);");
  buffer.writeln("});");
  buffer.writeln();

  // ─── Use‑case providers (one per async dropdown) ──────────────
  for (final field in apiDropdownFields) {
    final rawLabel = (field['label'] ?? field['id'] ?? 'field').toString().trim();
    final pascalLabel = _pascal(rawLabel.replaceAll(RegExp(r'\s+'), ''));
    final useCaseClass = 'Load${pascalLabel}ListUseCase';
    final providerName = 'load${pascalLabel}ListUseCaseProvider';

    buffer.writeln("/// UseCase provider for [$rawLabel] dropdown.");
    buffer.writeln("final $providerName = Provider.autoDispose<$useCaseClass>((ref) {");
    buffer.writeln("  final repository = ref.watch(${classLower}RepositoryProvider);");
    buffer.writeln("  return $useCaseClass(repository);");
    buffer.writeln("});");
    buffer.writeln();
  }

  return buffer.toString();
}

// ─── Helper functions ────────────────────────────────────────────

/// Converts a string to camelCase (first letter lowercase).
String _toCamelCase(String s) {
  if (s.isEmpty) return s;
  if (s.contains(RegExp(r'[a-z]'))) {
    return s[0].toLowerCase() + s.substring(1);
  }
  final parts = s.split(RegExp(r'[_\s]+'));
  if (parts.isEmpty) return s.toLowerCase();
  return parts[0].toLowerCase() +
      parts.skip(1).map((p) => _capitalize(p)).join();
}

/// Converts a string to PascalCase (first letter uppercase).
String _pascal(String label) {
  final n = label.trim().replaceAll(RegExp(r'\s+'), '');
  return n.isEmpty ? '' : n[0].toUpperCase() + n.substring(1);
}

/// Capitalises the first letter of a string.
String _capitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
