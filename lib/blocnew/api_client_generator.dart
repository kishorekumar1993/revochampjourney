// lib/bloc/generators/api_client_generator.dart
//
// Generates a reusable Dio-based API client with:
//   • Interceptors for auth, logging, error normalisation
//   • AppException hierarchy mapping HTTP → domain errors
//   • ApiResponse<T> wrapper
//   • LocalStorage service using shared_preferences

abstract final class ApiClientSources {
  // ─────────────────────────────────────────────────────────────────────────
  // app_exception.dart
  // ─────────────────────────────────────────────────────────────────────────
  static const String appException = r"""
// lib/bloc/core/network/app_exception.dart

/// Base exception for all app-level errors.
sealed class AppException implements Exception {
  const AppException({required this.message, this.statusCode});
  final String message;
  final int?   statusCode;

  @override
  String toString() => '$runtimeType($statusCode): $message';
}

/// The server responded with 4xx / 5xx.
final class ServerException extends AppException {
  const ServerException({required super.message, super.statusCode, this.errors});
  final Map<String, dynamic>? errors;
}

/// The device has no internet connectivity.
final class NetworkException extends AppException {
  const NetworkException({super.message = 'No internet connection.'});
}

/// Request timed out.
final class TimeoutException extends AppException {
  const TimeoutException({super.message = 'Request timed out.'});
}

/// Response could not be parsed.
final class ParseException extends AppException {
  const ParseException({required super.message});
}

/// Catch-all.
final class UnknownException extends AppException {
  const UnknownException({required super.message});
}
""";

  // ─────────────────────────────────────────────────────────────────────────
  // api_response.dart
  // ─────────────────────────────────────────────────────────────────────────
  static const String apiResponse = r"""
// lib/bloc/core/network/api_response.dart

/// Typed wrapper returned by every API call.
sealed class ApiResponse<T> {
  const ApiResponse();
}

final class ApiSuccess<T> extends ApiResponse<T> {
  const ApiSuccess(this.data, {this.statusCode = 200});
  final T   data;
  final int statusCode;
}

final class ApiFailure<T> extends ApiResponse<T> {
  const ApiFailure(this.exception);
  final Object exception;
}

extension ApiResponseX<T> on ApiResponse<T> {
  bool get isSuccess => this is ApiSuccess<T>;
  bool get isFailure => this is ApiFailure<T>;

  T get data       => (this as ApiSuccess<T>).data;
  Object get error => (this as ApiFailure<T>).exception;

  R fold<R>({
    required R Function(T data, int statusCode) onSuccess,
    required R Function(Object error)           onFailure,
  }) {
    if (this is ApiSuccess<T>) {
      final s = this as ApiSuccess<T>;
      return onSuccess(s.data, s.statusCode);
    }
    return onFailure((this as ApiFailure<T>).exception);
  }
}
""";

  // ─────────────────────────────────────────────────────────────────────────
  // dio_client.dart
  // ─────────────────────────────────────────────────────────────────────────
  static const String dioClient = r"""
// lib/bloc/core/network/dio_client.dart
import 'package:dio/dio.dart';
import 'app_exception.dart';
import 'api_response.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/error_interceptor.dart';

class DioClient {
  DioClient({
    required String baseUrl,
    Duration connectTimeout    = const Duration(seconds: 15),
    Duration receiveTimeout    = const Duration(seconds: 30),
    Map<String, dynamic>? defaultHeaders,
    List<Interceptor> extraInterceptors = const [],
  }) : _dio = _buildDio(
          baseUrl:        baseUrl,
          connectTimeout: connectTimeout,
          receiveTimeout: receiveTimeout,
          defaultHeaders: defaultHeaders,
          extraInterceptors: extraInterceptors,
        );

  final Dio _dio;

  static Dio _buildDio({
    required String baseUrl,
    required Duration connectTimeout,
    required Duration receiveTimeout,
    Map<String, dynamic>? defaultHeaders,
    required List<Interceptor> extraInterceptors,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl:        baseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept':        'application/json',
          ...?defaultHeaders,
        },
      ),
    );
    dio.interceptors.addAll([
      AuthInterceptor(),
      ErrorInterceptor(),
      LoggingInterceptor(),
      ...extraInterceptors,
    ]);
    return dio;
  }

  // ── Public HTTP helpers ──────────────────────────────────────────────────

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    T Function(dynamic)? fromJson,
  }) => _request(
        method:          'GET',
        path:            path,
        queryParameters: queryParameters,
        headers:         headers,
        fromJson:         fromJson,
      );

  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    T Function(dynamic)? fromJson,
  }) => _request(
        method:          'POST',
        path:            path,
        data:            data,
        queryParameters: queryParameters,
        headers:         headers,
        fromJson:         fromJson,
      );

  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    T Function(dynamic)? fromJson,
  }) => _request(
        method:          'PUT',
        path:            path,
        data:            data,
        queryParameters: queryParameters,
        headers:         headers,
        fromJson:         fromJson,
      );

  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    T Function(dynamic)? fromJson,
  }) => _request(
        method:          'PATCH',
        path:            path,
        data:            data,
        queryParameters: queryParameters,
        headers:         headers,
        fromJson:         fromJson,
      );

  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    T Function(dynamic)? fromJson,
  }) => _request(
        method:          'DELETE',
        path:            path,
        data:            data,
        queryParameters: queryParameters,
        headers:         headers,
        fromJson:         fromJson,
      );

  // ── Core request ─────────────────────────────────────────────────────────

  Future<ApiResponse<T>> _request<T>({
    required String method,
    required String path,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.request<dynamic>(
        path,
        data:            data,
        queryParameters: queryParameters,
        options:         Options(method: method, headers: headers),
      );
      final body = response.data;
      if (fromJson != null) {
        return ApiSuccess(fromJson(body), statusCode: response.statusCode ?? 200);
      }
      return ApiSuccess(body as T, statusCode: response.statusCode ?? 200);
    } on DioException catch (e) {
      throw _mapDioException(e);
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  // ── DioException → AppException mapping ──────────────────────────────────

  AppException _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException();
      case DioExceptionType.connectionError:
        return const NetworkException();
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final body       = e.response?.data;
        String message   = 'Server error';
        Map<String, dynamic>? errors;
        if (body is Map<String, dynamic>) {
          message = body['message'] as String? ??
                    body['error']   as String? ??
                    message;
          errors  = body['errors'] as Map<String, dynamic>?;
        }
        return ServerException(
          message:    message,
          statusCode: statusCode,
          errors:     errors,
        );
      default:
        return UnknownException(message: e.message ?? 'Unknown error');
    }
  }
}
""";

  // ─────────────────────────────────────────────────────────────────────────
  // auth_interceptor.dart
  // ─────────────────────────────────────────────────────────────────────────
  static const String authInterceptor = r"""
// lib/bloc/core/network/interceptors/auth_interceptor.dart
import 'package:dio/dio.dart';

/// Attaches the bearer token (or any auth header) to every request.
/// Swap the token source (e.g. SharedPreferences, secure storage) as needed.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({this.getToken});

  final Future<String?> Function()? getToken;

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await getToken?.call();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
""";

  // ─────────────────────────────────────────────────────────────────────────
  // logging_interceptor.dart
  // ─────────────────────────────────────────────────────────────────────────
  static const String loggingInterceptor = r"""
// lib/bloc/core/network/interceptors/logging_interceptor.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Logs requests and responses in debug mode only.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('[API ▶] ${options.method} ${options.uri}');
      if (options.data != null) debugPrint('  body: ${options.data}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('[API ◀] ${response.statusCode} ${response.requestOptions.uri}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('[API ✗] ${err.type} ${err.requestOptions.uri}');
      if (err.response != null) {
        debugPrint('  status: ${err.response?.statusCode}');
        debugPrint('  body:   ${err.response?.data}');
      }
    }
    handler.next(err);
  }
}
""";

  // ─────────────────────────────────────────────────────────────────────────
  // error_interceptor.dart
  // ─────────────────────────────────────────────────────────────────────────
  static const String errorInterceptor = r"""
// lib/bloc/core/network/interceptors/error_interceptor.dart
import 'package:dio/dio.dart';

/// Intercepts 401 responses and can trigger token refresh / logout.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // TODO: trigger token refresh or redirect to login.
    }
    handler.next(err);
  }
}
""";

  // ─────────────────────────────────────────────────────────────────────────
  // local_storage_service.dart
  // ─────────────────────────────────────────────────────────────────────────
  static const String localStorageService = r"""
// lib/bloc/core/storage/local_storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Thin, typed wrapper around SharedPreferences.
/// Used by data sources that need to cache dropdown lists or form drafts.
class LocalStorageService {
  LocalStorageService(this._prefs);

  final SharedPreferences _prefs;

  // ── Primitives ─────────────────────────────────────────────────────────

  Future<bool> setString(String key, String value)    => _prefs.setString(key, value);
  Future<bool> setBool  (String key, bool value)      => _prefs.setBool(key, value);
  Future<bool> setInt   (String key, int value)       => _prefs.setInt(key, value);
  Future<bool> setDouble(String key, double value)    => _prefs.setDouble(key, value);

  String?  getString(String key) => _prefs.getString(key);
  bool?    getBool  (String key) => _prefs.getBool(key);
  int?     getInt   (String key) => _prefs.getInt(key);
  double?  getDouble(String key) => _prefs.getDouble(key);

  // ── JSON helpers ────────────────────────────────────────────────────────

  Future<bool> setJson(String key, Map<String, dynamic> value) =>
      _prefs.setString(key, jsonEncode(value));

  Map<String, dynamic>? getJson(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try { return jsonDecode(raw) as Map<String, dynamic>; }
    catch (_) { return null; }
  }

  Future<bool> setJsonList(String key, List<Map<String, dynamic>> list) =>
      _prefs.setString(key, jsonEncode(list));

  List<Map<String, dynamic>>? getJsonList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } catch (_) { return null; }
  }

  // ── Cache helpers ────────────────────────────────────────────────────────

  /// Stores [list] and records the timestamp for TTL checks.
  Future<void> cacheList(
      String cacheKey, List<Map<String, dynamic>> list) async {
    await setJsonList(cacheKey, list);
    await setInt('${cacheKey}_ts', DateTime.now().millisecondsSinceEpoch);
  }

  /// Returns the cached list only if it was stored within [ttlSeconds].
  List<Map<String, dynamic>>? getCachedList(
      String cacheKey, {int ttlSeconds = 300}) {
    final ts = getInt('${cacheKey}_ts');
    if (ts == null) return null;
    final age = DateTime.now().millisecondsSinceEpoch - ts;
    if (age > ttlSeconds * 1000) return null; // expired
    return getJsonList(cacheKey);
  }

  // ── Housekeeping ─────────────────────────────────────────────────────────

  Future<bool> remove(String key) => _prefs.remove(key);
  Future<bool> clear()            => _prefs.clear();
  bool containsKey(String key)    => _prefs.containsKey(key);
}
""";

  // ─────────────────────────────────────────────────────────────────────────
  // failure_mapper.dart
  // ─────────────────────────────────────────────────────────────────────────
  static const String failureMapper = r"""
// lib/bloc/core/network/failure_mapper.dart
import '../runtime/failure.dart';
import 'app_exception.dart';

/// Maps any thrown exception → domain [Failure].
Failure mapExceptionToFailure(Object e) {
  if (e is ServerException) {
    return Failure(
      message:    e.message,
      code:       'server_${e.statusCode ?? 0}',
      statusCode: e.statusCode,
      retryable:  (e.statusCode ?? 0) >= 500,
    );
  }
  if (e is NetworkException) {
    return Failure(
      message:   e.message,
      code:      'network_error',
      retryable: true,
    );
  }
  if (e is TimeoutException) {
    return Failure(
      message:   e.message,
      code:      'timeout',
      retryable: true,
    );
  }
  if (e is ParseException) {
    return Failure(message: e.message, code: 'parse_error');
  }
  return Failure(message: e.toString(), code: 'unknown');
}
""";
}