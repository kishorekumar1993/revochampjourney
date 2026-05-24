String generateRepositoryImplInterface(
  String className,
  List<dynamic> configList,
  String fileName,
) {
  final buffer = StringBuffer();

  // Add necessary imports for functional programming (dartz), failures, and the entity.
  buffer.writeln("import 'package:dartz/dartz.dart';");
  // The entity file is typically in the same feature module, under 'entities'.

  // Use a Set to store unique dropdown model names to avoid duplicate imports.
  final dropdownModels = <String>{}; // ✅ Collect required dropdown model names

  void parseField(Map<String, dynamic> field) {
    final type = field['type'] ?? '';
    if (type == 'Dropdown') {
      final List<dynamic>? staticOpts =
          field['staticOptions'] as List<dynamic>?;
      // only add if staticOptions is null or empty
      if (staticOpts == null || staticOpts.isEmpty) {
        final label = (field['label'] ?? '').toString().trim();
        dropdownModels.add(label);
      }
    }
  }

  // Preprocess fields to collect model imports
  for (var item in configList.expand((e) => e is Iterable ? e : [e])) {
    if (item is Map<String, dynamic>) {
      parseField(item);
    }
  }

  for (final model in dropdownModels) {
    final fileName = model.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    buffer.writeln("import '../../domain/entity/${fileName}_entity.dart';");
  }

  buffer.writeln("import '../../../../../core/errors/failures.dart';");
  buffer.writeln(
    "import '../dataSource/${fileName.toLowerCase().replaceAll(" ", "_")}_data_source.dart';",
  );
  buffer.writeln(
    "import '../../domain/repository/${fileName.toLowerCase().replaceAll(" ", "_")}_repository.dart'; ",
  );
  buffer.writeln("");
  // Define the abstract repository class.
  buffer.writeln(
    "class ${className}RepoImpl implements ${className}Repository {",
  );

  buffer.writeln(
    "final ${className}Datasource ${className.toLowerCase()}Datasource;",
  );
  buffer.writeln(
    "  ${className}RepoImpl(this.${className.toLowerCase()}Datasource);",
  );
  buffer.writeln("");
  buffer.writeln("");
  // Iterate through the configList again to generate repository methods.
  for (var item in configList) {
    final label = (item['label'] ?? '').toString().trim();
    if (label.isEmpty) continue; // Skip if label is empty.

    // Derive names for method and variables.
    final labelname = label.replaceAll(RegExp(r'\s+'), '');
    final name = label.toLowerCase().replaceAll(RegExp(r'\s+'), '');

    // final name = label.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    final apiUrl = item['dropdownApiUrl'] ?? '';
    final modelClassName = label.toString().replaceAll(" ", "");
    // Logic to determine the model name from 'dropdowndata'.
    if (apiUrl.isNotEmpty) {
      buffer.writeln("  @override");
      buffer.writeln(
        "  Future<Either<NoData, ${modelClassName}Entity>> getAll${name}s() async {",
      );
      buffer.writeln("    try {");
      buffer.writeln(
        "      final model = await ${className.toLowerCase()}Datasource.getAll${labelname}s();",
      );
      buffer.writeln("      return Right(model.toDomain());");
      buffer.writeln("    } catch (e) {");
      buffer.writeln("      return Left(NoData(e.toString()));");
      buffer.writeln("    }");
      buffer.writeln("  }");
    }
  }
  buffer.writeln("}");

  return buffer.toString();
}

/// Helper function to capitalize the first letter of a string.
String capitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
