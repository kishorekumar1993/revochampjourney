String generateRepositoryInterface(
  String className,
  List<dynamic> configList,
  String fileName, {
  int depthToCore = 4, // unused; kept for backward compatibility
}) {
  final buffer = StringBuffer();

  // ─── Recursive flatten ────────────────────────────────────────
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

  // ─── Collect API dropdown fields ──────────────────────────────
  final apiDropdownFields = <Map<String, dynamic>>[];
  final dropdownFileNames = <String>{};

  for (final field in flatFields) {
    final type = (field['type'] ?? '').toString().toLowerCase();
    if (type == 'dropdown' || type == 'api_dropdown') {
      final useStatic = field['useStaticOptions'] == true;
      final hasApiUrl = field['dropdownApiUrl'] != null;
      final staticOpts =
          (field['options'] as List<dynamic>?) ??
          (field['staticOptions'] as List<dynamic>?);

      if (!useStatic && hasApiUrl) {
        apiDropdownFields.add(field);

        final rawLabel =
            (field['label'] ?? field['id'] ?? field['fieldId'] ?? 'model')
                .toString()
                .trim();

        // Snake_case filename from the original label (NO singularisation)
        final safeFile = rawLabel
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
            .replaceAll(RegExp(r'_+'), '_')
            .replaceAll(RegExp(r'^_|_$'), '');

        dropdownFileNames.add(safeFile);
      } else if (!useStatic && (staticOpts == null || staticOpts.isEmpty)) {
        final rawLabel =
            (field['label'] ?? field['id'] ?? field['fieldId'] ?? 'model')
                .toString()
                .trim();

        final safeFile = rawLabel
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
            .replaceAll(RegExp(r'_+'), '_')
            .replaceAll(RegExp(r'^_|_$'), '');

        dropdownFileNames.add(safeFile);
      }
    }
  }

  // ─── Imports ──────────────────────────────────────────────────
  buffer.writeln("import 'package:dartz/dartz.dart';");
  buffer.writeln("import '/core/error/failures.dart';"); // absolute path as expected

  for (final fileBase in dropdownFileNames) {
    buffer.writeln("import '../entity/${fileBase}_entity.dart';");
  }
  buffer.writeln();

  // ─── Abstract class ───────────────────────────────────────────
  buffer.writeln("abstract class ${className}Repository {");

  for (final item in apiDropdownFields) {
    final rawLabel =
        (item['label'] ?? item['id'] ?? item['fieldId'] ?? 'field')
            .toString()
            .trim();
    if (rawLabel.isEmpty) continue;

    // Remove spaces for method/class naming (e.g. "User Details" → "UserDetails")
    final name = rawLabel.replaceAll(RegExp(r'\s+'), '');

    // Decide List vs single response
    final dropdowndata = item['dropdowndata'];

    // --- Determine entity class name (configurable, with automatic fieldId fallback) ---
    String entityClassBase =
        item['entityClassName']?.toString() ??
        item['entityName']?.toString() ??
        item['modelName']?.toString() ??
        item['fieldId']?.toString() ?? // NEW: use fieldId if no explicit model name
        '';

    if (entityClassBase.isEmpty) {
      // Last resort: derive from label (singularised)
      entityClassBase = _ifaceSingularize(name);
    }

    // Format to proper PascalCase + "Entity" suffix
    String entityClass = _ifaceCapitalize(entityClassBase);
    if (!entityClass.endsWith('Entity')) {
      entityClass = '${entityClass}Entity';
    }

    // Method name: "getAll<Name>(s)?"
    final methodBase = 'getAll${_ifaceCapitalize(name)}';
    final methodName = _ifaceNeedsS(name) ? '${methodBase}s' : methodBase;

    if (dropdowndata is Map) {
      buffer.writeln("  Future<Either<Failure, $entityClass>> $methodName();");
    } else {
      buffer.writeln(
        "  Future<Either<Failure, List<$entityClass>>> $methodName();",
      );
    }
  }

  buffer.writeln("}");
  return buffer.toString();
}

// ─── Helpers ───────────────────────────────────────────────────
String _ifaceCapitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

/// Handles most English plurals; preserves special endings.
String _ifaceSingularize(String word) {
  if (word.endsWith('ies') && word.length > 3) {
    return '${word.substring(0, word.length - 3)}y';
  }
  if (word.endsWith('ss') ||
      word.endsWith('us') ||
      word.endsWith('is') ||
      word.endsWith('as')) {
    return word;
  }
  if (word.endsWith('es') && word.length > 2) {
    final stem = word.substring(0, word.length - 2);
    if (stem.endsWith('ch') ||
        stem.endsWith('sh') ||
        stem.endsWith('x') ||
        stem.endsWith('s') ||
        stem.endsWith('z')) {
      return stem;
    }
    return '${stem}e';
  }
  if (word.endsWith('s') && word.length > 1) {
    return word.substring(0, word.length - 1);
  }
  return word;
}

/// Returns true if the name does **not** already end with 's' – prevents double-s.
bool _ifaceNeedsS(String name) => !name.toLowerCase().endsWith('s');