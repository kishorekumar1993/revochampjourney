// lib/bloc/generators/repository_generator.dart
//
// Generates:
//   1. Abstract domain repository interface        ← FIX: imports Result from usecases
//   2. Remote datasource interface + Dio impl      ← FIX: uses DioClient, not http
//   3. Repository implementation                   ← FIX: uses failureMapper + LocalStorage
//   4. Use-case classes (defines Result here)
//
// ROOT CAUSE FIXED:
//   `NewWorkHomeResult` is defined in *_usecases.dart, but the repository
//   interface and impl files referenced it without importing that file.
//   Solution: move the Result class into a dedicated *_result.dart so that
//   both the repository and usecases can import it without a circular dep.

import 'field_schema.dart';

// ---------------------------------------------------------------------------
// Result Model Generator  (new — breaks the circular import)
// ---------------------------------------------------------------------------

class ResultModelGenerator {
  ResultModelGenerator({required this.featureName});

  final String featureName;

  String generate() {
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
    final snakeName      = toSnakeCase(featureName);
    final entityName     = '${featureName}Entity';
    final resultName     = '${featureName}Result';
    final asyncDropdowns = fields.where((f) => f.isAsyncDropdown).toList();
    final buf            = StringBuffer();

    buf.writeln('// AUTO-GENERATED — do not edit');
    buf.writeln("import 'package:dartz/dartz.dart';");
    buf.writeln("import '../../../../core/runtime/async_state.dart';");
    // FIX: import Result from its own file
    buf.writeln("import '../result/${snakeName}_result.dart';");
    buf.writeln("import '../entities/${snakeName}_entity.dart';");
    for (final f in asyncDropdowns) {
      final snake = toSnakeCase(f.entityClassName.replaceAll('Entity', ''));
      buf.writeln("import '../entities/${snake}_entity.dart';");
    }
    buf.writeln();
    buf.writeln('abstract interface class ${featureName}Repository {');

    for (final f in asyncDropdowns) {
      buf.writeln(
        '  Future<Either<Failure, List<${f.entityClassName}>>> '
        'get${toCap(f.fieldName)}List();',
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
    this.submitApiMethod = 'POST',
    this.modelImportPath = '../model',
    this.listDataKey = 'data',          // default key for list extraction
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
    buf.writeln("import '../../../../core/network/api_response.dart';"); // kept for parity
    buf.writeln("import '../../../../core/network/dio_client.dart';");
    buf.writeln("import '../../../../core/network/app_exception.dart';");
    for (final f in asyncDropdowns) {
      final snake = _toSnakeCase(f.entityClassName.replaceAll('Entity', ''));
      buf.writeln("import '$modelImportPath/${snake}_model.dart';");
    }
    buf.writeln();

    buf.writeln('abstract interface class ${featureName}RemoteDataSource {');
    for (final f in asyncDropdowns) {
      buf.writeln(
        '  Future<List<${f.modelClassName}>> '
        'fetch${_toCap(f.fieldName)}List();',
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
    final url = f.dropdownApiUrl;   // must be provided in field schema
    final respKey = f.dropdownKey.isNotEmpty ? f.dropdownKey : listDataKey;

    buf.writeln('  @override');
    buf.writeln(
      '  Future<List<${f.modelClassName}>> '
      'fetch${_toCap(f.fieldName)}List() async {',
    );
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
    buf.writeln('          .map(${f.modelClassName}.fromJson)');
    buf.writeln('          .toList();');
    buf.writeln('      return models;');
    buf.writeln('    } on DioException catch (e) {');
    buf.writeln('      throw ServerException(');
    buf.writeln(
        "        message: e.response?.data?['message'] as String? ?? e.message ?? 'Request failed',");
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
    final submitPath = submitApiUrl ?? '/${_toSnakeCase(featureName)}';
    final method = submitApiMethod.toUpperCase();

    buf.writeln('  @override');
    buf.writeln(
        '  Future<Map<String, dynamic>> submitForm(Map<String, dynamic> payload) async {');
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
    buf.writeln('      throw ServerException(');
    buf.writeln(
        "        message: e.response?.data?['message'] as String? ?? e.message ?? 'Submit failed',");
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

  // ── Helpers ────────────────────────────────────────────────────────────
  static String _toSnakeCase(String input) {
    if (input.isEmpty) return input;
    final buffer = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final char = input[i];
      if (char.toUpperCase() == char && char.toLowerCase() != char) {
        if (i != 0) buffer.write('_');
        buffer.write(char.toLowerCase());
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  static String _toCap(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }
}

// class  DataSourceGenerator {
//   DataSourceGenerator({
//     required this.featureName,
//     required this.fields,
//     this.submitApiUrl = '/submit',
//     this.submitApiMethod = 'POST',
//     this.modelImportPath = '../model',
//   });

//   final String featureName;
//   final List<FieldSchema> fields;
//   final String submitApiUrl;
//   final String submitApiMethod;
//   final String modelImportPath;

//   String generate() {
//     final asyncDropdowns = fields.where((f) => f.isAsyncDropdown).toList();
//     final hasCached = asyncDropdowns.any(
//         (f) => f.cacheKey != null || f.isLocalStorageEnabled);
//     final buf = StringBuffer();

//     buf.writeln('// AUTO-GENERATED');
//     buf.writeln("import 'package:dio/dio.dart';");
//     buf.writeln("import '../../../../core/network/dio_client.dart';");
//     buf.writeln("import '../../../../core/network/app_exception.dart';");
//     if (hasCached) {
//       buf.writeln("import '../../../../core/storage/local_storage_service.dart';");
//     }
//     for (final f in asyncDropdowns) {
//       final snake = _toSnakeCase(f.entityClassName.replaceAll('Entity', ''));
//       buf.writeln("import '$modelImportPath/${snake}_model.dart';");
//     }
//     buf.writeln();

//     buf.writeln('abstract interface class ${featureName}RemoteDataSource {');
//     for (final f in asyncDropdowns) {
//       buf.writeln(
//         '  Future<List<${f.modelClassName}>> '
//         'fetch${_toCap(f.fieldName)}List();',
//       );
//     }
//     buf.writeln('  Future<Map<String, dynamic>> submitForm(Map<String, dynamic> payload);');
//     buf.writeln('}');
//     buf.writeln();

//     buf.writeln('class ${featureName}RemoteDataSourceImpl');
//     buf.writeln('    implements ${featureName}RemoteDataSource {');
//     buf.writeln('  const ${featureName}RemoteDataSourceImpl({');
//     buf.writeln('    required this.client,');
//     if (hasCached) buf.writeln('    this.storage,');
//     buf.writeln('  });');
//     buf.writeln();
//     buf.writeln('  final DioClient client;');
//     if (hasCached) buf.writeln('  final LocalStorageService? storage;');
//     buf.writeln();

//     for (final f in asyncDropdowns) {
//       _writeDropdownFetch(buf, f);
//     }
//     _writeSubmitForm(buf);
//     buf.writeln('}');

//     return buf.toString();
//   }

//   void _writeDropdownFetch(StringBuffer buf, FieldSchema f) {
//     final method = f.dropdownApiMethod.toLowerCase();
//     final url = f.dropdownApiUrl;
//     final bodyStr = f.dropdownApiBody.trim();
//     final hasBody = bodyStr.isNotEmpty &&
//         (method == 'post' || method == 'put' || method == 'patch');
//     final cacheKey = f.cacheKey ??
//         (f.isLocalStorageEnabled
//             ? f.localStorageKey ?? '${_toSnakeCase(f.fieldName)}_cache'
//             : null);
//     final cacheTTL = f.cacheDuration ?? 300;
//     final useCache = cacheKey != null;
//     final respKey = f.dropdownKey;
//     final schHeaders = f.dropdownApiHeaders ?? {};

//     buf.writeln('  @override');
//     buf.writeln(
//       '  Future<List<${f.modelClassName}>> '
//       'fetch${_toCap(f.fieldName)}List() async {',
//     );

//     // Cache read
//     if (useCache) {
//       buf.writeln(
//           "    final cached = storage?.getCachedList('$cacheKey', ttlSeconds: $cacheTTL);");
//       buf.writeln('    if (cached != null) {');
//       buf.writeln('      return cached');
//       buf.writeln('          .whereType<Map<String, dynamic>>()');
//       buf.writeln('          .map(${f.modelClassName}.fromJson)');
//       buf.writeln('          .toList();');
//       buf.writeln('    }');
//       buf.writeln();
//     }

//     // Build data expression
//     String? dataExpr;
//     if (hasBody) {
//       final isJsonObj = bodyStr.startsWith('{') || bodyStr.startsWith('[');
//       dataExpr = isJsonObj ? bodyStr : "'$bodyStr'";
//     }

//     buf.writeln('    try {');
//     buf.writeln('      final response = await client.request<dynamic>(');
//     buf.writeln("        '$url',");
//     buf.writeln("        method: '${method.toUpperCase()}',");
//     if (dataExpr != null) buf.writeln('        data: $dataExpr,');
//     if (schHeaders.isNotEmpty) {
//       buf.writeln('        headers: <String, String>{');
//       for (final e in schHeaders.entries) {
//         buf.writeln("          '${e.key}': '${e.value}',");
//       }
//       buf.writeln('        },');
//     }
//     buf.writeln('      );');
//     buf.writeln();
//     buf.writeln('      final data = response.data;'); // 👈 extract actual data
//     buf.writeln();

//     _writeBodyParsing(buf, respKey, f.modelClassName, cacheKey, useCache);

//     buf.writeln('    } on DioException catch (e) {');
//     buf.writeln('      throw ServerException(');
//     buf.writeln(
//         "        message: e.response?.data?['message'] as String? ?? e.message ?? 'Request failed',");
//     buf.writeln('        statusCode: e.response?.statusCode,');
//     buf.writeln('      );');
//     buf.writeln('    } on AppException {');
//     buf.writeln('      rethrow;');
//     buf.writeln('    } catch (e) {');
//     buf.writeln('      throw ParseException(message: e.toString());');
//     buf.writeln('    }');
//     buf.writeln('  }');
//     buf.writeln();
//   }

//   void _writeBodyParsing(
//     StringBuffer buf,
//     String respKey,
//     String modelClass,
//     String? cacheKey,
//     bool useCache,
//   ) {
//     if (respKey.isNotEmpty) {
//       buf.writeln('      if (data is! Map<String, dynamic>) {');
//       buf.writeln(
//           "        throw const ParseException(message: 'Response is not a JSON object');");
//       buf.writeln('      }');
//       buf.writeln("      final listData = data['$respKey'];");
//       buf.writeln('      if (listData is! List) {');
//       buf.writeln(
//           "        throw ParseException(message: 'Key \"$respKey\" is missing or not a list');");
//       buf.writeln('      }');
//       buf.writeln('      final rawList = listData;');
//     } else {
//       buf.writeln('      final List<dynamic> rawList;');
//       buf.writeln('      if (data is List) {');
//       buf.writeln('        rawList = data;');
//       buf.writeln('      } else if (data is Map<String, dynamic>) {');
//       buf.writeln(
//           '        final lists = data.values.whereType<List<dynamic>>().toList();');
//       buf.writeln('        if (lists.isEmpty) {');
//       buf.writeln(
//           "          throw const ParseException(message: 'No list found in response object');");
//       buf.writeln('        }');
//       buf.writeln('        rawList = lists.first;');
//       buf.writeln('      } else {');
//       buf.writeln(
//           "        throw const ParseException(message: 'Response is not a list or object');");
//       buf.writeln('      }');
//     }

//     buf.writeln('      final models = rawList');
//     buf.writeln('          .whereType<Map<String, dynamic>>()');
//     buf.writeln('          .map($modelClass.fromJson)');
//     buf.writeln('          .toList();');

//     if (useCache && cacheKey != null) {
//       buf.writeln();
//       buf.writeln(
//           "      await storage?.cacheList('$cacheKey', models.map((m) => m.toJson()).toList());");
//     }

//     buf.writeln('      return models;');
//   }

//   void _writeSubmitForm(StringBuffer buf) {
//     buf.writeln('  @override');
//     buf.writeln(
//         '  Future<Map<String, dynamic>> submitForm(Map<String, dynamic> payload) async {');
//     buf.writeln('    try {');
//     buf.writeln('      final response = await client.request<dynamic>(');
//     buf.writeln("        '$submitApiUrl',");
//     buf.writeln("        method: '${submitApiMethod.toUpperCase()}',");
//     buf.writeln('        data: payload,');
//     buf.writeln('      );');
//     buf.writeln('      final data = response.data;'); // 👈 extract actual data
//     buf.writeln('      if (data is! Map<String, dynamic>) {');
//     buf.writeln(
//         "        throw const ParseException(message: 'Submit response is not a JSON object');");
//     buf.writeln('      }');
//     buf.writeln('      return data;'); // 👈 return the map
//     buf.writeln('    } on DioException catch (e) {');
//     buf.writeln('      throw ServerException(');
//     buf.writeln(
//         "        message: e.response?.data?['message'] as String? ?? e.message ?? 'Submit failed',");
//     buf.writeln('        statusCode: e.response?.statusCode,');
//     buf.writeln('      );');
//     buf.writeln('    } on AppException {');
//     buf.writeln('      rethrow;');
//     buf.writeln('    } catch (e) {');
//     buf.writeln('      throw ParseException(message: e.toString());');
//     buf.writeln('    }');
//     buf.writeln('  }');
//     buf.writeln();
//   }

//   // ========== Helper methods ==========
//   static String _toSnakeCase(String input) {
//     if (input.isEmpty) return input;
//     final buffer = StringBuffer();
//     for (int i = 0; i < input.length; i++) {
//       final char = input[i];
//       if (char.toUpperCase() == char && char.toLowerCase() != char) {
//         if (i != 0) buffer.write('_');
//         buffer.write(char.toLowerCase());
//       } else {
//         buffer.write(char);
//       }
//     }
//     return buffer.toString();
//   }

//   static String _toCap(String input) {
//     if (input.isEmpty) return input;
//     return input[0].toUpperCase() + input.substring(1);
//   }
// }

// ---------------------------------------------------------------------------
// Repository Implementation
// ---------------------------------------------------------------------------

class RepositoryImplGenerator {
  RepositoryImplGenerator({
    required this.featureName,
    required this.fields,
  });

  final String featureName;
  final List<FieldSchema> fields;

  String generate() {
    final snakeName      = toSnakeCase(featureName);
    final entityName     = '${featureName}Entity';
    final resultName     = '${featureName}Result';
    final asyncDropdowns = fields.where((f) => f.isAsyncDropdown).toList();
    final buf            = StringBuffer();

    buf.writeln('// AUTO-GENERATED — do not edit');
    buf.writeln("import 'package:dartz/dartz.dart';");
    buf.writeln("import '../../../../core/runtime/async_state.dart';");
    buf.writeln("import '../../../../core/network/failure_mapper.dart';");
    // FIX: import Result from its own dedicated file
    buf.writeln("import '../../domain/result/${snakeName}_result.dart';");
    buf.writeln("import '../../domain/entities/${snakeName}_entity.dart';");
    buf.writeln(
        "import '../../domain/repositories/${snakeName}_repository.dart';");
    buf.writeln(
        "import '../datasources/${snakeName}_datasource.dart';");
    for (final f in asyncDropdowns) {
      final snake = toSnakeCase(f.entityClassName.replaceAll('Entity', ''));
      buf.writeln("import '../../domain/entities/${snake}_entity.dart';");
    }
    buf.writeln();

    buf.writeln(
        'class ${featureName}RepositoryImpl implements ${featureName}Repository {');
    buf.writeln('  const ${featureName}RepositoryImpl(this._dataSource);');
    buf.writeln('  final ${featureName}RemoteDataSource _dataSource;');
    buf.writeln();

    // ── Dropdown list implementations ─────────────────────────────────────
    for (final f in asyncDropdowns) {
      buf.writeln('  @override');
      buf.writeln(
        '  Future<Either<Failure, List<${f.entityClassName}>>> '
        'get${toCap(f.fieldName)}List() async {',
      );
      buf.writeln('    try {');
      buf.writeln(
          '      final models = await _dataSource.fetch${toCap(f.fieldName)}List();');
      buf.writeln(
          '      return right(models.map((m) => m.toEntity()).toList());');
      buf.writeln('    } catch (e) {');
      buf.writeln('      return left(mapExceptionToFailure(e));');
      buf.writeln('    }');
      buf.writeln('  }');
      buf.writeln();
    }

    // ── Submit implementation ─────────────────────────────────────────────
    buf.writeln('  @override');
    buf.writeln(
        '  Future<Either<Failure, $resultName>> submit($entityName entity) async {');
    buf.writeln('    try {');
    buf.writeln(
        '      final res = await _dataSource.submitForm(entity.toJson());');
    buf.writeln('      return right($resultName(');
    buf.writeln("        id:      (res['id'] as num?)?.toInt() ?? 0,");
    buf.writeln("        message: res['message'] as String? ?? 'Submitted successfully',");
    buf.writeln('        data:    res,');
    buf.writeln('      ));');
    buf.writeln('    } catch (e) {');
    buf.writeln('      return left(mapExceptionToFailure(e));');
    buf.writeln('    }');
    buf.writeln('  }');
    buf.writeln('}');

    return buf.toString();
  }
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
    final snakeName      = toSnakeCase(featureName);
    final entityName     = '${featureName}Entity';
    final resultName     = '${featureName}Result';
    final asyncDropdowns = fields.where((f) => f.isAsyncDropdown).toList();
    final buf            = StringBuffer();

    buf.writeln('// AUTO-GENERATED — do not edit');
    buf.writeln("import 'package:dartz/dartz.dart';");
    buf.writeln("import '../../../../core/runtime/async_state.dart';");
    // FIX: Result imported from its own file — no circular dependency
    buf.writeln("import '../result/${snakeName}_result.dart';");
    buf.writeln("import '../entities/${snakeName}_entity.dart';");
    buf.writeln("import '../repositories/${snakeName}_repository.dart';");
    for (final f in asyncDropdowns) {
      final snake = toSnakeCase(f.entityClassName.replaceAll('Entity', ''));
      buf.writeln("import '../entities/${snake}_entity.dart';");
    }
    buf.writeln();

    // ── One strongly-typed load use case per async dropdown ─────────────────
    for (final f in asyncDropdowns) {
      final ucName = 'Load${toCap(f.fieldName)}ListUseCase';
      buf.writeln('/// Fetches the [${f.entityClassName}] list for the'
          ' ${toCap(f.fieldName)} dropdown.');
      buf.writeln('class $ucName {');
      buf.writeln('  const $ucName(this._repository);');
      buf.writeln('  final ${featureName}Repository _repository;');
      buf.writeln();
      buf.writeln(
          '  Future<Either<Failure, List<${f.entityClassName}>>> call() =>');
      buf.writeln('      _repository.get${toCap(f.fieldName)}List();');
      buf.writeln('}');
      buf.writeln();
    }

    // ── Submit use case ─────────────────────────────────────────────────────
    buf.writeln('class Submit${featureName}UseCase {');
    buf.writeln('  const Submit${featureName}UseCase(this._repository);');
    buf.writeln('  final ${featureName}Repository _repository;');
    buf.writeln(
        '  Future<Either<Failure, $resultName>> call($entityName entity) =>');
    buf.writeln('      _repository.submit(entity);');
    buf.writeln('}');

    return buf.toString();
  }
}
