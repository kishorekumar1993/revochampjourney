
String generateRepositoryInterface(
  String className,
  List<dynamic> configList,
  String fileName,
) {
  final buffer = StringBuffer();

  // Add necessary imports for functional programming (dartz), failures, and the entity.
  buffer.writeln("import 'package:dartz/dartz.dart';");
  buffer.writeln("import '../../../../../core/errors/failures.dart';");
  // The entity file is typically in the same feature module, under 'entities'.
 
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

      buffer.writeln("import '../entity/${fileName}_entity.dart';");

  }


  // Define the abstract repository class.
  buffer.writeln("abstract class ${className}Repository {");

  // Iterate through the configList again to generate repository methods.
  for (var item in configList) {
    final label = (item['label'] ?? '').toString().trim();
    if (label.isEmpty) continue; // Skip if label is empty.

    final name = label.replaceAll(RegExp(r'\s+'), '');
    final apiUrl = item['dropdownApiUrl'] ?? '';
    final modelClassName = label.toString().replaceAll(" ", "");
    final dropdowndata = item['dropdowndata'];

    if (apiUrl.isNotEmpty) {
      if (dropdowndata is Map) {
        buffer.writeln(
          "  Future<Either<Failure, ${modelClassName}Entity>> getAll${capitalize(name)}s();",
        );
      } else {
        buffer.writeln(
          "  Future<Either<Failure, List<${modelClassName}Entity>>> getAll${capitalize(name)}s();",
        );
      }
    }
  }
  buffer.writeln("}");

  return buffer.toString();
}

/// Helper function to capitalize the first letter of a string.
String capitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';











  // buffer.writeln(
  //   "  /// Fetches a list of all ${className.toLowerCase()} entities.",
  // );
  // buffer.writeln(
  //   "  /// Returns an [Either] type: [Failure] on the left for errors,",
  // );
  // buffer.writeln("  /// or a [List<$className>] on the right for success.");
