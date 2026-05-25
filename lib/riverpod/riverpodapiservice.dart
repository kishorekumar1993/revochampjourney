String generateApiServiceInterface() {
  final buffer = StringBuffer();

  buffer.writeln('''
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

/// ─── Failure sealed classes ───────────────────────────────────────
sealed class ApiFailure {
  final String message;
  final int? statusCode;
  final dynamic data;

  const ApiFailure({required this.message, this.statusCode, this.data});

  @override
  String toString() => '\${runtimeType}: \$message (\${statusCode ?? 'No Status'})';
}

class NetworkFailure extends ApiFailure {
  const NetworkFailure({required super.message});
}

class TimeoutFailure extends ApiFailure {
  const TimeoutFailure() : super(message: 'Request timed out');
}

class ServerFailure extends ApiFailure {
  const ServerFailure({
    required super.message,
    required super.statusCode,
    super.data,
  });
}

class UnexpectedFailure extends ApiFailure {
  const UnexpectedFailure({required super.message});
}

/// ─── Token provider interface ─────────────────────────────────────
/// Implement this to provide auth tokens from secure storage.
/// ✅ FIX 3: no hardcoded token
abstract class TokenProvider {
  Future<String?> getAccessToken();
}

/// ─── API Service ──────────────────────────────────────────────────
class ApiService {
  final String baseUrl;
  final http.Client client;
  final Duration timeout;
  final TokenProvider? tokenProvider;

  /// ✅ FIX 5: removed path package — use dart:io directly
  /// ✅ FIX 3: tokenProvider replaces hardcoded Bearer token
  ApiService({
    required this.baseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 30),
    this.tokenProvider,
  }) : client = client ?? http.Client();

  // ═══════════════════════════════════════════════
  // PUBLIC METHODS
  // ═══════════════════════════════════════════════

  /// GET request
  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
    int retries = 1,
  }) async {
    return _makeRequest(
      method: 'GET',
      endpoint: endpoint,
      headers: headers,
      queryParameters: queryParameters,
      requiresAuth: requiresAuth,
      retries: retries,
    );
  }

  /// POST request
  Future<dynamic> post(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
    int retries = 0,
  }) async {
    return _makeRequest(
      method: 'POST',
      endpoint: endpoint,
      headers: headers,
      body: body,
      queryParameters: queryParameters,
      requiresAuth: requiresAuth,
      retries: retries,
    );
  }

  /// ✅ FIX 1: PUT request added
  Future<dynamic> put(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
    int retries = 0,
  }) async {
    return _makeRequest(
      method: 'PUT',
      endpoint: endpoint,
      headers: headers,
      body: body,
      queryParameters: queryParameters,
      requiresAuth: requiresAuth,
      retries: retries,
    );
  }

  /// ✅ FIX 2: PATCH request added
  Future<dynamic> patch(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
    int retries = 0,
  }) async {
    return _makeRequest(
      method: 'PATCH',
      endpoint: endpoint,
      headers: headers,
      body: body,
      queryParameters: queryParameters,
      requiresAuth: requiresAuth,
      retries: retries,
    );
  }

  /// ✅ FIX 1: DELETE request added
  Future<dynamic> delete(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
    int retries = 0,
  }) async {
    return _makeRequest(
      method: 'DELETE',
      endpoint: endpoint,
      headers: headers,
      body: body,
      queryParameters: queryParameters,
      requiresAuth: requiresAuth,
      retries: retries,
    );
  }

  /// File upload (Multipart)
  /// ✅ FIX 5: use file.path.split('/').last instead of basename from path pkg
  Future<dynamic> upload(
    String endpoint, {
    required File file,
    String fieldName = 'file',
    Map<String, String>? headers,
    Map<String, String>? fields,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    await _checkInternetConnection();
    final uri = _buildUri(endpoint, queryParameters);
    final request = http.MultipartRequest('POST', uri);

    final fileStream = http.ByteStream(file.openRead());
    final fileLength = await file.length();

    // ✅ FIX 5: dart:io only — no path package needed
    final fileName = file.path.split(Platform.pathSeparator).last;

    request.files.add(
      http.MultipartFile(
        fieldName,
        fileStream,
        fileLength,
        filename: fileName,
      ),
    );

    if (fields != null) {
      request.fields.addAll(fields);
    }

    final builtHeaders = await _buildHeaders(headers, requiresAuth);
    request.headers.addAll(builtHeaders);

    // ✅ FIX 7: debug logging
    _log('UPLOAD', uri, null);

    try {
      final streamedResponse = await request.send().timeout(timeout);
      return _handleStreamedResponse(streamedResponse);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ═══════════════════════════════════════════════
  // PRIVATE METHODS
  // ═══════════════════════════════════════════════

  /// ✅ FIX 6: retry logic for transient failures (GET only by default)
  Future<dynamic> _makeRequest({
    required String method,
    required String endpoint,
    Map<String, String>? headers,
    dynamic body,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
    int retries = 0,
  }) async {
    await _checkInternetConnection();

    int attempt = 0;
    while (true) {
      try {
        return await _executeRequest(
          method: method,
          endpoint: endpoint,
          headers: headers,
          body: body,
          queryParameters: queryParameters,
          requiresAuth: requiresAuth,
        );
      } catch (e) {
        if (attempt >= retries) rethrow;
        attempt++;
        // ✅ Exponential backoff between retries
        await Future.delayed(Duration(milliseconds: 300 * attempt));
      }
    }
  }

  Future<dynamic> _executeRequest({
    required String method,
    required String endpoint,
    Map<String, String>? headers,
    dynamic body,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    final uri = _buildUri(endpoint, queryParameters);
    // ✅ FIX 3: await token from provider
    final requestHeaders = await _buildHeaders(headers, requiresAuth);
    final encodedBody = body != null ? jsonEncode(body) : null;

    // ✅ FIX 7: request logging
    _log(method, uri, body);

    try {
      late final http.Response response;

      switch (method) {
        case 'GET':
          response = await client
              .get(uri, headers: requestHeaders)
              .timeout(timeout);
          break;
        case 'POST':
          response = await client
              .post(uri, headers: requestHeaders, body: encodedBody)
              .timeout(timeout);
          break;
        case 'PUT':
          response = await client
              .put(uri, headers: requestHeaders, body: encodedBody)
              .timeout(timeout);
          break;
        case 'PATCH':
          response = await client
              .patch(uri, headers: requestHeaders, body: encodedBody)
              .timeout(timeout);
          break;
        case 'DELETE':
          response = await client
              .delete(uri, headers: requestHeaders, body: encodedBody)
              .timeout(timeout);
          break;
        default:
          throw UnexpectedFailure(
              message: 'Unsupported HTTP method: \$method');
      }

      // ✅ FIX 7: response logging
      _logResponse(response.statusCode, response.body);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Uri _buildUri(
      String endpoint, Map<String, dynamic>? queryParameters) {
    final uri = Uri.parse(baseUrl).resolve(endpoint);
    return queryParameters != null
        ? uri.replace(
            queryParameters: queryParameters
                .map((k, v) => MapEntry(k, v.toString())))
        : uri;
  }

  /// ✅ FIX 3: async token from TokenProvider — no hardcoded value
  Future<Map<String, String>> _buildHeaders(
    Map<String, String>? additional,
    bool requiresAuth,
  ) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?additional,
    };
    if (requiresAuth && tokenProvider != null) {
      final token = await tokenProvider!.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer \$token';
      }
    }
    return headers;
  }

  /// ✅ FIX 8: guard against non-JSON responses
  dynamic _handleResponse(http.Response response) {
    dynamic jsonBody;
    try {
      jsonBody = jsonDecode(response.body);
    } catch (_) {
      // Non-JSON response body — return raw string
      jsonBody = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonBody;
    }

    final message = jsonBody is Map
        ? (jsonBody['message'] ?? jsonBody['error'] ?? 'Request failed')
            .toString()
        : 'Request failed';

    throw ServerFailure(
      message: message,
      statusCode: response.statusCode,
      data: jsonBody,
    );
  }

  /// ✅ FIX 8: guard against non-JSON streamed responses
  Future<dynamic> _handleStreamedResponse(
      http.StreamedResponse response) async {
    final str = await response.stream.bytesToString();
    dynamic jsonBody;
    try {
      jsonBody = jsonDecode(str);
    } catch (_) {
      jsonBody = str;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonBody;
    }

    final message = jsonBody is Map
        ? (jsonBody['message'] ?? jsonBody['error'] ?? 'Request failed')
            .toString()
        : 'Request failed';

    throw ServerFailure(
      message: message,
      statusCode: response.statusCode,
      data: jsonBody,
    );
  }

  /// ✅ FIX 4: connectivity_plus v5+ returns List<ConnectivityResult>
  Future<void> _checkInternetConnection() async {
    final results = await Connectivity().checkConnectivity();
    final hasConnection = results.any(
      (r) => r != ConnectivityResult.none,
    );
    if (!hasConnection) {
      throw const NetworkFailure(message: 'No internet connection');
    }
  }

  Exception _handleError(Object error) {
    if (error is SocketException) {
      return NetworkFailure(
          message: 'Network error: \${error.message}');
    } else if (error is TimeoutException) {
      return const TimeoutFailure();
    } else if (error is ApiFailure) {
      return error as Exception;
    }
    return UnexpectedFailure(message: 'Unexpected error: \$error');
  }

  /// ✅ FIX 7: debug-only logging — no output in release builds
  void _log(String method, Uri uri, dynamic body) {
    assert(() {
      // ignore: avoid_print
      print('➡️  [\$method] \$uri');
      if (body != null) print('   Body: \$body');
      return true;
    }());
  }

  void _logResponse(int statusCode, String body) {
    assert(() {
      final emoji = statusCode >= 200 && statusCode < 300 ? '✅' : '❌';
      // ignore: avoid_print
      print('\$emoji  [\$statusCode] \${body.length > 300 ? body.substring(0, 300) + "..." : body}');
      return true;
    }());
  }

  void dispose() {
    client.close();
  }
}
''');

  return buffer.toString();
}