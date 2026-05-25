String generateRepositoryInterface(
  String className,
  List<dynamic> configList,
  String fileName,
) {
  final buffer = StringBuffer();

  // ─── Recursive flatten (same pattern as controller/view/repoImpl) ──
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

  // ─── Collect API dropdown fields only ─────────────────────────
  // ✅ FIX 1: iterate flatFields (not configList) — catches nested fields
  // ✅ FIX 2: label first, id fallback
  // ✅ FIX 3: lowercase type check + useStaticOptions + dropdownApiUrl guard
  final apiDropdownFields = <Map<String, dynamic>>[];
  final dropdownModels = <String>{};

  for (final field in flatFields) {
    final type = (field['type'] ?? '').toString().toLowerCase();
    if (type == 'dropdown' || type == 'api_dropdown') {
      final useStatic = field['useStaticOptions'] == true;
      final hasApiUrl = field['dropdownApiUrl'] != null;
      final staticOpts = (field['options'] as List<dynamic>?) ??
          (field['staticOptions'] as List<dynamic>?);

      if (!useStatic && hasApiUrl) {
        // Confirmed API dropdown
        apiDropdownFields.add(field);
        final label =
            (field['label'] ?? field['id'] ?? field['fieldId'] ?? 'model')
                .toString()
                .trim();
        dropdownModels.add(label);
      } else if (!useStatic && (staticOpts == null || staticOpts.isEmpty)) {
        // No URL, no static opts — still needs a model
        final label =
            (field['label'] ?? field['id'] ?? field['fieldId'] ?? 'model')
                .toString()
                .trim();
        dropdownModels.add(label);
      }
    }
  }

  // ─── Imports ──────────────────────────────────────────────────
  buffer.writeln("import 'package:dartz/dartz.dart';");
  buffer.writeln("import '../../../../../core/errors/failures.dart';");

  for (final model in dropdownModels) {
    final modelFile = model.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    buffer.writeln("import '../entity/${modelFile}_entity.dart';");
  }

  buffer.writeln();

  // ─── Abstract class ───────────────────────────────────────────
  buffer.writeln("abstract class ${className}Repository {");

  // ✅ FIX 4: iterate apiDropdownFields (already flattened + filtered)
  //           instead of raw configList which missed nested items
  for (final item in apiDropdownFields) {
    final rawLabel =
        (item['label'] ?? item['id'] ?? item['fieldId'] ?? 'field')
            .toString()
            .trim();
    if (rawLabel.isEmpty) continue;

    final name = rawLabel.replaceAll(RegExp(r'\s+'), '');
    final dropdowndata = item['dropdowndata'];

    // Derive model class name from dropdowndata keys if possible
    String? dropdownModel = item['modelName']?.toString();
    if (dropdownModel == null || dropdownModel.isEmpty) {
      if (dropdowndata is Map<String, dynamic>) {
        for (final entry in dropdowndata.entries) {
          final v = entry.value;
          if (v is List && v.isNotEmpty && v.first is Map<String, dynamic>) {
            dropdownModel = '${capitalize(singularize(entry.key))}Entity';
            break;
          }
        }
      }
    }
    dropdownModel ??= '${capitalize(name)}Entity';

    if (dropdowndata is Map) {
      // Single-object response
      buffer.writeln(
        "  Future<Either<Failure, $dropdownModel>> getAll${capitalize(name)}s();",
      );
    } else {
      // List response
      buffer.writeln(
        "  Future<Either<Failure, List<$dropdownModel>>> getAll${capitalize(name)}s();",
      );
    }
  }

  buffer.writeln("}");
  return buffer.toString();
}

// ─── Helpers ──────────────────────────────────────────────────────
String capitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

String singularize(String text) {
  if (text.endsWith('ies')) {
    return '${text.substring(0, text.length - 3)}y';
  }
  if (text.endsWith('s') && text.length > 1) {
    return text.substring(0, text.length - 1);
  }
  return text;
}