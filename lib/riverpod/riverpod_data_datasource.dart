String generateDataSourceInterface(
  String className,
  List<dynamic> configList,
  String fileName, // Not directly used in this snippet, but kept for signature
) {
  final buffer = StringBuffer();

  buffer.writeln("import 'package:flutter/cupertino.dart';");
  buffer.writeln("import 'package:flutter/foundation.dart';");
  buffer.writeln("import 'package:http/http.dart' as http;");
  buffer.writeln("import '../../../../../core/utils/api_utils.dart';");
  buffer.writeln("import 'dart:convert';");
  buffer.writeln("import '../../../../../core/errors/failures.dart';");

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
    buffer.writeln("import '../model/${fileName}_model.dart';");
  }

  // Define the abstract repository class.
  buffer.writeln("abstract class ${className}Datasource {");

  // Iterate through the configList again to generate repository methods.
  for (var item in configList) {
    final label = (item['label'] ?? '').toString().trim();
    if (label.isEmpty) continue; // Skip if label is empty.

    // Derive names for method and variables.
    final name = label.replaceAll(RegExp(r'\s+'), '');
    final apiUrl = item['dropdownApiUrl'] ?? '';
    final modelClassName = label.toString().replaceAll(" ", "");
    final dropdowndata = item['dropdowndata']; // Get the dropdowndata

    // Logic to determine the model name from 'dropdowndata'.
    if (apiUrl.isNotEmpty) {
      // buffer.writeln(" Future<${modelClassName}Model> getAll${name}s();");
      // Prioritize static data if available
      if (dropdowndata != null) {
        if (dropdowndata is List) {
          // Method for static list data
          buffer.writeln(
            "  Future<List<${modelClassName}Model>> getAll${capitalize(name)}s();",
          );
        } else if (dropdowndata is Map) {
          // Method for static single object data
          buffer.writeln(
            "  Future<${modelClassName}Model> getAll${capitalize(name)}s();",
          );
        }
        // You could add an 'else' here for unsupported 'dropdowndata' types
      } else if (apiUrl.isNotEmpty) {
        // Logic for API calls (matching your specified output)
        buffer.writeln(
          "  Future<List<${modelClassName}Model>> getAll${name}s();",
        );
      }
    }
  }
  buffer.writeln("}");

  // Define the abstract repository class.

  buffer.writeln(
    "class ${className}DatasourceImpl extends ${className}Datasource {",
  );
  buffer.writeln("  final http.Client client;");

  buffer.writeln("  ${className}DatasourceImpl(this.client);");

  // Iterate through the configList again to generate repository methods.

  for (var item in configList) {
    final label = (item['label'] ?? '').toString().trim();
    if (label.isEmpty) continue;
    final name = label.replaceAll(RegExp(r'\s+'), '');
    final apiUrl = (item['dropdownApiUrl'] ?? '').toString().trim();
    final modelClassName = label.replaceAll(' ', '');
    final dropdowndata = item['dropdowndata']; // Get the dropdowndata

    if (apiUrl.isNotEmpty) {
      buffer.writeln('  @override');
      // buffer.writeln(
      //   '  Future<List<${modelClassName}Model>> getAll${capitalize(name)}s() async {',
      // );
      if (dropdowndata != null) {
        if (dropdowndata is List) {
          // Method for static list data
          buffer.writeln(
            "  Future<List<${modelClassName}Model>> getAll${capitalize(name)}s() async {",
          );
        } else if (dropdowndata is Map) {
          // Method for static single object data
          buffer.writeln(
            "  Future<${modelClassName}Model> getAll${capitalize(name)}s() async {",
          );
        }
        // You could add an 'else' here for unsupported 'dropdowndata' types
      } else if (apiUrl.isNotEmpty) {
        // Logic for API calls (matching your specified output)
        buffer.writeln(
          "  Future<List<${modelClassName}Model>> getAll${capitalize(name)}s() async {",
        );
      }
      buffer.writeln('    final uri = Uri.parse("$apiUrl");');
      buffer.writeln('    try {');
      buffer.writeln(
        '      final response = await client.get(uri, headers: ApiUtils.defaultHeaders());',
      );
      buffer.writeln('      if (response.statusCode == 200) {');

      if (dropdowndata is Map) {
        buffer.writeln(
          '        final Map<String, dynamic> json = jsonDecode(response.body);',
        );
        buffer.writeln('        return ${modelClassName}Model.fromJson(json);');
      } else {
        buffer.writeln(
          '        final List<dynamic> dataList = jsonDecode(response.body);',
        );
        buffer.writeln(
          '        return dataList.map((e) => ${modelClassName}Model.fromJson(e as Map<String, dynamic>)).toList();',
        );
      }

      buffer.writeln('      } else {');
      buffer.writeln(
        '        throw Exception("Failed to load ${name}s: \${response.statusCode}");',
      );
      buffer.writeln('      }');
      buffer.writeln('    } on NoData {');
      buffer.writeln('      rethrow;');
      buffer.writeln('    } catch (e) {');
      buffer.writeln('      if (kDebugMode) {');
      buffer.writeln('        print(e.toString());');
      buffer.writeln('      }');
      buffer.writeln('      throw Exception(e);');
      buffer.writeln('    }');
      buffer.writeln('  }');
      buffer.writeln('');
    }
  }
  buffer.writeln("}");

  return buffer.toString();
}

/// Helper function to capitalize the first letter of a string.
String capitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

/// Helper function to lowercase the first letter of a string.
String lowercapitalize(String s) =>
    s.isEmpty ? s : '${s[0].toLowerCase()}${s.substring(1)}';
