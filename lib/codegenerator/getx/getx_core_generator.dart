// lib/codegenerator/getx/getx_core_generator.dart
// Improved GetX core file generator – enterprise grade


/// Generate all global GetX core files.
/// Call this once per project (e.g., in your main generation script).
List<Map<String, String>> generateGetxCoreFiles({
  required String projectName,
  required String baseUrl,
  required String environmentName, // 'dev', 'staging', or 'prod'
  bool generateResultClass = true,
  bool generateBaseController = true,
}) {
  final result = <Map<String, String>>[];
  const outputBase = 'lib/getx';

  // Core utilities
  result.add(_makeFile(outputBase, 'app_config.dart', _appConfigTemplate(baseUrl, environmentName)));
  result.add(_makeFile(outputBase, 'logger.dart', _loggerTemplate()));
  result.add(_makeFile(outputBase, 'result.dart', _resultTemplate()));
  result.add(_makeFile(outputBase, 'validation_engine.dart', _validationEngineTemplate()));
  result.add(_makeFile(outputBase, 'api_executor.dart', _apiExecutorTemplate()));
  result.add(_makeFile(outputBase, 'worker_manager.dart', _workerManagerTemplate()));
  result.add(_makeFile(outputBase, 'message_service.dart', _messageServiceTemplate()));
  result.add(_makeFile(outputBase, 'getx_exports.dart', getxexport()));
  if (generateBaseController) {
    result.add(_makeFile(outputBase, 'base_controller.dart', _baseControllerTemplate()));
  }

  return result;
}

Map<String, String> _makeFile(String folder, String fileName, String content) =>
    {'folderPath': folder, 'fileName': fileName, 'textContent': content};

// ==================== Templates ====================

String _appConfigTemplate(String baseUrl, String environmentName) => '''
import 'package:get/get.dart';

enum Environment { dev, staging, prod }

class AppConfig extends GetxService {
  static AppConfig get to => Get.find();
  late final Environment environment;
  late final String baseUrl;

  AppConfig({required this.environment, required this.baseUrl});

  factory AppConfig.fromEnvironment() {
    const env = String.fromEnvironment('ENV', defaultValue: '$environmentName');
    final environment = env == 'prod' ? Environment.prod : (env == 'staging' ? Environment.staging : Environment.dev);
    final url = _urlForEnvironment(environment);
    return AppConfig(environment: environment, baseUrl: url);
  }

  static String _urlForEnvironment(Environment env) {
    switch (env) {
      case Environment.dev:
        return '$baseUrl';
      case Environment.staging:
        return 'https://staging-api.yourdomain.com';
      case Environment.prod:
        return 'https://api.yourdomain.com';
    }
  }

  bool get isDev => environment == Environment.dev;
  bool get isStaging => environment == Environment.staging;
  bool get isProd => environment == Environment.prod;
}
''';

String _loggerTemplate() => '''
import 'package:flutter/foundation.dart';

class AppLogger {
  static void debug(String message) {
    if (kDebugMode) print('[DEBUG] \$message');
  }

  static void info(String message) {
    print('[INFO] \$message');
  }

  static void warning(String message) {
    print('[WARNING] \$message');
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    print('[ERROR] \$message');
    if (error != null) print('  Error: \$error');
    if (stackTrace != null) print('  StackTrace: \$stackTrace');
  }
}
''';

String _resultTemplate() => '''
/// Sealed result type for async operations (replaces AsyncValue).
sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

final class Failure<T> extends Result<T> {
  final Object error;
  final StackTrace? stackTrace;
  const Failure(this.error, [this.stackTrace]);
}
''';

String _validationEngineTemplate() => '''
typedef Validator = String? Function(String? value);

class ValidationEngine {
  static final ValidationEngine _instance = ValidationEngine._internal();
  factory ValidationEngine() => _instance;
  ValidationEngine._internal();

  final Map<String, Validator> _validators = {};

  void register(String key, Validator validator) {
    _validators[key] = validator;
  }

  Validator? get(String key) => _validators[key];

  String? validate(String? value, List<Validator> validators) {
    for (final validator in validators) {
      final error = validator(value);
      if (error != null) return error;
    }
    return null;
  }

  // Built‑in validators
  static Validator required([String fieldName = 'This field']) =>
      (value) => (value == null || value.trim().isEmpty) ? '\$fieldName is required' : null;

  static Validator email() => (value) {
        if (value == null || value.isEmpty) return null;
        final regex = RegExp(r'^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}\$');
        return regex.hasMatch(value) ? null : 'Enter a valid email';
      };

  static Validator minLength(int length, [String fieldName = 'This field']) =>
      (value) => (value != null && value.length < length) ? '\$fieldName must be at least \$length characters' : null;

  static Validator maxLength(int length, [String fieldName = 'This field']) =>
      (value) => (value != null && value.length > length) ? '\$fieldName must not exceed \$length characters' : null;
}
''';

String _apiExecutorTemplate() => '''
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'app_config.dart';
import 'logger.dart';
import 'result.dart';

class ApiExecutor extends GetxService {
  static ApiExecutor get to => Get.find();
  late final Dio _dio;
  final CancelToken _cancelToken = CancelToken();

  @override
  void onInit() {
    super.onInit();
    final config = Get.find<AppConfig>();
    _dio = Dio(BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));
    _addInterceptors();
  }

  void _addInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = _getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer \$token';
        }
        AppLogger.debug('Request: \${options.method} \${options.uri}');
        return handler.next(options);
      },
      onError: (error, handler) async {
        AppLogger.error('API Error', error);
        if (error.response?.statusCode == 401) {
          // Handle token refresh
        }
        return handler.next(error);
      },
    ));
    _dio.interceptors.add(RetryInterceptor(_dio));
  }

  String? _getToken() => null; // Replace with secure storage

  Future<Result<T>> execute<T>(Future<T> Function() request) async {
    try {
      final data = await request();
      return Success<T>(data);
    } on DioException catch (e) {
      final message = _handleError(e);
      return Failure<T>(message);
    } catch (e) {
      AppLogger.error('Unexpected error', e);
      return Failure<T>(e.toString());
    }
  }

  Future<Result<Response>> get(String path, {Map<String, dynamic>? query}) =>
      execute(() => _dio.get(path, queryParameters: query));

  Future<Result<Response>> post(String path, {dynamic data}) =>
      execute(() => _dio.post(path, data: data));

  Future<Result<Response>> put(String path, {dynamic data}) =>
      execute(() => _dio.put(path, data: data));

  Future<Result<Response>> patch(String path, {dynamic data}) =>
      execute(() => _dio.patch(path, data: data));

  Future<Result<Response>> delete(String path, {dynamic data}) =>
      execute(() => _dio.delete(path, data: data));

  String _handleError(DioException error) {
    if (error.response != null) {
      final data = error.response!.data;
      if (data is Map && data.containsKey('message')) return data['message'];
      return 'Server error: \${error.response!.statusCode}';
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout';
      case DioExceptionType.receiveTimeout:
        return 'Receive timeout';
      case DioExceptionType.connectionError:
        return 'No internet connection';
      default:
        return 'Unexpected error: \${error.message}';
    }
  }

  void cancelRequests() => _cancelToken.cancel('Request cancelled');
  @override
  void onClose() => cancelRequests();
}

class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  RetryInterceptor(this.dio, [this.maxRetries = 3]);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_shouldRetry(err)) {
      int retryCount = err.requestOptions.extra['retryCount'] ?? 0;
      if (retryCount < maxRetries) {
        retryCount++;
        err.requestOptions.extra['retryCount'] = retryCount;
        await Future.delayed(const Duration(seconds: 1));
        try {
          final response = await dio.request(
            err.requestOptions.path,
            options: Options(
              method: err.requestOptions.method,
              headers: err.requestOptions.headers,
              extra: err.requestOptions.extra,
            ),
            data: err.requestOptions.data,
            queryParameters: err.requestOptions.queryParameters,
          );
          return handler.resolve(response);
        } catch (e) {
          return handler.next(err);
        }
      }
    }
    return handler.next(err);
  }

  bool _shouldRetry(DioException err) =>
      err.type == DioExceptionType.connectionTimeout ||
      err.type == DioExceptionType.receiveTimeout ||
      err.type == DioExceptionType.connectionError;
}
''';

String _workerManagerTemplate() => '''
import 'package:get/get.dart';

/// Wrapper around GetX workers with automatic disposal.
class WorkerManager extends GetxService {
  final List<Worker> _workers = [];

  /// Registers a [debounce] worker.
  Worker registerDebounce<T>(
    RxInterface<T> observable,
    WorkerCallback<T> callback, {
    required Duration time,
  }) {
    final worker = debounce(observable, callback, time: time);
    _workers.add(worker);
    return worker;
  }

  /// Registers an [interval] worker.
  Worker registerInterval<T>(
    RxInterface<T> observable,
    WorkerCallback<T> callback, {
    required Duration time,
  }) {
    final worker = interval(observable, callback, time: time);
    _workers.add(worker);
    return worker;
  }

  /// Registers an [ever] worker.
  Worker registerEver<T>(
    RxInterface<T> observable,
    WorkerCallback<T> callback,
  ) {
    final worker = ever(observable, callback);
    _workers.add(worker);
    return worker;
  }

  /// Registers a [once] worker.
  Worker registerOnce<T>(
    RxInterface<T> observable,
    WorkerCallback<T> callback,
  ) {
    final worker = once(observable, callback);
    _workers.add(worker);
    return worker;
  }

  /// Manually disposes all workers and closes the service.
  void dispose() {
    onClose();
  }

  @override
  void onClose() {
    // Use toList() to avoid modification during iteration
    for (final worker in _workers.toList()) {
      try {
        worker.dispose();
      } catch (e) {
        // Log error if needed, but continue cleanup
      }
    }
    _workers.clear();
    super.onClose();
  }
}
''';

String _messageServiceTemplate() => '''
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'logger.dart';

enum MessageType { success, error, warning, info }

class MessageEvent {
  final String message;
  final MessageType type;
  final DateTime timestamp;
  MessageEvent(this.message, {this.type = MessageType.info, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();
}

class MessageService extends GetxService {
  static MessageService get to => Get.find();
  final _queue = <MessageEvent>[];
  bool _isShowing = false;
  final _controller = StreamController<MessageEvent>.broadcast();
  Stream<MessageEvent> get messageStream => _controller.stream;

  void showSuccess(String msg) => _enqueue(msg, MessageType.success);
  void showError(String msg) => _enqueue(msg, MessageType.error);
  void showWarning(String msg) => _enqueue(msg, MessageType.warning);
  void showInfo(String msg) => _enqueue(msg, MessageType.info);

  void _enqueue(String msg, MessageType type) {
    final event = MessageEvent(msg, type: type);
    _queue.add(event);
    _controller.add(event);
    _processQueue();
  }

  void _processQueue() async {
    if (_isShowing || _queue.isEmpty) return;
    _isShowing = true;
    final event = _queue.removeAt(0);
    await _showSnackbar(event);
    _isShowing = false;
    _processQueue();
  }

  Future<void> _showSnackbar(MessageEvent event) async {
    if (Get.context == null) return;
    if (Get.isSnackbarOpen) Get.back();
    Get.snackbar(
      event.type.toString().split('.').last.toUpperCase(),
      event.message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: _colorForType(event.type),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(10),
      borderRadius: 8,
    );
  }

  Color _colorForType(MessageType type) {
    switch (type) {
      case MessageType.success:
        return Colors.green;
      case MessageType.error:
        return Colors.red;
      case MessageType.warning:
        return Colors.orange;
      case MessageType.info:
        return Colors.blue;
    }
  }

  @override
  void onClose() {
    _controller.close();
    super.onClose();
  }
}
''';

String getxexport() => '''
export 'app_config.dart';
export 'logger.dart';
export 'message_service.dart';
export 'result.dart';
export 'validation_engine.dart';
export 'api_executor.dart';
export 'worker_manager.dart';''';
  
  
  String _baseControllerTemplate() => '''
import 'package:get/get.dart';
import 'message_service.dart';
import 'logger.dart';
import 'result.dart';

abstract class BaseController extends GetxController {
  final isLoading = false.obs;
  final errorMessage = RxnString();

  void setLoading(bool value) => isLoading.value = value;

  void setError(String? value) => errorMessage.value = value;

  void showSuccess(String message) => MessageService.to.showSuccess(message);
  void showError(String message) => MessageService.to.showError(message);
  void showWarning(String message) => MessageService.to.showWarning(message);
  void showInfo(String message) => MessageService.to.showInfo(message);

  void logDebug(String message) => AppLogger.debug(message);
  void logInfo(String message) => AppLogger.info(message);
  void logError(String message, [Object? error, StackTrace? stack]) =>
      AppLogger.error(message, error, stack);

  Future<void> runAsync(Future<void> Function() task, {String? loadingMessage}) async {
    if (isLoading.value) return;
    setLoading(true);
    setError(null);
    try {
      await task();
    } catch (e, st) {
      logError('Async error', e, st);
      setError(e.toString());
      showError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  void handleResult<T>(Result<T> result, {
    required void Function(T data) onSuccess,
    void Function(Object error)? onError,
  }) {
    switch (result) {
      case Success<T>():
        onSuccess(result.data);
      case Failure<T>():
        final errorMsg = result.error.toString();
        setError(errorMsg);
        showError(errorMsg);
        onError?.call(result.error);
    }
  }
}
''';