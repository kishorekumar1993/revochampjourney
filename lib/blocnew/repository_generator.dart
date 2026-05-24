// lib/bloc/generators/repository_generator.dart
//
// Generates:
//   1. Abstract domain repository interface
//   2. Remote datasource interface + Dio impl
//   3. Repository implementation
//   4. Use-case classes
//   5. Result model class (breaks circular import)

import 'field_schema.dart';

// ---------------------------------------------------------------------------
// Shared naming utilities (to avoid code duplication)
// ---------------------------------------------------------------------------
class NamingUtils {
  static String toSnakeCase(String input) {
    if (input.isEmpty) return input;
    final buffer = StringBuffer();
    buffer.write(input[0].toLowerCase());
    for (int i = 1; i < input.length; i++) {
      final char = input[i];
      if (char.toUpperCase() == char && char != char.toLowerCase()) {
        buffer.write('_${char.toLowerCase()}');
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  static String toCap(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }

  static String toCamelCase(String input) {
    if (input.isEmpty) return input;
    final parts = input.split('_');
    final buffer = StringBuffer(parts.first);
    for (int i = 1; i < parts.length; i++) {
      buffer.write(toCap(parts[i]));
    }
    return buffer.toString();
  }

  /// Convert entity class name (e.g., "VehicleMakeEntity") to model class name ("VehicleMakeModel")
  static String entityToModelClassName(String entityClassName) {
    if (entityClassName.endsWith('Entity')) {
      return entityClassName.substring(0, entityClassName.length - 6) + 'Model';
    }
    return '${entityClassName}Model';
  }

  /// Convert entity class name to snake_case base name for imports (e.g., "vehicle_make")
  static String entityToImportBase(String entityClassName) {
    final base = entityClassName.replaceAll('Entity', '');
    return toSnakeCase(base);
  }
}

// ---------------------------------------------------------------------------
// Result Model Generator  (new — breaks the circular import)
// ---------------------------------------------------------------------------
class ResultModelGenerator {
  ResultModelGenerator({required this.featureName});

  final String featureName;

  String generate() {
    final snake = NamingUtils.toSnakeCase(featureName);
    final resultName = '${featureName}Result';
    return '''
// AUTO-GENERATED — do not edit
import 'package:equatable/equatable.dart';

/// Value object returned by a successful $featureName submission.
class $resultName extends Equatable {
  const $resultName({required this.id, required this.message, this.data});

  final int    id;
  final String message;
  final Map<String, dynamic>? data;

  @override
  List<Object?> get props => [id, message, data];
}
''';
  }
}

// ---------------------------------------------------------------------------
// Domain Repository Interface
// ---------------------------------------------------------------------------
class DomainRepositoryGenerator {
  DomainRepositoryGenerator({
    required this.featureName,
    required this.fields,
  });

  final String featureName;
  final List<FieldSchema> fields;

  String generate() {
    final snakeName = NamingUtils.toSnakeCase(featureName);
    final entityName = '${featureName}Entity';
    final resultName = '${featureName}Result';
    final asyncDropdowns = fields.where((f) => f.isAsyncDropdown).toList();
    final buf = StringBuffer();

    buf.writeln('// AUTO-GENERATED — do not edit');
    buf.writeln("import 'package:dartz/dartz.dart';");
    buf.writeln("import '../../../../../core/runtime/failure.dart';");
    buf.writeln("import '../result/${snakeName}_result.dart';");
    buf.writeln("import '../entities/${snakeName}_entity.dart';");
    for (final f in asyncDropdowns) {
      final base = NamingUtils.entityToImportBase(f.entityClassName);
      buf.writeln("import '../entities/${base}_entity.dart';");
    }
    buf.writeln();
    buf.writeln('abstract interface class ${featureName}Repository {');

    for (final f in asyncDropdowns) {
      buf.writeln(
        '  Future<Either<Failure, List<${f.entityClassName}>>> '
        'get${NamingUtils.toCap(f.fieldName)}List();',
      );
    }
    buf.writeln(
      '  Future<Either<Failure, $resultName>> submit($entityName entity);',
    );
    buf.writeln('}');

    return buf.toString();
  }
}

// ---------------------------------------------------------------------------
// Remote DataSource  (Dio-based, with local storage cache support)
// ---------------------------------------------------------------------------
class DataSourceGenerator {
  DataSourceGenerator({
    required this.featureName,
    required this.fields,
    this.submitApiUrl,
    this.submitApiMethod = 'post',
    this.modelImportPath = '../model',
    this.listDataKey = 'data',
  });

  final String featureName;
  final List<FieldSchema> fields;
  final String? submitApiUrl;
  final String submitApiMethod;
  final String modelImportPath;
  final String listDataKey;

  String generate() {
    final asyncDropdowns = fields.where((f) => f.isAsyncDropdown).toList();
    final buf = StringBuffer();

    buf.writeln('// AUTO-GENERATED');
    buf.writeln("import 'package:dio/dio.dart';");
    buf.writeln("import '../../../../../core/network/dio_client.dart';");
    buf.writeln("import '../../../../../core/network/api_response.dart';");

    buf.writeln("import '../../../../../core/network/app_exception.dart';");
    for (final f in asyncDropdowns) {
      final modelClass = NamingUtils.entityToModelClassName(f.entityClassName);
      final base = NamingUtils.entityToImportBase(f.entityClassName);
      buf.writeln("import '$modelImportPath/${base}_model.dart';");
    }
    buf.writeln();

    buf.writeln('abstract interface class ${featureName}RemoteDataSource {');
    for (final f in asyncDropdowns) {
      buf.writeln(
        '  Future<List<${NamingUtils.entityToModelClassName(f.entityClassName)}>> '
        'fetch${NamingUtils.toCap(f.fieldName)}List();',
      );
    }
    buf.writeln('  Future<Map<String, dynamic>> submitForm(Map<String, dynamic> payload);');
    buf.writeln('}');
    buf.writeln();

    buf.writeln('class ${featureName}RemoteDataSourceImpl');
    buf.writeln('    implements ${featureName}RemoteDataSource {');
    buf.writeln('  const ${featureName}RemoteDataSourceImpl({');
    buf.writeln('    required this.client,');
    buf.writeln('  });');
    buf.writeln();
    buf.writeln('  final DioClient client;');
    buf.writeln();

    for (final f in asyncDropdowns) {
      _writeFetchMethod(buf, f);
    }
    _writeSubmitForm(buf);
    buf.writeln('}');

    return buf.toString();
  }

  void _writeFetchMethod(StringBuffer buf, FieldSchema f) {
    // Fallback URL: if not provided, use '/${snake_case_feature}/${field_name}s'
    final url = f.dropdownApiUrl;
    final respKey = f.dropdownKey.isNotEmpty ? f.dropdownKey : listDataKey;
    final modelClass = NamingUtils.entityToModelClassName(f.entityClassName);

    buf.writeln('  @override');
    buf.writeln('  Future<List<$modelClass>> fetch${NamingUtils.toCap(f.fieldName)}List() async {');
    buf.writeln('    try {');
    buf.writeln("      final response = await client.get<dynamic>(");
    buf.writeln("        '$url',");
    buf.writeln('      );');
    buf.writeln();
    buf.writeln('      final data = response.data;');
    buf.writeln();
    buf.writeln('      if (data is! Map<String, dynamic>) {');
    buf.writeln(
        "        throw const ParseException(message: 'Response is not a JSON object');");
    buf.writeln('      }');
    buf.writeln("      final listData = data['$respKey'];");
    buf.writeln('      if (listData is! List) {');
    buf.writeln(
        "        throw ParseException(message: 'Key \"$respKey\" is missing or not a list');");
    buf.writeln('      }');
    buf.writeln('      final rawList = listData;');
    buf.writeln('      final models = rawList');
    buf.writeln('          .whereType<Map<String, dynamic>>()');
    buf.writeln('          .map($modelClass.fromJson)');
    buf.writeln('          .toList();');
    buf.writeln('      return models;');
    buf.writeln('    } on DioException catch (e) {');
    buf.writeln('      final data = e.response?.data;');
    buf.writeln('      final msg = data is Map ? data[\'message\'] as String? : null;');
    buf.writeln('      throw ServerException(');
    buf.writeln('        message: msg ?? e.message ?? \'Request failed\',');
    buf.writeln('        statusCode: e.response?.statusCode,');
    buf.writeln('      );');
    buf.writeln('    } on AppException {');
    buf.writeln('      rethrow;');
    buf.writeln('    } catch (e) {');
    buf.writeln('      throw ParseException(message: e.toString());');
    buf.writeln('    }');
    buf.writeln('  }');
    buf.writeln();
  }

  void _writeSubmitForm(StringBuffer buf) {
    final submitPath = submitApiUrl ?? '/${NamingUtils.toSnakeCase(featureName)}';
    final method = submitApiMethod.toLowerCase();

    buf.writeln('  @override');
    buf.writeln('  Future<Map<String, dynamic>> submitForm(Map<String, dynamic> payload) async {');
    buf.writeln('    try {');
    buf.writeln('      final response = await client.$method<dynamic>(');
    buf.writeln("        '$submitPath',");
    buf.writeln('        data: payload,');
    buf.writeln('      );');
    buf.writeln('      final data = response.data;');
    buf.writeln('      if (data is! Map<String, dynamic>) {');
    buf.writeln(
        "        throw const ParseException(message: 'Submit response is not a JSON object');");
    buf.writeln('      }');
    buf.writeln('      return data;');
    buf.writeln('    } on DioException catch (e) {');
    buf.writeln('      final data = e.response?.data;');
    buf.writeln('      final msg = data is Map ? data[\'message\'] as String? : null;');
    buf.writeln('      throw ServerException(');
    buf.writeln('        message: msg ?? e.message ?? \'Submit failed\',');
    buf.writeln('        statusCode: e.response?.statusCode,');
    buf.writeln('      );');
    buf.writeln('    } on AppException {');
    buf.writeln('      rethrow;');
    buf.writeln('    } catch (e) {');
    buf.writeln('      throw ParseException(message: e.toString());');
    buf.writeln('    }');
    buf.writeln('  }');
  }
}

// ---------------------------------------------------------------------------
// Repository Implementation
// ---------------------------------------------------------------------------
// lib/bloc/generators/repository_impl_generator.dart (part of repository_generator.dart)

class RepositoryImplGenerator {
  RepositoryImplGenerator({
    required this.featureName,
    required this.fields,
  });

  final String featureName;
  final List<FieldSchema> fields;

  String generate() {
    final snakeName = _toSnakeCase(featureName);
    final entityName = '${featureName}Entity';
    final resultName = '${featureName}Result';
    final asyncDropdowns = fields.where((f) => f.isAsyncDropdown).toList();
    final buf = StringBuffer();

    buf.writeln('// AUTO-GENERATED — do not edit');
    buf.writeln("import 'package:dartz/dartz.dart';");
    buf.writeln("import '../../../../../core/runtime/failure.dart';");
    buf.writeln("import '../../../../../core/network/failure_mapper.dart';");
    // Correct relative imports from data/repositories/ to domain/ and datasource
    buf.writeln("import '../../domain/result/${snakeName}_result.dart';");
    buf.writeln("import '../../domain/entities/${snakeName}_entity.dart';");
    buf.writeln("import '../../domain/repositories/${snakeName}_repository.dart';");
    buf.writeln("import '../datasources/${snakeName}_datasource.dart';");

    // Import async dropdown entities if any (optional)
    for (final f in asyncDropdowns) {
      final base = _entityToImportBase(f.entityClassName);
      buf.writeln("import '../../domain/entities/${base}_entity.dart';");
    }
    buf.writeln();

    buf.writeln('class ${featureName}RepositoryImpl implements ${featureName}Repository {');
    buf.writeln('  const ${featureName}RepositoryImpl(this._dataSource);');
    buf.writeln('  final ${featureName}RemoteDataSource _dataSource;');
    buf.writeln();

    // Submit method (only method shown in your example)
    buf.writeln('  @override');
    buf.writeln('  Future<Either<Failure, $resultName>> submit($entityName entity) async {');
    buf.writeln('    try {');
    buf.writeln('      final res = await _dataSource.submitForm(entity.toJson());');
    buf.writeln('      return right($resultName(');
    buf.writeln("        id: (res['id'] as num?)?.toInt() ?? 0,");
    buf.writeln("        message: res['message'] as String? ?? 'Submitted successfully',");
    buf.writeln('        data: res,');
    buf.writeln('      ));');
    buf.writeln('    } catch (e) {');
    buf.writeln('      return left(mapExceptionToFailure(e));');
    buf.writeln('    }');
    buf.writeln('  }');
    buf.writeln('}');

    return buf.toString();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  String _entityToImportBase(String entityClassName) {
    final base = entityClassName.replaceAll('Entity', '');
    return _toSnakeCase(base);
  }

  String _toSnakeCase(String input) {
    if (input.isEmpty) return input;
    final buffer = StringBuffer();
    buffer.write(input[0].toLowerCase());
    for (int i = 1; i < input.length; i++) {
      final char = input[i];
      if (char.toUpperCase() == char && char != char.toLowerCase()) {
        buffer.write('_${char.toLowerCase()}');
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  String _toCap(String input) =>
      input.isEmpty ? input : input[0].toUpperCase() + input.substring(1);
}

// ---------------------------------------------------------------------------
// Use Cases
// ---------------------------------------------------------------------------
class UseCaseGenerator {
  UseCaseGenerator({
    required this.featureName,
    required this.fields,
  });

  final String featureName;
  final List<FieldSchema> fields;

  String generate() {
    final snakeName = NamingUtils.toSnakeCase(featureName);
    final entityName = '${featureName}Entity';
    final resultName = '${featureName}Result';
    final asyncDropdowns = fields.where((f) => f.isAsyncDropdown).toList();
    final buf = StringBuffer();

    buf.writeln('// AUTO-GENERATED — do not edit');
    buf.writeln("import 'package:dartz/dartz.dart';");
    buf.writeln("import '../../../../../core/runtime/failure.dart';");
    buf.writeln("import '../result/${snakeName}_result.dart';");
    buf.writeln("import '../entities/${snakeName}_entity.dart';");
    buf.writeln("import '../repositories/${snakeName}_repository.dart';");
    for (final f in asyncDropdowns) {
      final base = NamingUtils.entityToImportBase(f.entityClassName);
      buf.writeln("import '../entities/${base}_entity.dart';");
    }
    buf.writeln();

    buf.writeln('class ${featureName}Usecases {');
    buf.writeln('  const ${featureName}Usecases(this.repository);');
    buf.writeln('  final ${featureName}Repository repository;');
    buf.writeln();

    for (final f in asyncDropdowns) {
      buf.writeln('  Future<Either<Failure, List<${f.entityClassName}>>> load${NamingUtils.toCap(f.fieldName)}List() =>');
      buf.writeln('      repository.get${NamingUtils.toCap(f.fieldName)}List();');
      buf.writeln();
    }

    buf.writeln('  Future<Either<Failure, $resultName>> execute($entityName payload) =>');
    buf.writeln('      repository.submit(payload);');
    buf.writeln('}');

    return buf.toString();
  }
}