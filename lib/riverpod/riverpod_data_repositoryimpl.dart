String generateRepositoryImplInterface(
  String className,
  List<dynamic> configList,
  String fileName,
) {
  final buffer = StringBuffer();

  // ─── Recursive flatten (same pattern as controller/view) ──────
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
  // ✅ FIX 1: iterate flatFields not configList
  // ✅ FIX 2: label first, id fallback
  // ✅ FIX 3: same isApiDropdown logic as controller/view
  final apiDropdownFields = <Map<String, dynamic>>[];
  final dropdownModels = <String>{};

  for (final field in flatFields) {
    final type = (field['type'] ?? '').toString().toLowerCase();
    if (type == 'dropdown' || type == 'api_dropdown') {
      final useStatic = field['useStaticOptions'] == true;
      final hasApiUrl = field['dropdownApiUrl'] != null;
      final staticOpts = (field['options'] as List<dynamic>?) ??
          (field['staticOptions'] as List<dynamic>?);

      // Only treat as API dropdown if it has a URL and is not forced static
      if (!useStatic && hasApiUrl) {
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

  for (final model in dropdownModels) {
    final modelFile = model.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    buffer.writeln(
        "import '../../domain/entity/${modelFile}_entity.dart';");
  }

  buffer.writeln("import '../../../../../core/errors/failures.dart';");
  buffer.writeln(
    "import '../dataSource/${fileName.toLowerCase().replaceAll(' ', '_')}_data_source.dart';",
  );
  buffer.writeln(
    "import '../../domain/repository/${fileName.toLowerCase().replaceAll(' ', '_')}_repository.dart';",
  );
  buffer.writeln();

  // ─── Class definition ─────────────────────────────────────────
  buffer.writeln(
      "class ${className}RepoImpl implements ${className}Repository {");
  buffer.writeln(
      "  final ${className}Datasource ${className.toLowerCase()}Datasource;");
  buffer.writeln(
      "  ${className}RepoImpl(this.${className.toLowerCase()}Datasource);");
  buffer.writeln();

  // ─── Generate one method per API dropdown field ───────────────
  // ✅ FIX 4: iterate apiDropdownFields (already filtered) instead of
  //           re-iterating configList which missed nested items
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
            dropdownModel =
                '${capitalize(singularize(entry.key))}Entity';
            break;
          }
        }
      }
    }
    dropdownModel ??= '${capitalize(name)}Entity';

    buffer.writeln("  @override");
    if (dropdowndata is Map) {
      // Single-object response
      buffer.writeln(
          "  Future<Either<Failure, $dropdownModel>> getAll${capitalize(name)}s() async {");
      buffer.writeln("    try {");
      buffer.writeln(
          "      final model = await ${className.toLowerCase()}Datasource.getAll${capitalize(name)}s();");
      buffer.writeln("      return Right(model.toDomain());");
    } else {
      // List response
      buffer.writeln(
          "  Future<Either<Failure, List<$dropdownModel>>> getAll${capitalize(name)}s() async {");
      buffer.writeln("    try {");
      buffer.writeln(
          "      final models = await ${className.toLowerCase()}Datasource.getAll${capitalize(name)}s();");
      buffer.writeln(
          "      return Right(models.map((model) => model.toDomain()).toList());");
    }
    buffer.writeln("    } catch (e) {");
    buffer.writeln("      return Left(NoData(e.toString()));");
    buffer.writeln("    }");
    buffer.writeln("  }");
    buffer.writeln();
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

// String generateRepositoryImplInterface(
//   String className,
//   List<dynamic> configList,
//   String fileName,
// ) {
//   final buffer = StringBuffer();

//   // Add necessary imports for functional programming (dartz), failures, and the entity.
//   buffer.writeln("import 'package:dartz/dartz.dart';");
//   // The entity file is typically in the same feature module, under 'entities'.

//   // Use a Set to store unique dropdown model names to avoid duplicate imports.
//   final dropdownModels = <String>{}; // ✅ Collect required dropdown model names

//   void parseField(Map<String, dynamic> field) {
//     final type = field['type'] ?? '';
//     if (type == 'Dropdown') {
//       final List<dynamic>? staticOpts =
//           field['staticOptions'] as List<dynamic>?;
//       // only add if staticOptions is null or empty
//       if (staticOpts == null || staticOpts.isEmpty) {
//         final label = (field['label'] ?? '').toString().trim();
//         dropdownModels.add(label);
//       }
//     }
//   }

//   // Preprocess fields to collect model imports
//   for (var item in configList.expand((e) => e is Iterable ? e : [e])) {
//     if (item is Map<String, dynamic>) {
//       parseField(item);
//     }
//   }

//   for (final model in dropdownModels) {
//     final fileName = model.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
//     buffer.writeln("import '../../domain/entity/${fileName}_entity.dart';");
//   }

//   buffer.writeln("import '../../../../../core/errors/failures.dart';");
//   buffer.writeln(
//     "import '../dataSource/${fileName.toLowerCase().replaceAll(" ", "_")}_data_source.dart';",
//   );
//   buffer.writeln(
//     "import '../../domain/repository/${fileName.toLowerCase().replaceAll(" ", "_")}_repository.dart'; ",
//   );
//   buffer.writeln("");
//   // Define the abstract repository class.
//   buffer.writeln(
//     "class ${className}RepoImpl implements ${className}Repository {",
//   );

//   buffer.writeln(
//     "final ${className}Datasource ${className.toLowerCase()}Datasource;",
//   );
//   buffer.writeln(
//     "  ${className}RepoImpl(this.${className.toLowerCase()}Datasource);",
//   );
//   buffer.writeln("");
//   buffer.writeln("");
//   // Iterate through the configList again to generate repository methods.
//   for (var item in configList) {
//     final label = (item['label'] ?? '').toString().trim();
//     if (label.isEmpty) continue; // Skip if label is empty.

//     // Derive names for method and variables.
//     final name = label.replaceAll(RegExp(r'\s+'), '');
//     final apiUrl = item['dropdownApiUrl'] ?? '';
//     final modelClassName = label.toString().replaceAll(" ", "");
//     final dropdowndata = item['dropdowndata'];

//     if (apiUrl.isNotEmpty) {
//       buffer.writeln("  @override");
//       if (dropdowndata is Map) {
//         buffer.writeln(
//           "  Future<Either<Failure, ${modelClassName}Entity>> getAll${capitalize(name)}s() async {",
//         );
//         buffer.writeln("    try {");
//         buffer.writeln(
//           "      final model = await ${className.toLowerCase()}Datasource.getAll${capitalize(name)}s();",
//         );
//         buffer.writeln("      return Right(model.toDomain());");
//       } else {
//         buffer.writeln(
//           "  Future<Either<Failure, List<${modelClassName}Entity>>> getAll${capitalize(name)}s() async {",
//         );
//         buffer.writeln("    try {");
//         buffer.writeln(
//           "      final models = await ${className.toLowerCase()}Datasource.getAll${capitalize(name)}s();",
//         );
//         buffer.writeln("      return Right(models.map((model) => model.toDomain()).toList());");
//       }
//       buffer.writeln("    } catch (e) {");
//       buffer.writeln("      return Left(NoData(e.toString()));");
//       buffer.writeln("    }");
//       buffer.writeln("  }");
//     }
//   }
//   buffer.writeln("}");

//   return buffer.toString();
// }

// /// Helper function to capitalize the first letter of a string.
// String capitalize(String s) =>
//     s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
