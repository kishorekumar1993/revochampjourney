String generateRepositoryInterface(
  String className,
  List<dynamic> configList,
  String fileName, {
  int depthToCore = 4,
}) {
  final buffer = StringBuffer();

  // ─── Recursive flatten (unchanged) ──────────────────────────
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

  // ─── Collect API dropdown fields ────────────────────────────
  final apiDropdownFields = <Map<String, dynamic>>[];
  final dropdownFileNames = <String>{};

  for (final field in flatFields) {
    final type = (field['type'] ?? '').toString().toLowerCase();
    if (type == 'dropdown' || type == 'api_dropdown') {
      final useStatic = field['useStaticOptions'] == true;
      final hasApiUrl = (field['dropdownApiUrl'] ?? '').toString().isNotEmpty;
      final staticOpts =
          (field['options'] as List<dynamic>?) ??
          (field['staticOptions'] as List<dynamic>?);

      if (!useStatic &&
          (hasApiUrl || staticOpts != null && staticOpts.isNotEmpty)) {
        apiDropdownFields.add(field);

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

  // ─── Imports ────────────────────────────────────────────────
  buffer.writeln("import 'package:dartz/dartz.dart';");
  buffer.writeln("import '/core/error/failures.dart';");
  for (final fileBase in dropdownFileNames) {
    buffer.writeln("import '../entity/${fileBase}_entity.dart';");
  }
  buffer.writeln();

  // ─── Abstract class ─────────────────────────────────────────
  buffer.writeln("abstract class ${className}Repository {");

  for (final item in apiDropdownFields) {
    final rawLabel = (item['label'] ?? item['id'] ?? item['fieldId'] ?? 'field')
        .toString()
        .trim();
    if (rawLabel.isEmpty) continue;

    // Remove spaces → "UserDetails", "PostTitle"
    final name = rawLabel.replaceAll(RegExp(r'\s+'), '');

    // Determine entity class name – use explicit field or fallback to label (AS-IS, no singularisation)
    String entityClassBase =
        item['entityClassName']?.toString() ??
        item['entityName']?.toString() ??
        item['modelName']?.toString() ??
        item['fieldId']?.toString() ??
        name; // 👈 use the label’s PascalCase directly

    // Ensure it ends with 'Entity'
    String entityClass = _ifaceCapitalize(entityClassBase);
    if (!entityClass.endsWith('Entity')) {
      entityClass = '${entityClass}Entity';
    }

    // Method name: getAll<Name>(s)? – pluralise if name doesn’t already end with 's'
    final methodName = 'getAll$name${_ifaceNeedsS(name) ? 's' : ''}';

    // Decide return type based on dropdowndata structure
    final dropdowndata = item['dropdowndata'];
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

// ─── Helpers (unchanged) ──────────────────────────────────────
String _ifaceCapitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

bool _ifaceNeedsS(String name) => !name.toLowerCase().endsWith('s');
