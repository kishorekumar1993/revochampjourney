String generateDataSourceInterface(
  String className,
  List<dynamic> configList,
  String fileName, {
  String? packageName,
  String? featurePath,
  String coreImportBase = '/core',         // e.g. '/core' or 'package:myapp/core'
  String apiServiceSubPath = 'service/api_service.dart',
  String failuresSubPath = 'errors/failures.dart',
}) {
  final buffer = StringBuffer();

  // ─── Recursive flatten ─────────────────────────────────────────
  final flatFields = <Map<String, dynamic>>[];

  void flattenFields(dynamic source) {
    if (source == null) return;
    if (source is List) {
      for (final item in source) {
        flattenFields(item);
      }
      return;
    }
    if (source is! Map<String, dynamic>) return;
    if (source.containsKey('steps')) {
      flattenFields(source['steps']);
      return;
    }
    if (source.containsKey('fields')) {
      flattenFields(source['fields']);
      return;
    }
    if (source.containsKey('type')) {
      flatFields.add(source);
      flattenFields(source['nestedFields']);
      final config = source['componentConfig'];
      if (config is Map) {
        flattenFields(config['fields']);
        flattenFields(config['columns']);
      }
    }
  }

  flattenFields(configList);

  // ─── Collect API dropdown fields ──────────────────────────────
  final apiDropdownFields = <Map<String, dynamic>>[];
  final modelImports = <String>{};

  for (final field in flatFields) {
    final type = (field['type'] ?? '').toString().toLowerCase();
    if (type == 'dropdown' || type == 'api_dropdown') {
      final useStatic = field['useStaticOptions'] == true;
      final hasApiUrl = field['dropdownApiUrl'] != null;
      final staticOpts =
          (field['options'] as List<dynamic>?) ??
          (field['staticOptions'] as List<dynamic>?);

      if (!useStatic && hasApiUrl) {
        apiDropdownFields.add(field);
        modelImports.add(_resolveModelFileName(field));
      } else if (!useStatic && (staticOpts == null || staticOpts.isEmpty)) {
        apiDropdownFields.add(field);
        modelImports.add(_resolveModelFileName(field));
      }
    }
  }

  // ─── Imports ──────────────────────────────────────────────────
  buffer.writeln("import '/service/api_service.dart';");
  // Import app_exceptions (ServerException, ParseException)
  buffer.writeln("import '$coreImportBase/network/app_exception.dart';");
  // Import debugPrint
  buffer.writeln("import 'package:flutter/foundation.dart';");
  buffer.writeln();

  for (final modelFile in modelImports) {
    if (packageName != null && featurePath != null) {
      buffer.writeln(
        "import 'package:$packageName/$featurePath/model/${modelFile}_model.dart';",
      );
    } else {
      buffer.writeln("import '../model/${modelFile}_model.dart';");
    }
  }
  buffer.writeln();

  // ─── Abstract datasource interface ────────────────────────────
  buffer.writeln("abstract class ${className}DataSource {");

  for (final item in apiDropdownFields) {
    final rawLabel = (item['label'] ?? item['id'] ?? item['fieldId'] ?? 'field')
        .toString()
        .trim();
    if (rawLabel.isEmpty) continue;

    final name = rawLabel.replaceAll(RegExp(r'\s+'), '');
    final dropdowndata = item['dropdowndata'];
    final modelClass = _resolveModelClass(item);
    final methodName = 'getAll${_cap(name)}${_needsS(name) ? "s" : ""}';

    if (dropdowndata is Map) {
      buffer.writeln("  Future<$modelClass> $methodName();");
    } else {
      buffer.writeln("  Future<List<$modelClass>> $methodName();");
    }
  }
  buffer.writeln("  Future<Map<String, dynamic>?> submitStep({");
  buffer.writeln("    required String stepId,");
  buffer.writeln("    required Map<String, dynamic> formData,");
  buffer.writeln("    required String trigger,");
  buffer.writeln("    String? method,");
  buffer.writeln("    String? url,");
  buffer.writeln("    Map<String, String>? headers,");
  buffer.writeln("    dynamic body,");
  buffer.writeln("  });");
  buffer.writeln("}");
  buffer.writeln();

  // ─── Concrete implementation ───────────────────────────────────
  buffer.writeln(
    "class ${className}DataSourceImpl implements ${className}DataSource {",
  );
  buffer.writeln("  final ApiService apiService;");
  buffer.writeln();
  buffer.writeln("  ${className}DataSourceImpl(this.apiService);");
  buffer.writeln();

  for (final item in apiDropdownFields) {
    final rawLabel = (item['label'] ?? item['id'] ?? item['fieldId'] ?? 'field')
        .toString()
        .trim();
    if (rawLabel.isEmpty) continue;

    final name = rawLabel.replaceAll(RegExp(r'\s+'), '');
    final apiUrl = (item['dropdownApiUrl'] ?? '').toString().trim();
    final dropdowndata = item['dropdowndata'];
    final modelClass = _resolveModelClass(item);
    final methodName = 'getAll${_cap(name)}${_needsS(name) ? "s" : ""}';

    buffer.writeln("  @override");

    if (dropdowndata is Map) {
      buffer.writeln("  Future<$modelClass> $methodName() async {");
      buffer.writeln("    try {");
      buffer.writeln("      final response = await apiService.get(");
      buffer.writeln("        '$apiUrl',");
      buffer.writeln("        requiresAuth: false,");
      buffer.writeln("      );");
      buffer.writeln();
      buffer.writeln("      if (response == null) {");
      buffer.writeln(
        "        throw const ServerException(",
      );
      buffer.writeln("          message: 'Null response from server',");
      buffer.writeln("        );");
      buffer.writeln("      }");
      buffer.writeln("      if (response is! Map<String, dynamic>) {");
      buffer.writeln(
        "        throw const ParseException(",
      );
      buffer.writeln("          message: 'Expected a JSON object',");
      buffer.writeln("        );");
      buffer.writeln("      }");
      buffer.writeln("      return $modelClass.fromJson(response);");
    } else {
      buffer.writeln("  Future<List<$modelClass>> $methodName() async {");
      buffer.writeln("    try {");
      buffer.writeln("      final response = await apiService.get(");
      buffer.writeln("        '$apiUrl',");
      buffer.writeln("        requiresAuth: false,");
      buffer.writeln("      );");
      buffer.writeln();
      buffer.writeln("      if (response == null) {");
      buffer.writeln(
        "        throw const ServerException(",
      );
      buffer.writeln("          message: 'Null response from server',");
      buffer.writeln("        );");
      buffer.writeln("      }");
      buffer.writeln();
      buffer.writeln("      final List<dynamic> dataList;");
      buffer.writeln("      if (response is List) {");
      buffer.writeln("        dataList = response;");
      buffer.writeln("      } else if (response is Map<String, dynamic>) {");
      buffer.writeln(
        "        final listValue = response.values.whereType<List>().firstOrNull;",
      );
      buffer.writeln("        if (listValue == null) {");
      buffer.writeln(
        "          throw const ParseException(",
      );
      buffer.writeln("            message: 'No list found in response',");
      buffer.writeln("          );");
      buffer.writeln("        }");
      buffer.writeln("        dataList = listValue;");
      buffer.writeln("      } else {");
      buffer.writeln(
        "        throw const ParseException(",
      );
      buffer.writeln("          message: 'Unexpected response shape',");
      buffer.writeln("        );");
      buffer.writeln("      }");
      buffer.writeln();
      buffer.writeln("      return dataList");
      buffer.writeln(
        "          .map((e) => $modelClass.fromJson(e as Map<String, dynamic>))",
      );
      buffer.writeln("          .toList();");
    }

    buffer.writeln("    } on ApiFailure catch (e) {");
    buffer.writeln(
      "      throw ServerException(",
    );
    buffer.writeln("        message: e.message,");
    buffer.writeln("        statusCode: e.statusCode,");
    buffer.writeln("      );");
    buffer.writeln("    } catch (e, stack) {");
    buffer.writeln("      assert(() {");
    buffer.writeln("        debugPrint('DataSource [$name]: \$e\\n\$stack');");
    buffer.writeln("        return true;");
    buffer.writeln("      }());");
    buffer.writeln(
      "      throw ServerException(",
    );
    buffer.writeln("        message: e.toString(),");
    buffer.writeln("      );");
    buffer.writeln("    }");
    buffer.writeln("  }");
    buffer.writeln();
  }

  buffer.writeln("  @override");
  buffer.writeln("  Future<Map<String, dynamic>?> submitStep({");
  buffer.writeln("    required String stepId,");
  buffer.writeln("    required Map<String, dynamic> formData,");
  buffer.writeln("    required String trigger,");
  buffer.writeln("    String? method,");
  buffer.writeln("    String? url,");
  buffer.writeln("    Map<String, String>? headers,");
  buffer.writeln("    dynamic body,");
  buffer.writeln("  }) async {");
  buffer.writeln("    if (url == null || url.trim().isEmpty) {");
  buffer.writeln("      return <String, dynamic>{};");
  buffer.writeln("    }");
  buffer.writeln("    final httpMethod = (method ?? 'POST').toUpperCase();");
  buffer.writeln("    final payload = body ?? formData;");
  buffer.writeln("    dynamic response;");
  buffer.writeln("    switch (httpMethod) {");
  buffer.writeln("      case 'GET':");
  buffer.writeln("        response = await apiService.get(url, headers: headers, requiresAuth: false);");
  buffer.writeln("        break;");
  buffer.writeln("      case 'PUT':");
  buffer.writeln("        response = await apiService.put(url, headers: headers, body: payload, requiresAuth: false);");
  buffer.writeln("        break;");
  buffer.writeln("      case 'PATCH':");
  buffer.writeln("        response = await apiService.patch(url, headers: headers, body: payload, requiresAuth: false);");
  buffer.writeln("        break;");
  buffer.writeln("      case 'DELETE':");
  buffer.writeln("        response = await apiService.delete(url, headers: headers, body: payload, requiresAuth: false);");
  buffer.writeln("        break;");
  buffer.writeln("      default:");
  buffer.writeln("        response = await apiService.post(url, headers: headers, body: payload, requiresAuth: false);");
  buffer.writeln("        break;");
  buffer.writeln("    }");
  buffer.writeln("    if (response is Map<String, dynamic>) return response;");
  buffer.writeln("    return <String, dynamic>{'data': response};");
  buffer.writeln("  }");
  buffer.writeln();

  buffer.writeln("}");
  return buffer.toString();
}

// ─── Helpers ──────────────────────────────────────────────────────

bool _needsS(String name) {
  final lower = name.toLowerCase();
  return !lower.endsWith('s');
}

String _resolveModelClass(Map<String, dynamic> field) {
  final rawLabel = (field['label'] ?? field['id'] ?? field['fieldId'] ?? 'model')
      .toString()
      .trim();
  final labelPascal = _capPascal(rawLabel.replaceAll(RegExp(r'\s+'), ''));
  return '${labelPascal}Model';
}

String _resolveModelFileName(Map<String, dynamic> field) {
  final rawLabel = (field['label'] ?? field['id'] ?? field['fieldId'] ?? 'model')
      .toString()
      .trim();
  return rawLabel.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
}

String _cap(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

String _capPascal(String text) {
  if (text.isEmpty) return '';
  return text
      .split(RegExp(r'[_\s]+'))
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join();
}
