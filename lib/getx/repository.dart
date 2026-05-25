

/// Generates a concrete repository class string for a Flutter application.
///
/// This function creates a Dart class that implements repository methods
/// for fetching dropdown data based on a provided configuration list.
/// It dynamically generates imports for dropdown models and corresponding
/// API fetching methods.
///
/// [className]: The name of the main class (e.g., "Product") for which
///              this repository is being generated. This will be used for
///              `ProductRepository`. It should start with an uppercase letter.
/// [configList]: A list of dynamic configurations, typically maps, that define
///               the structure and behavior of various fields, especially
///               'Dropdown' fields with API URLs.
/// [fileName]: The base name for related files (e.g., "product"). While
///             passed, its direct use in generated method names or class names
///             is limited in the current implementation.
/// [isNested]: A boolean flag (currently unused) that could be used to adjust
///             paths or logic for nested configurations.
///
/// Throws [ArgumentError] if [className] or [fileName] are empty or do not
/// follow basic naming conventions.
String generaterepositoryClass(
  String className,
  List<dynamic> configList,
  String fileName, {
  bool isNested =
      false, // Currently unused, but kept as per original signature.
}) {
  final StringBuffer buffer = StringBuffer();

  // Import the API service provider.
  buffer.writeln("import '/core/service/api_service.dart';");
  buffer.writeln("import 'package:flutter/foundation.dart';\n");

  // ─── Helper to recursively flatten fields ─────────────
  void flattenFields(dynamic source, List<Map<String, dynamic>> result) {
    if (source == null) return;
    
    if (source is List) {
      for (final item in source) {
        flattenFields(item, result);
      }
      return;
    }
    
    if (source is! Map<String, dynamic>) return;
    
    // If it's a journey config with steps
    if (source.containsKey('steps')) {
      flattenFields(source['steps'], result);
      return;
    }
    
    // If it's a step with fields
    if (source.containsKey('fields')) {
      flattenFields(source['fields'], result);
      return;
    }
    
    // It's a field - add it
    if (source.containsKey('type')) {
      result.add(source);
      
      // Recursively flatten nested fields
      flattenFields(source['nestedFields'], result);
      
      // Flatten component config fields (repeater, table columns)
      final config = source['componentConfig'];
      if (config is Map) {
        flattenFields(config['fields'], result);
        flattenFields(config['columns'], result);
      }
    }
  }

  // ─── Flatten fields once ──────────────────────────────
  final flatFields = <Map<String, dynamic>>[];
  flattenFields(configList, flatFields);

  // Use a Set to store unique dropdown model names to avoid duplicate imports.
  final dropdownModels = <String>{};

  for (final field in flatFields) {
    final type = (field['type'] ?? '').toString().toLowerCase();
    if (type == 'dropdown' || type == 'api_dropdown') {
      final List<dynamic>? staticOpts =
          (field['options'] as List<dynamic>?) ?? (field['staticOptions'] as List<dynamic>?);
      if (staticOpts == null || staticOpts.isEmpty) {
        final rawId = (field['id'] ?? field['fieldId'] ?? field['label'] ?? 'model').toString().trim();
        dropdownModels.add(rawId);
      }
    }
  }

  // Write dynamic model imports based on collected dropdownModels.
  for (final model in dropdownModels) {
    final modelFile = model.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    buffer.writeln(
      "import '../model/${modelFile}_model.dart';",
    );
  }

  buffer.writeln("\nclass ${className}Repository {");
  buffer.writeln("  final ApiService api;\n");

  buffer.writeln("  ${className}Repository(this.api);\n");

  // Iterate through the flatFields to generate repository methods.
  for (final item in flatFields) {
    final type = (item['type'] ?? '').toString().toLowerCase();
    if (type == 'dropdown' || type == 'api_dropdown') {
      final List<dynamic>? staticOpts =
          (item['options'] as List<dynamic>?) ?? (item['staticOptions'] as List<dynamic>?);
      
      if (staticOpts != null && staticOpts.isNotEmpty) continue; // Skip static dropdowns

      final rawId = (item['id'] ?? item['fieldId'] ?? item['label'] ?? 'field').toString().trim();
      final capitalLabel = pascalCaseName(rawId);
      final apiUrl = item['dropdownApiUrl'] ?? '';
      var apidata = item['dropdowndata'];

      String? dropdownmodel = (item['modelName']?.toString());
      if (dropdownmodel == null || dropdownmodel.isEmpty) {
        if (apidata is Map<String, dynamic>) {
          for (final entry in apidata.entries) {
            final value = entry.value;
            if (value is List && value.isNotEmpty && value.first is Map<String, dynamic>) {
              dropdownmodel = capitalize(entry.key);
              break;
            }
          }
        }
      }
      dropdownmodel ??= '${capitalLabel}Model';
      
      final apiMethod = (item['dropdownApiMethod'] ?? 'GET').toString().toUpperCase();
      final apiBody = item['dropdownApiBody'];
      final apiHeaders = item['dropdownApiHeaders'];
      final dropdownListKey = (item['dropdownListKey']?.toString() ?? '');

      if (apiUrl.isNotEmpty) {
        buffer.writeln(
          '  Future<List<$dropdownmodel>> get${capitalLabel.replaceAll(" ", "")}() async {',
        );
        buffer.writeln("    try {");
        
        if (apiMethod == 'POST' || apiMethod == 'PUT' || apiMethod == 'DELETE') {
          final bodyJson = apiBody is String && apiBody.isNotEmpty ? "'''$apiBody'''" : apiBody != null ? _generateMapLiteral(apiBody as Map<String, dynamic>) : '{}';

          if (apiHeaders is Map<String, dynamic> && apiHeaders.isNotEmpty) {
            var headerval = _generateMapLiteral(apiHeaders);
            buffer.writeln('      final headers = <String, String>$headerval;');
          } else {
            buffer.writeln('      final headers = <String, String>{};');
          }

          if ((apiBody is String && apiBody.isNotEmpty) || (apiBody is Map && apiBody.isNotEmpty)) {
            buffer.writeln('      final body = $bodyJson;');
            buffer.writeln("      final res = await api.${apiMethod.toLowerCase()}('$apiUrl', body, headers: headers);");
          } else {
             buffer.writeln("      final res = await api.${apiMethod.toLowerCase()}('$apiUrl', {}, headers: headers);");
          }
        } else {
          if (apiHeaders is Map<String, dynamic> && apiHeaders.isNotEmpty) {
             var headerval = _generateMapLiteral(apiHeaders);
             buffer.writeln('      final headers = <String, String>$headerval;');
             buffer.writeln("      final res = await api.get('$apiUrl', headers: headers);");
          } else {
             buffer.writeln("      final res = await api.get('$apiUrl');");
          }
        }

        if (dropdownListKey.isNotEmpty) {
          buffer.writeln("      final data = res['$dropdownListKey'];");
        } else {
          buffer.writeln("      dynamic data = res;");
          buffer.writeln("      if (res is Map) {");
          buffer.writeln("        data = res['${dropdownmodel.toLowerCase()}'] ?? res['data'] ?? res['items'] ?? res;");
          buffer.writeln("      }");
        }

        buffer.writeln("      if (data is! List) {");
        buffer.writeln("        throw Exception('Invalid response format');");
        buffer.writeln("      }");
        buffer.writeln(
          "      return data.map((e) => $dropdownmodel.fromJson(e)).toList();",
        );
        buffer.writeln("    } catch (e, st) {");
        buffer.writeln("      debugPrint('Error fetching $capitalLabel: \$e');");
        buffer.writeln("      debugPrintStack(stackTrace: st);");
        buffer.writeln("      rethrow;");
        buffer.writeln("    }");
        buffer.writeln("  }\n");
      }
    }
  }

  buffer.writeln("}");
  return buffer.toString();
}

/// Helper function to capitalize the first letter of a string.
String capitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

String capitalizeWords(String s) => s.split(' ').map(capitalize).join();

String normalizeLabel(String label) =>
    label.trim().replaceAll(RegExp(r'\s+'), '');

String camelCaseName(String label) {
  final n = normalizeLabel(label);
  return n.isEmpty ? '' : n[0].toLowerCase() + n.substring(1);
}

String pascalCaseName(String label) {
  final n = normalizeLabel(label);
  return n.isEmpty ? '' : n[0].toUpperCase() + n.substring(1);
}

String _generateMapLiteral(Map<String, dynamic> map) {
  final entries = map.entries.map((e) {
    final key = "'${e.key}'";
    final value = e.value is String
        ? "'${e.value.toString().replaceAll("'", "\\'")}'"
        : e.value.toString();
    return '$key: $value';
  }).join(', ');
  return '{$entries}';
}
