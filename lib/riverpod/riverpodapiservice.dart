String generateapiserviceInterface(
) {
  final buffer = StringBuffer();


buffer.writeln('''
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path/path.dart';

/// A reusable API service class that handles all network operations
class ApiService {
  final String baseUrl;
  final http.Client client;
  final Duration timeout;
  
  ApiService({
    required this.baseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 30),
  }) : client = client ?? http.Client();

  /// GET request
  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    return _makeRequest(
      method: 'GET',
      endpoint: endpoint,
      headers: headers,
      queryParameters: queryParameters,
      requiresAuth: requiresAuth,
    );
  }

  /// POST request
  Future<dynamic> post(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    return _makeRequest(
      method: 'POST',
      endpoint: endpoint,
      headers: headers,
      body: body,
      queryParameters: queryParameters,
      requiresAuth: requiresAuth,
    );
  }

  /// File upload (Multipart)
  Future<dynamic> upload(
    String endpoint, {
    required File file,
    String fieldName = 'file',
    Map<String, String>? headers,
    Map<String, dynamic>? fields,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    await _checkInternetConnection();
    final uri = _buildUri(endpoint, queryParameters);
    final request = http.MultipartRequest('POST', uri);

    // Attach file
    final fileStream = http.ByteStream(file.openRead());
    final fileLength = await file.length();
    request.files.add(
      http.MultipartFile(
        fieldName,
        fileStream,
        fileLength,
        filename: basename(file.path),
      ),
    );

    // Attach additional fields
    if (fields != null) {
      request.fields.addAll(fields.map((k, v) => MapEntry(k, v.toString())));
    }

    request.headers.addAll(_buildHeaders(headers, requiresAuth));

    try {
      final streamedResponse = await request.send().timeout(timeout);
      return _handleStreamedResponse(streamedResponse);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ========== PRIVATE ========== //

  Future<dynamic> _makeRequest({
    required String method,
    required String endpoint,
    Map<String, String>? headers,
    dynamic body,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    await _checkInternetConnection();
    final uri = _buildUri(endpoint, queryParameters);
    final requestHeaders = _buildHeaders(headers, requiresAuth);

    try {
      late final http.Response response;
      final encodedBody = body != null ? jsonEncode(body) : null;
      switch (method) {
        case 'GET':
          response = await client.get(uri, headers: requestHeaders).timeout(timeout);
          break;
        case 'POST':
          response = await client.post(uri, headers: requestHeaders, body: encodedBody).timeout(timeout);
          break;
        case 'PUT':
          response = await client.put(uri, headers: requestHeaders, body: encodedBody).timeout(timeout);
          break;
        case 'DELETE':
          response = await client.delete(uri, headers: requestHeaders, body: encodedBody).timeout(timeout);
          break;
        default:
          throw ApiException(message: 'Unsupported HTTP method: \$method');
      }

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Uri _buildUri(String endpoint, Map<String, dynamic>? queryParameters) {
    final uri = Uri.parse(baseUrl).resolve(endpoint);
    return queryParameters != null
        ? uri.replace(queryParameters: queryParameters.map((k, v) => MapEntry(k, v.toString())))
        : uri;
  }

  Map<String, String> _buildHeaders(Map<String, String>? additional, bool requiresAuth) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?additional,
    };
    if (requiresAuth) {
      // Provide token via method or override this class
      headers['Authorization'] = 'Bearer YOUR_ACCESS_TOKEN';
    }
    return headers;
  }

  dynamic _handleResponse(http.Response response) {
    final jsonBody = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonBody;
    }
    throw ApiException(
      message: jsonBody['message'] ?? 'Request failed',
      statusCode: response.statusCode,
      data: jsonBody,
    );
  }

  Future<dynamic> _handleStreamedResponse(http.StreamedResponse response) async {
    final str = await response.stream.bytesToString();
    final jsonBody = jsonDecode(str);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonBody;
    }
    throw ApiException(
      message: jsonBody['message'] ?? 'Request failed',
      statusCode: response.statusCode,
      data: jsonBody,
    );
  }

  Future<void> _checkInternetConnection() async {
    final conn = await Connectivity().checkConnectivity();
    if (conn == ConnectivityResult.none) {
      throw ApiException(message: 'No internet connection');
    }
  }

  Exception _handleError(Object error) {
    if (error is SocketException) {
      return ApiException(message: 'Network error: \${error.message}');
    } else if (error is TimeoutException) {
      return ApiException(message: 'Request timeout');
    } else if (error is ApiException) {
      return error;
    }
    return ApiException(message: 'Unexpected error: \$error');
  }

  void dispose() {
    client.close();
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({required this.message, this.statusCode, this.data});

  @override
  String toString() => 'ApiException: \$message (\${statusCode ?? 'No Status'})';
}
''');
 return buffer.toString();
}