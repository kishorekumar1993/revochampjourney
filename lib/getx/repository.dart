/// Generates a concrete repository class string for a Flutter application.
///
/// This function creates a Dart class that implements repository methods
/// for fetching dropdown data from APIs based on a provided configuration list.
/// It uses labels (not IDs) for naming and returns raw `List<Map<String, dynamic>>`
/// to avoid unnecessary model imports.
///
/// [className]: Name of the repository class (e.g., "NewJourneyRepository").
/// [configList]: List of configurations (fields, steps, etc.) to scan for API dropdowns.
/// [fileName]: Base file name (unused but kept for signature compatibility).
String generaterepositoryClass(
  String className,
  List<dynamic> configList,
  String fileName, {
  bool isNested = false,
}) {
  final buffer = StringBuffer();

  // Import the API service provider and debug tools.
  buffer.writeln("import '/core/service/api_service.dart';");
  buffer.writeln("import 'package:flutter/foundation.dart';");
  buffer.writeln("import 'dart:convert';\n");

  // -------------------------------------------------------------------
  // Helper to recursively flatten all fields
  // -------------------------------------------------------------------
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

  // -------------------------------------------------------------------
  // Helper to get a clean PascalCase name from label (preferred) or id
  // -------------------------------------------------------------------
  String getPascalName(Map<String, dynamic> field) {
    final raw = (field['label'] ?? field['id'] ?? field['fieldId'] ?? 'field')
        .toString()
        .trim();
    final cleaned = raw.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), ' ');
    final words = cleaned.split(' ');
    final pascal = words.map((w) {
      if (w.isEmpty) return '';
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join();
    return pascal.isEmpty ? 'Field' : pascal;
  }

  // -------------------------------------------------------------------
  // Generate the repository class
  // -------------------------------------------------------------------
  buffer.writeln("class ${className}Repository {");
  buffer.writeln("  final ApiService api;");
  buffer.writeln("  ${className}Repository(this.api);\n");

  // Iterate through flattened fields, generate methods for API dropdowns
  for (final field in flatFields) {
    final type = (field['type'] ?? '').toString().toLowerCase();
    final useStatic = (field['useStaticOptions'] == true);
    final apiUrl = field['dropdownApiUrl']?.toString() ?? '';

    // Only generate for API dropdowns (not static ones)
    if ((type == 'dropdown' || type == 'api_dropdown') && !useStatic && apiUrl.isNotEmpty) {
      final pascalName = getPascalName(field);
      final apiMethod = (field['dropdownApiMethod'] ?? 'GET').toString().toUpperCase();
      final apiBody = field['dropdownApiBody'];
      final apiHeaders = field['dropdownApiHeaders'];
      final listKey = field['dropdownListKey']?.toString() ?? '';

      buffer.writeln("  /// Fetches options for '$pascalName' from $apiUrl");
      buffer.writeln("  Future<List<Map<String, dynamic>>> get${pascalName}Options() async {");
      buffer.writeln("    try {");

      // Prepare headers if any
      if (apiHeaders is Map && apiHeaders.isNotEmpty) {
        buffer.writeln("      final headers = ${_mapToLiteral(apiHeaders)};");
      } else {
        buffer.writeln("      const headers = <String, String>{};");
      }

      // Handle different HTTP methods
      if (apiMethod == 'GET') {
        if (apiHeaders is Map && apiHeaders.isNotEmpty) {
          buffer.writeln("      final response = await api.get('$apiUrl', headers: headers);");
        } else {
          buffer.writeln("      final response = await api.get('$apiUrl');");
        }
      } else {
        // POST, PUT, DELETE, etc.
        final bodyLiteral = _buildBodyLiteral(apiBody);
        buffer.writeln("      final response = await api.${apiMethod.toLowerCase()}('$apiUrl', $bodyLiteral, headers: headers);");
      }

      // Extract the list from response
      buffer.writeln("      List<Map<String, dynamic>> items = [];");
      buffer.writeln("      if (response is List) {");
      buffer.writeln("        items = response.cast<Map<String, dynamic>>();");
      buffer.writeln("      } else if (response is Map) {");
      if (listKey.isNotEmpty) {
        buffer.writeln("        final data = response['$listKey'];");
        buffer.writeln("        if (data is List) items = data.cast<Map<String, dynamic>>();");
      } else {
        buffer.writeln("        // Try to find the first list in the response");
        buffer.writeln("        for (final value in response.values) {");
        buffer.writeln("          if (value is List) {");
        buffer.writeln("            items = value.cast<Map<String, dynamic>>();");
        buffer.writeln("            break;");
        buffer.writeln("          }");
        buffer.writeln("        }");
      }
      buffer.writeln("      }");
      buffer.writeln("      return items;");
      buffer.writeln("    } catch (e, st) {");
      buffer.writeln("      debugPrint('Error fetching $pascalName options: \$e');");
      buffer.writeln("      debugPrintStack(stackTrace: st);");
      buffer.writeln("      rethrow;");
      buffer.writeln("    }");
      buffer.writeln("  }\n");
    }
  }

  buffer.writeln("}");
  return buffer.toString();
}

// -------------------------------------------------------------------
// Helper functions
// -------------------------------------------------------------------

/// Converts a Map to a Dart map literal string.
String _mapToLiteral(Map<dynamic, dynamic> map) {
  final entries = map.entries.map((e) {
    final key = "'${e.key.toString().replaceAll("'", "\\'")}'";
    final value = e.value is String
        ? "'${e.value.toString().replaceAll("'", "\\'")}'"
        : e.value.toString();
    return "$key: $value";
  }).join(', ');
  return "{ $entries }";
}

/// Builds a Dart literal for the request body (supports String, Map, or null).
String _buildBodyLiteral(dynamic body) {
  if (body == null) return "null";
  if (body is String) {
    if (body.trim().startsWith('{') || body.trim().startsWith('[')) {
      // Assume it's already JSON-like literal; use as-is
      return body;
    }
    // String body, wrap in quotes
    return "'${body.replaceAll("'", "\\'")}'";
  }
  if (body is Map) {
    return _mapToLiteral(body);
  }
  return "null";
}