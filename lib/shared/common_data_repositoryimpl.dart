String generateRepositoryImplInterface(
  String className,
  List<dynamic> configList,
  String fileName, {
  String? packageName, // e.g. 'testenv'
  String? featurePath, // e.g. 'features/new/userjourney'
  String coreImportBase = '/core',
  String failuresSubPath = 'error/failures.dart',
  String dataSourceImport =
      '../dataSource/', // exact import path for datasource
}) {
  final buffer = StringBuffer();

  // ─── Flatten fields ───────────────────────────────────────────
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
    if (source.containsKey('steps')) flattenFields(source['steps']);
    if (source.containsKey('fields')) flattenFields(source['fields']);
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

  // ─── Identify API dropdown fields ─────────────────────────────
  final apiDropdownFields = <Map<String, dynamic>>[];
  final entityFileNames = <String>[]; // ordered, for ordered imports

  for (final field in flatFields) {
    final type = (field['type'] ?? '').toString().toLowerCase();
    if (type == 'dropdown' || type == 'api_dropdown') {
      final useStatic = field['useStaticOptions'] == true;
      final hasApiUrl = (field['dropdownApiUrl'] ?? '').toString().isNotEmpty;
      final apiRequired = field['apiRequired'] == true;

      if (!useStatic && (hasApiUrl || apiRequired)) {
        apiDropdownFields.add(field);

        final rawLabel =
            (field['label'] ?? field['id'] ?? field['fieldId'] ?? 'model')
                .toString()
                .trim();

        // snake_case file name — preserve original label as-is (no singularize)
        final safeFile = rawLabel
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
            .replaceAll(RegExp(r'_+'), '_')
            .replaceAll(RegExp(r'^_|_$'), '');

        if (!entityFileNames.contains(safeFile)) {
          entityFileNames.add(safeFile);
        }
      }
    }
  }

  // ─── snake_case file name for datasource/repository ───────────
  final snakeFileName = fileName
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');

  // ─── Imports ──────────────────────────────────────────────────

  // 1. dartz
  buffer.writeln("import 'package:dartz/dartz.dart';");
  buffer.writeln("import '/core/network/failure_mapper.dart';");
  buffer.writeln("import '/core/runtime/failure.dart';");

  // 2. Package-based entity import (first field only, if packageName given)
  if (packageName != null &&
      featurePath != null &&
      entityFileNames.isNotEmpty) {
    buffer.writeln(
      "import 'package:$packageName/$featurePath/domain/entity/${entityFileNames.first}_entity.dart';",
    );
  }

  // 3. Core failures import

  // 4. Datasource import (single, using exact path)
  buffer.writeln(
    "import '$dataSourceImport${snakeFileName}_data_source.dart';",
  );
  buffer.writeln();

  // 5. Remaining entity imports (relative, skip first if already package-imported)
  final startIndex = (packageName != null && featurePath != null) ? 1 : 0;
  for (int i = startIndex; i < entityFileNames.length; i++) {
    buffer.writeln(
      "import '../../domain/entity/${entityFileNames[i]}_entity.dart';",
    );
  }

  // 6. Repository interface import
  buffer.writeln(
    "import '../../domain/repository/${snakeFileName}_repository.dart';",
  );
  buffer.writeln();

  // ─── Class definition ─────────────────────────────────────────
  final classLower = className[0].toLowerCase() + className.substring(1);

  buffer.writeln(
    "class ${className}RepoImpl implements ${className}Repository {",
  );
  buffer.writeln("  final ${className}DataSource ${classLower}Datasource;");
  buffer.writeln();
  buffer.writeln("  ${className}RepoImpl(this.${classLower}Datasource);");
  buffer.writeln();

  // ─── Generate methods ─────────────────────────────────────────
  final generatedMethods = <String>{};
  for (final item in apiDropdownFields) {
    final rawLabel = (item['label'] ?? item['id'] ?? item['fieldId'] ?? 'field')
        .toString()
        .trim();
    if (rawLabel.isEmpty) continue;

    final name = rawLabel.replaceAll(RegExp(r'\s+'), '');

    String entityClassBase =
        item['entityClassName']?.toString() ??
        item['entityName']?.toString() ??
        item['modelName']?.toString() ??
        item['fieldId']?.toString() ??
        name;

    String entityClassName = toPascalCase(entityClassBase);
    if (!entityClassName.endsWith('Entity')) {
      entityClassName = '${entityClassName}Entity';
    }

    final methodName = 'getAll${pluralize(name)}';

    if (generatedMethods.contains(methodName)) continue;
    generatedMethods.add(methodName);

    buffer.writeln("  @override");

    final isSingleObject = item['isSingleObject'] == true ||
        item['responseType'] == 'object' ||
        item['dropdowndata'] is Map;

    if (isSingleObject) {
      buffer.writeln(
        "  Future<Either<Failure, $entityClassName>> $methodName() async {",
      );
      buffer.writeln("    try {");
      buffer.writeln(
        "      final model = await ${classLower}Datasource.$methodName();",
      );
      buffer.writeln("      return Right(model.toDomain());");
    } else {
      buffer.writeln(
        "  Future<Either<Failure, List<$entityClassName>>> $methodName() async {",
      );
      buffer.writeln("    try {");
      buffer.writeln(
        "      final models = await ${classLower}Datasource.$methodName();",
      );
      buffer.writeln(
        "      return Right(models.map((m) => m.toDomain()).toList());",
      );
    }

    buffer.writeln("    } catch (e) {");
    buffer.writeln(
      "      return Left(mapExceptionToFailure(e));",
    );
    buffer.writeln("    }");
    buffer.writeln("  }");
    buffer.writeln();
  }

  buffer.writeln("  @override");
  buffer.writeln("  Future<Either<Failure, Map<String, dynamic>?>> submitStep({");
  buffer.writeln("    required String stepId,");
  buffer.writeln("    required Map<String, dynamic> formData,");
  buffer.writeln("    required String trigger,");
  buffer.writeln("    String? method,");
  buffer.writeln("    String? url,");
  buffer.writeln("    Map<String, String>? headers,");
  buffer.writeln("    dynamic body,");
  buffer.writeln("  }) async {");
  buffer.writeln("    try {");
  buffer.writeln(
    "      final result = await (${classLower}Datasource as dynamic).submitStep(",
  );
  buffer.writeln("        stepId: stepId,");
  buffer.writeln("        formData: formData,");
  buffer.writeln("        trigger: trigger,");
  buffer.writeln("        method: method,");
  buffer.writeln("        url: url,");
  buffer.writeln("        headers: headers,");
  buffer.writeln("        body: body,");
  buffer.writeln("      );");
  buffer.writeln("      if (result is Map<String, dynamic> || result == null) {");
  buffer.writeln("        return Right(result as Map<String, dynamic>?);");
  buffer.writeln("      }");
  buffer.writeln("      return Right(<String, dynamic>{});");
  buffer.writeln("    } catch (e) {");
  buffer.writeln("      return Left(mapExceptionToFailure(e));");
  buffer.writeln("    }");
  buffer.writeln("  }");
  buffer.writeln();

  buffer.writeln("}");
  return buffer.toString();
}

// ─── Helpers ──────────────────────────────────────────────────────

String toPascalCase(String value) {
  if (value.isEmpty) return value;
  return value
      .split(RegExp(r'[_\s-]+'))
      .where((e) => e.isNotEmpty)
      .map((e) => e[0].toUpperCase() + e.substring(1))
      .join();
}

String pluralize(String value) {
  if (value.isEmpty) return value;
  if (value.endsWith('y')) {
    return '${value.substring(0, value.length - 1)}ies';
  }
  if (value.endsWith('s')) {
    return value;
  }
  return '${value}s';
}
