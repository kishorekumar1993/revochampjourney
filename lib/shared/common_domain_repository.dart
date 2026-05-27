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

  // ─── Collect API dropdown fields ────────────────────────────
  final apiDropdownFields = <Map<String, dynamic>>[];
  final dropdownFileNames = <String>{};

  for (final field in flatFields) {
    final type = (field['type'] ?? '').toString().toLowerCase();
    if (type == 'dropdown' || type == 'api_dropdown') {
      final useStatic = field['useStaticOptions'] == true;
      final hasApiUrl = (field['dropdownApiUrl'] ?? '').toString().isNotEmpty;
      final apiRequired = field['apiRequired'] == true;

      if (!useStatic && (hasApiUrl || apiRequired)) {
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
  buffer.writeln("import '/core/runtime/failure.dart';");
  for (final fileBase in dropdownFileNames) {
    buffer.writeln("import '../entity/${fileBase}_entity.dart';");
  }
  buffer.writeln();

  // ─── Abstract class ─────────────────────────────────────────
  buffer.writeln("abstract class ${className}Repository {");

  final generatedMethods = <String>{};
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
    String entityClass = toPascalCase(entityClassBase);
    if (!entityClass.endsWith('Entity')) {
      entityClass = '${entityClass}Entity';
    }

    // Method name: getAll<Name>(s)? – robust pluralization
    final methodName = 'getAll${pluralize(name)}';

    if (generatedMethods.contains(methodName)) continue;
    generatedMethods.add(methodName);

    // Decide return type based on explicit config or dropdowndata structure
    final isSingleObject = item['isSingleObject'] == true ||
        item['responseType'] == 'object' ||
        item['dropdowndata'] is Map;

    if (isSingleObject) {
      buffer.writeln("  Future<Either<Failure, $entityClass>> $methodName();");
    } else {
      buffer.writeln(
        "  Future<Either<Failure, List<$entityClass>>> $methodName();",
      );
    }
  }

  buffer.writeln();
  buffer.writeln("  Future<Either<Failure, Map<String, dynamic>?>> submitStep({");
  buffer.writeln("    required String stepId,");
  buffer.writeln("    required Map<String, dynamic> formData,");
  buffer.writeln("    required String trigger,");
  buffer.writeln("    String? method,");
  buffer.writeln("    String? url,");
  buffer.writeln("    Map<String, String>? headers,");
  buffer.writeln("    dynamic body,");
  buffer.writeln("  });");

  buffer.writeln("}");
  return buffer.toString();
}

// ─── Helpers ──────────────────────────────────────────────────
String toPascalCase(String value) {
  if (value.isEmpty) return value;
  return value
      .split(RegExp(r'[_\s-]+'))
      .where((e) => e.isNotEmpty)
      .map((e) => e[0].toUpperCase() + e.substring(1))
      .join();
}

String pluralize(String value) {
  if (value.isEmpty) return value;
  if (value.endsWith('y')) {
    return '${value.substring(0, value.length - 1)}ies';
  }
  if (value.endsWith('s')) {
    return value;
  }
  return '${value}s';
}
