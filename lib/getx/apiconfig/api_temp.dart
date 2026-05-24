/// Generates the full source code for an API provider class.
String generateApiProviderTemplate({
  required String providerClassName,
  required String configClassName,
  required String exceptionClassName,
  String baseUrl = 'https://api.example.com/',
  Duration timeout = const Duration(seconds: 15),
}) {
  final buffer = StringBuffer();

  // Core imports
  buffer.writeln("import 'dart:async';");
  buffer.writeln("import 'dart:convert';");
  buffer.writeln("import 'package:http/http.dart' as http;\n");

  // Configuration class
  buffer.writeln('/// Configuration for API endpoints and timeouts');
  buffer.writeln('class $configClassName {');
  buffer.writeln("  static const String baseUrl = '$baseUrl';");
  buffer.writeln('  static const Duration timeout = Duration(seconds: ${timeout.inSeconds});');
  buffer.writeln('  static const Map<String, String> defaultHeaders = {');
  buffer.writeln("    'Content-Type': 'application/json',");
  buffer.writeln("    'Accept': 'application/json',");
  buffer.writeln('  };');
  buffer.writeln('}\n');

  // Exception class
  buffer.writeln('/// Exception thrown for API request failures');
  buffer.writeln('class $exceptionClassName implements Exception {');
  buffer.writeln('  final int statusCode;');
  buffer.writeln('  final String message;');
  buffer.writeln('  final dynamic data;\n');
  buffer.writeln('  $exceptionClassName(this.statusCode, this.message, [this.data]);');
  buffer.writeln('  @override');
  buffer.writeln('  String toString() => "$exceptionClassName: \$statusCode - \$message";');
  buffer.writeln('}\n');

  // Provider class
  buffer.writeln('/// Handles HTTP requests using configured settings');
  buffer.writeln('class $providerClassName {');
  buffer.writeln('  final http.Client _client;');
  buffer.writeln('  final String _baseUrl;');
  buffer.writeln('  final Duration _timeout;\n');
  buffer.writeln('  $providerClassName({');
  buffer.writeln('    http.Client? client,');
  buffer.writeln('    String? baseUrl,');
  buffer.writeln('    Duration? timeout,');
  buffer.writeln('  }) :');
  buffer.writeln('    _client = client ?? http.Client(),');
  buffer.writeln('    _baseUrl = baseUrl ?? $configClassName.baseUrl,');
  buffer.writeln('    _timeout = timeout ?? $configClassName.timeout;\n');

  // CRUD methods
  for (final method in ['get', 'post', 'put', 'delete']) {
    buffer.writeln('  /// Sends a ${method.toUpperCase()} request');
    buffer.writeln('  Future<dynamic> $method(');
    buffer.writeln('    String endpoint, {');
    if (method != 'get') buffer.writeln('    dynamic body,');
    buffer.writeln('    Map<String, dynamic>? queryParams,');
    buffer.writeln('    Map<String, String>? headers,');
    buffer.writeln('  }) async => _request(');
    buffer.writeln('        HttpMethod.$method, endpoint,');
    if (method != 'get') buffer.writeln('        body: body,');
    buffer.writeln('        queryParams: queryParams,');
    buffer.writeln('        headers: headers,');
    buffer.writeln('      );\n');
  }

  // Helper: headers
  buffer.writeln('  Map<String, String> _buildHeaders([Map<String, String>? extra]) =>');
  buffer.writeln('      {...$configClassName.defaultHeaders, ...?extra};\n');

  // Helper: URI
  buffer.writeln('  Uri _buildUri(String endpoint, Map<String, dynamic>? params) {');
  buffer.writeln('    final url = endpoint.startsWith("http") ? endpoint : "\$_baseUrl\$endpoint";');
  buffer.writeln('    return Uri.parse(url).replace(');
  buffer.writeln('      queryParameters: params?.map((k, v) => MapEntry(k, v.toString())),');
  buffer.writeln('    );');
  buffer.writeln('  }\n');

  // Core request
  buffer.writeln('  Future<dynamic> _request(');
  buffer.writeln('    HttpMethod method, String endpoint, {');
  buffer.writeln('    dynamic body, Map<String, dynamic>? queryParams, Map<String, String>? headers,');
  buffer.writeln('  }) async {');
  buffer.writeln('    final uri = _buildUri(endpoint, queryParams);');
  buffer.writeln('    try {');
  buffer.writeln('      final resp = await _executeRequest(');
  buffer.writeln('        method, uri,');
  buffer.writeln('        headers: _buildHeaders(headers),');
  buffer.writeln('        body: body,');
  buffer.writeln('      ).timeout(_timeout);');
  buffer.writeln('      return _handleResponse(resp);');
  buffer.writeln('    } on TimeoutException {');
  buffer.writeln('      throw $exceptionClassName(408, "Request timed out");');
  buffer.writeln('    } on FormatException {');
  buffer.writeln('      throw $exceptionClassName(400, "Bad response format");');
  buffer.writeln('    } on http.ClientException catch (e) {');
  buffer.writeln('      throw $exceptionClassName(0, "Network error: " + e.message);');
  buffer.writeln('    } catch (e) {');
  buffer.writeln('      throw $exceptionClassName(500, "Unexpected error: " + e.toString());');
  buffer.writeln('    }');
  buffer.writeln('  }\n');

  // Execute request
  buffer.writeln('  Future<http.Response> _executeRequest(');
  buffer.writeln('    HttpMethod method, Uri uri, {Map<String, String>? headers, dynamic body,}');
  buffer.writeln('  ) async {');
  buffer.writeln('    final encodedBody = body != null ? jsonEncode(body) : null;');
  buffer.writeln('    switch (method) {');
  buffer.writeln('      case HttpMethod.get:');
  buffer.writeln('        return _client.get(uri, headers: headers);');
  buffer.writeln('      case HttpMethod.post:');
  buffer.writeln('        return _client.post(uri, headers: headers, body: encodedBody);');
  buffer.writeln('      case HttpMethod.put:');
  buffer.writeln('        return _client.put(uri, headers: headers, body: encodedBody);');
  buffer.writeln('      case HttpMethod.delete:');
  buffer.writeln('        return _client.delete(uri, headers: headers, body: encodedBody);');
  buffer.writeln('    }');
  buffer.writeln('  }\n');

  // Handle response
  buffer.writeln('  dynamic _handleResponse(http.Response response) {');
  buffer.writeln('    final status = response.statusCode;');
  buffer.writeln('    dynamic data;');
  buffer.writeln('    try {');
  buffer.writeln('      data = response.body.isNotEmpty ? jsonDecode(response.body) : null;');
  buffer.writeln('    } catch (_) {');
  buffer.writeln('      throw $exceptionClassName(status, "Failed to parse response", response.body);');
  buffer.writeln('    }');
  buffer.writeln('    if (status >= 200 && status < 300) return data;');
  buffer.writeln('    throw $exceptionClassName(');
  buffer.writeln('      status,');
  buffer.writeln('      (data is Map && data["message"] != null)');
  buffer.writeln('        ? data["message"]');
  buffer.writeln('        : "Request failed with status " + status.toString(),');
  buffer.writeln('      data,');
  buffer.writeln('    );');
  buffer.writeln('  }\n');

  // Dispose
  buffer.writeln('  void dispose() => _client.close();');
  buffer.writeln('}\n');

  // Enum
  buffer.writeln('enum HttpMethod { get, post, put, delete }');

  return buffer.toString();
}