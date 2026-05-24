

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

  // Basic validation for className and fileName
  // if (className.isEmpty || !RegExp(r'^[A-Z][a-zA-Z0-9]*$').hasMatch(className)) {
  //   throw ArgumentError(
  //       'className must be a non-empty string, start with an uppercase letter, '
  //       'and contain only alphanumeric characters. Example: "Product"');
  // }
  // if (fileName.isEmpty || !RegExp(r'^[a-z_][a-z0-9_]*$').hasMatch(fileName)) {
  //   throw ArgumentError(
  //       'fileName must be a non-empty string, lowercase, and can contain '
  //       'underscores and alphanumeric characters. Example: "product" or "product_detail"');
  // }

  // Import the API service provider.
  buffer.writeln("import '/core/service/api_service.dart';\n");

  // Use a Set to store unique dropdown model names to avoid duplicate imports.
  final dropdownModels = <String>{};

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

  // Preprocess configList to collect all required dropdown model imports.
  // This handles cases where configList might contain nested iterables.
  for (var item in configList.expand((e) => e is Iterable ? e : [e])) {
    if (item is Map<String, dynamic>) {
      parseField(item);
    }
  }

  // Write dynamic model imports based on collected dropdownModels.
  for (final model in dropdownModels) {
    buffer.writeln(
      "import '../model/${model.toLowerCase().replaceAll(" ", "_")}_model.dart';",
    );
  }

  buffer.writeln("\nclass ${className}Repository {");
  buffer.writeln("  final ApiService api;\n");

  buffer.writeln("  ${className}Repository(this.api);\n");

  // Iterate through the configList again to generate repository methods.
  for (var item in configList) {
    // Ensure the item is a Map and represents a 'Dropdown' type.
    if (item is Map<String, dynamic> && item['type'] == 'Dropdown') {
      final label = (item['label'] ?? '').toString().trim();
      if (label.isEmpty) continue; // Skip if label is empty.

      // // Derive names for method and variables.
      // final name = label.toLowerCase().replaceAll(RegExp(r'\s+'), '');
      // final capitalLabel = capitalize(name);
      final rawLabel = (item['label'] ?? '').toString().trim();
      final capitalLabel = capitalizeWords(rawLabel); // NEW helper

      // final capitalLabel = capitalize(label);
      final apiUrl = item['dropdownApiUrl'] ?? '';
      var apidata = item['dropdowndata'];

      String?
      dropdownmodel; // Store the determined model name for this specific dropdown.

      // Logic to determine the model name from 'dropdowndata'.
      if (apidata is Map<String, dynamic>) {
        for (final entry in apidata.entries) {
          final key = entry.key;
          final value = entry.value;

          if (value is List &&
              value.isNotEmpty &&
              value.first is Map<String, dynamic>) {
            dropdownmodel = capitalize(key);
            break; // Found the model for this dropdown, exit loop.
          }
        }
      }
      dropdownmodel ??= '${capitalizeWords(label)}Model';
      // final apiMethod = (item['apiMethod'] ?? 'GET').toString().toUpperCase();
      final apiMethod = item['dropdownApiMethod'] ;
      final apiBody = item['dropdownApiBody'];
      final apiHeaders = item['dropdownApiHeaders'];

      // Only generate the method if an API URL and a valid dropdown model are found.
      if (apiUrl.isNotEmpty) {
        // Generate the asynchronous method signature.
        buffer.writeln(
          '  Future<List<$dropdownmodel>> get${capitalLabel.replaceAll(" ", "")}() async {',
        );
        buffer.writeln("  try {");
        // Make the API call using the provided ApiProvider.
        // buffer.writeln("    final res = await api.get('$apiUrl');");

        if (apiMethod == 'POST') {
          final bodyJson =
              apiBody; 
              // != null
              //     ? jsonEncode(apiBody).replaceAll('"', '\\"')
              //     : '{}';

          if (apiHeaders is Map<String, dynamic>) {
            final headerJson = apiHeaders;
            var headerval=_generateMapLiteral(headerJson);
            buffer.writeln('      final headers = $headerval;');
          } else {
            buffer.writeln('      final headers = <String, String>{};');
          }

          buffer.writeln('      final body = $bodyJson;');
          buffer.writeln(
            "      final res = await api.post('$apiUrl', body, headers: headers);",
          );
        } else {
          buffer.writeln("      final res = await api.get('$apiUrl');");
        }
        // Extract the list of data from the response, assuming it's under a key
        // derived from the dropdownmodel name (e.g., 'products' for ProductModel).
        // buffer.writeln(
        //   "    final List ${capitalLabel.replaceAll(" ", "").toLowerCase()} = res['${dropdownmodel.toLowerCase()}'];",
        // );
        // // Map the raw JSON list to a list of model objects.
        // buffer.writeln(
        //   "    return ${capitalLabel.replaceAll(" ", "").toLowerCase()}.map((e) => $dropdownmodel.fromJson(e)).toList();",
        // );
        buffer.writeln(
          "      final data = res['${dropdownmodel.toLowerCase()}'];",
        );
        buffer.writeln("      if (data is! List) {;");
        buffer.writeln("      throw Exception('Invalid response format');");
        buffer.writeln("     }");
        buffer.writeln(
          "      return data.map((e) => $dropdownmodel.fromJson(e)).toList();",
        );
        buffer.writeln("  } catch (e, st) {");
        buffer.writeln("    debugPrint('Error fetching $capitalLabel: \$e');");
        buffer.writeln("    debugPrintStack(stackTrace: st);");
        buffer.writeln("    rethrow;");
        buffer.writeln("  }");
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
