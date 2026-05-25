String generateDataSourceInterface(
  String className,
  List<dynamic> configList,
  String fileName,
) {
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
      final staticOpts = (field['options'] as List<dynamic>?) ??
          (field['staticOptions'] as List<dynamic>?);

      if (!useStatic && hasApiUrl) {
        apiDropdownFields.add(field);
        modelImports.add(_resolveModelFileName(field));
      } else if (!useStatic &&
          (staticOpts == null || staticOpts.isEmpty)) {
        apiDropdownFields.add(field);
        modelImports.add(_resolveModelFileName(field));
      }
    }
  }

  // ─── Imports ──────────────────────────────────────────────────
  // ✅ FIX 5: use ApiService — no raw http/jsonDecode in datasource
  buffer.writeln("import 'dart:convert';");
  buffer.writeln(
      "import '../../../../../core/network/api_service.dart';");
  buffer.writeln(
      "import '../../../../../core/errors/failures.dart';");

  for (final modelFile in modelImports) {
    buffer.writeln("import '../model/${modelFile}_model.dart';");
  }

  buffer.writeln();

  // ─── Abstract datasource interface ────────────────────────────
  buffer.writeln("abstract class ${className}DataSource {");

  for (final item in apiDropdownFields) {
    final rawLabel =
        (item['label'] ?? item['id'] ?? item['fieldId'] ?? 'field')
            .toString()
            .trim();
    if (rawLabel.isEmpty) continue;

    final name = rawLabel.replaceAll(RegExp(r'\s+'), '');
    final dropdowndata = item['dropdowndata'];
    final modelClass = _resolveModelClass(item);

    // ✅ FIX 2: trim trailing 's' only when label already ends with 's'
    //           to avoid getAllUserDetailss() double-s bug
    final methodName = 'getAll${_cap(name)}${_needsS(name) ? "s" : ""}';

    if (dropdowndata is Map) {
      buffer.writeln("  Future<$modelClass> $methodName();");
    } else {
      buffer.writeln(
          "  Future<List<$modelClass>> $methodName();");
    }
  }

  buffer.writeln("}");
  buffer.writeln();

  // ─── Concrete implementation ───────────────────────────────────
  // ✅ FIX 1: implements (not extends) — datasource is a contract/interface
  buffer.writeln(
      "class ${className}DataSourceImpl implements ${className}DataSource {");

  // ✅ FIX 5: inject ApiService, not raw http.Client
  buffer.writeln("  final ApiService apiService;");
  buffer.writeln();
  buffer.writeln(
      "  ${className}DataSourceImpl(this.apiService);");
  buffer.writeln();

  for (final item in apiDropdownFields) {
    final rawLabel =
        (item['label'] ?? item['id'] ?? item['fieldId'] ?? 'field')
            .toString()
            .trim();
    if (rawLabel.isEmpty) continue;

    final name = rawLabel.replaceAll(RegExp(r'\s+'), '');
    final apiUrl =
        (item['dropdownApiUrl'] ?? '').toString().trim();
    final dropdowndata = item['dropdowndata'];
    final modelClass = _resolveModelClass(item);

    // ✅ FIX 2: consistent method name — no double-s
    final methodName =
        'getAll${_cap(name)}${_needsS(name) ? "s" : ""}';

    // Determine list key for Map responses
    String? listKey;
    if (dropdowndata is Map<String, dynamic>) {
      for (final entry in dropdowndata.entries) {
        final v = entry.value;
        if (v is List &&
            v.isNotEmpty &&
            v.first is Map<String, dynamic>) {
          listKey = entry.key;
          break;
        }
      }
    }

    buffer.writeln("  @override");

    if (dropdowndata is Map) {
      buffer.writeln(
          "  Future<$modelClass> $methodName() async {");
    } else {
      buffer.writeln(
          "  Future<List<$modelClass>> $methodName() async {");
    }

    buffer.writeln("    try {");

    // ✅ FIX 5: delegate to ApiService — handles headers, timeout,
    //           connectivity, logging centrally
    buffer.writeln(
        "      // ApiService handles: timeout, connectivity,");
    buffer.writeln(
        "      // auth headers, retry, and debug logging");
    buffer.writeln(
        "      final response = await apiService.get(");
    buffer.writeln("        '$apiUrl',");
    buffer.writeln("        requiresAuth: false,");
    buffer.writeln("      );");
    buffer.writeln();

    // ✅ FIX 4: safe JSON decoding — ApiService already decoded,
    //           but guard against unexpected shape
    buffer.writeln(
        "      // ApiService already returns decoded dynamic —");
    buffer.writeln(
        "      // guard against unexpected non-Map/non-List shape");
    buffer.writeln("      if (response == null) {");
    buffer.writeln(
        "        throw const UnexpectedFailure(");
    buffer.writeln(
        "            message: 'Null response from server');");
    buffer.writeln("      }");
    buffer.writeln();

    if (dropdowndata is Map) {
      if (listKey != null) {
        // Wrapped list response e.g. { "posts": [...] }
        buffer.writeln(
            "      if (response is! Map<String, dynamic>) {");
        buffer.writeln(
            "        throw const UnexpectedFailure(");
        buffer.writeln(
            "            message: 'Expected a JSON object');");
        buffer.writeln("      }");
        buffer.writeln(
            "      return $modelClass.fromJson(");
        buffer.writeln(
            "          response as Map<String, dynamic>);");
      } else {
        // Single object
        buffer.writeln(
            "      if (response is! Map<String, dynamic>) {");
        buffer.writeln(
            "        throw const UnexpectedFailure(");
        buffer.writeln(
            "            message: 'Expected a JSON object');");
        buffer.writeln("      }");
        buffer.writeln(
            "      return $modelClass.fromJson(");
        buffer.writeln(
            "          response as Map<String, dynamic>);");
      }
    } else {
      // List response — may be direct array or wrapped
      buffer.writeln(
          "      final List<dynamic> dataList;");
      buffer.writeln(
          "      if (response is List) {");
      buffer.writeln("        dataList = response;");
      buffer.writeln(
          "      } else if (response is Map<String, dynamic>) {");
      buffer.writeln(
          "        // Unwrap first List value from object");
      buffer.writeln(
          "        final listValue = response.values");
      buffer.writeln(
          "            .whereType<List>()");
      buffer.writeln(
          "            .firstOrNull;");
      buffer.writeln(
          "        if (listValue == null) {");
      buffer.writeln(
          "          throw const UnexpectedFailure(");
      buffer.writeln(
          "              message: 'No list found in response');");
      buffer.writeln("          }");
      buffer.writeln(
          "        dataList = listValue;");
      buffer.writeln("      } else {");
      buffer.writeln(
          "        throw const UnexpectedFailure(");
      buffer.writeln(
          "            message: 'Unexpected response shape');");
      buffer.writeln("      }");
      buffer.writeln();
      buffer.writeln("      return dataList");
      buffer.writeln(
          "          .map((e) => $modelClass.fromJson(");
      buffer.writeln(
          "              e as Map<String, dynamic>))");
      buffer.writeln("          .toList();");
    }

    // ✅ FIX 6: Failure abstraction — catch domain failures first,
    //           ApiService already converts HTTP errors to ApiFailure
    buffer.writeln();
    buffer.writeln("    } on Failure {");
    buffer.writeln("      rethrow;");
    buffer.writeln("    } on ApiFailure catch (e) {");
    // ApiFailure from ApiService — wrap into domain Failure
    buffer.writeln(
        "      throw ServerFailure(");
    buffer.writeln(
        "        message: e.message,");
    buffer.writeln(
        "        statusCode: e.statusCode,");
    buffer.writeln("      );");
    buffer.writeln("    } catch (e, stack) {");
    buffer.writeln("      assert(() {");
    buffer.writeln(
        "        // ignore: avoid_print");
    buffer.writeln(
        "        print('DataSource [$name]: \$e\\n\$stack');");
    buffer.writeln("        return true;");
    buffer.writeln("      }());");
    buffer.writeln(
        "      throw UnexpectedFailure(message: e.toString());");
    buffer.writeln("    }");
    buffer.writeln("  }");
    buffer.writeln();
  }

  buffer.writeln("}");

  return buffer.toString();
}

// ─── Helpers ──────────────────────────────────────────────────────

/// ✅ FIX 2: prevents double-s — "UserDetails" → "getUserDetails"
/// only appends "s" if the name does NOT already end with s/S
bool _needsS(String name) {
  final lower = name.toLowerCase();
  return !lower.endsWith('s');
}

String _resolveModelClass(Map<String, dynamic> field) {
  final dropdowndata = field['dropdowndata'];
  if (dropdowndata is Map<String, dynamic>) {
    for (final entry in dropdowndata.entries) {
      final v = entry.value;
      if (v is List &&
          v.isNotEmpty &&
          v.first is Map<String, dynamic>) {
        return '${_capPascal(_singularize(entry.key))}Model';
      }
    }
  }
  final rawLabel =
      (field['label'] ?? field['id'] ?? 'model').toString().trim();
  return '${_capPascal(rawLabel.replaceAll(RegExp(r'\s+'), ''))}Model';
}

String _resolveModelFileName(Map<String, dynamic> field) {
  final dropdowndata = field['dropdowndata'];
  if (dropdowndata is Map<String, dynamic>) {
    for (final entry in dropdowndata.entries) {
      final v = entry.value;
      if (v is List &&
          v.isNotEmpty &&
          v.first is Map<String, dynamic>) {
        return _singularize(entry.key);
      }
    }
  }
  final rawLabel =
      (field['label'] ?? field['id'] ?? 'model').toString().trim();
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

String _singularize(String text) {
  if (text.endsWith('ies')) {
    return '${text.substring(0, text.length - 3)}y';
  }
  if (text.endsWith('s') && text.length > 1) {
    return text.substring(0, text.length - 1);
  }
  return text;
}