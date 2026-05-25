String generateLocatorInterface(
  String className,
  List<dynamic> configList,
  String fileName,
) {
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

  // ─── Collect API dropdown fields ──────────────────────────────
  final apiDropdownFields = <Map<String, dynamic>>[];
  for (final field in flatFields) {
    final type = (field['type'] ?? '').toString().toLowerCase();
    if (type == 'dropdown' || type == 'api_dropdown') {
      final useStatic = field['useStaticOptions'] == true;
      final hasApiUrl = field['dropdownApiUrl'] != null;
      final staticOpts = (field['options'] as List<dynamic>?) ??
          (field['staticOptions'] as List<dynamic>?);
      if (!useStatic && hasApiUrl) {
        apiDropdownFields.add(field);
      } else if (!useStatic && (staticOpts == null || staticOpts.isEmpty)) {
        apiDropdownFields.add(field);
      }
    }
  }

  final fileSnake = fileName.toLowerCase().replaceAll(' ', '_');
  final classLower = _toCamelCase(className);

  // ─── Imports ──────────────────────────────────────────────────
  buffer.writeln(
      "import 'package:flutter_riverpod/flutter_riverpod.dart';");
  buffer.writeln(
      "import '../../../../../network/client/client_provider.dart';");
  buffer.writeln(
      "import '../../data/dataSource/${fileSnake}_data_source.dart';");
  buffer.writeln(
      "import '../../data/repositoryimpl/${fileSnake}_repositoryimpl.dart';");
  buffer.writeln(
      "import '../repository/${fileSnake}_repository.dart';");

  // ✅ UseCase imports — one per API dropdown field
  for (final field in apiDropdownFields) {
    final rawLabel =
        (field['label'] ?? field['id'] ?? field['fieldId'] ?? 'field')
            .toString()
            .trim();
    final useCaseFile =
        'get_all_${rawLabel.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}_usecase';
    buffer.writeln("import '../usecase/$useCaseFile.dart';");
  }

  buffer.writeln();

  // ─── DataSource provider ───────────────────────────────────────
  buffer.writeln("/// DataSource provider.");
  buffer.writeln(
      "/// [${className}DataSource] → abstract interface.");
  buffer.writeln(
      "/// [${className}DataSourceImpl] → concrete HTTP implementation.");
  buffer.writeln(
      "final ${classLower}DataSourceProvider = Provider.autoDispose<${className}DataSource>((ref) {");
  buffer.writeln("  final client = ref.watch(httpClientProvider);");
  buffer.writeln("  return ${className}DataSourceImpl(client);");
  buffer.writeln("});");
  buffer.writeln();

  // ─── Repository provider ───────────────────────────────────────
  buffer.writeln("/// Repository provider.");
  buffer.writeln(
      "/// Bridges [${className}DataSource] ↔ [${className}Repository] interface.");
  buffer.writeln(
      "final ${classLower}RepositoryProvider = Provider.autoDispose<${className}Repository>((ref) {");
  buffer.writeln(
      "  final dataSource = ref.watch(${classLower}DataSourceProvider);");
  buffer.writeln("  return ${className}RepoImpl(dataSource);");
  buffer.writeln("});");
  buffer.writeln();

  // ─── UseCase providers — one per API dropdown ──────────────────
  // ✅ UI → Notifier → UseCase Provider → Repository
  // Notifier calls ref.read(xxxUseCaseProvider) and invokes .call()
  for (final field in apiDropdownFields) {
    final rawLabel =
        (field['label'] ?? field['id'] ?? field['fieldId'] ?? 'field')
            .toString()
            .trim();
    final name = rawLabel.replaceAll(RegExp(r'\s+'), '');
    final pascal = _pascal(name);
    final lower = _toCamelCase(pascal);

    // Derive entity class from dropdowndata keys
    String entityClass = '${pascal}Entity';
    final dropdowndata = field['dropdowndata'];
    if (dropdowndata is Map<String, dynamic>) {
      for (final entry in dropdowndata.entries) {
        final v = entry.value;
        if (v is List &&
            v.isNotEmpty &&
            v.first is Map<String, dynamic>) {
          entityClass =
              '${_capitalize(_singularize(entry.key))}Entity';
          break;
        }
      }
    }

    final useCaseClass = 'GetAll${pascal}UseCase';

    buffer.writeln("/// UseCase provider for [$pascal].");
    buffer.writeln(
        "/// Returns [Either<Failure, List<$entityClass>>].");
    buffer.writeln(
        "/// Usage: ref.read(${lower}UseCaseProvider).call()");
    buffer.writeln(
        "final ${lower}UseCaseProvider = Provider.autoDispose<$useCaseClass>((ref) {");
    buffer.writeln(
        "  final repository = ref.watch(${classLower}RepositoryProvider);");
    buffer.writeln("  return $useCaseClass(repository);");
    buffer.writeln("});");
    buffer.writeln();
  }

  return buffer.toString();
}

// ─── Helpers ──────────────────────────────────────────────────────

/// "UserJourneyForm" → "userJourneyForm"
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

String _pascal(String label) {
  final n = label.trim().replaceAll(RegExp(r'\s+'), '');
  return n.isEmpty ? '' : n[0].toUpperCase() + n.substring(1);
}

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

// String generateLocaltorInterface(
//   String className,
//   List<dynamic> configList,
//   String fileName, // Not directly used in this snippet, but kept for signature
// ) {
//   final buffer = StringBuffer();
//   buffer.writeln('''
// import  '../../data/repositoryimpl/${fileName.toLowerCase().replaceAll(" ", "_")}_repositoryimpl.dart';
// import '../repository/${fileName.toLowerCase().replaceAll(" ", "_")}_repository.dart';
// import '../../data/dataSource/${fileName.toLowerCase().replaceAll(" ", "_")}_data_source.dart';

// import '../../../../../network/client/client_provider.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';



// final connectionProvider = Provider<${className}Datasource>((ref) {
//   final client = ref.watch(httpClientProvider);
//   return ${className}DatasourceImpl(client);
// });
// final ${lowercapitalize(className)}ViewProvider = Provider<${className}Repository>((ref) {
//   final dataSource = ref.watch(connectionProvider);
//   return ${className}RepoImpl(dataSource);
// });
// ''');

//   return buffer.toString();
// }

// /// Helper function to capitalize the first letter of a string.
// String capitalize(String s) =>
//     s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

// /// Helper function to lowercase the first letter of a string.
// String lowercapitalize(String s) =>
//     s.isEmpty ? s : '${s[0].toLowerCase()}${s.substring(1)}';
