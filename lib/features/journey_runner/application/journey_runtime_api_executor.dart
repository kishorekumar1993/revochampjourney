import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../journey_builder/domain/entities/journey_models.dart';

class JourneyApiFailure implements Exception {
  final String message;
  final int? statusCode;

  const JourneyApiFailure(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Executes step `apiCalls` and action-triggered API calls from journey JSON.
class JourneyRuntimeApiExecutor {
  JourneyRuntimeApiExecutor({
    http.Client? client,
    Duration timeout = const Duration(seconds: 20),
    int maxRetries = 1,
  })  : _client = client ?? http.Client(),
        _timeout = timeout,
        _maxRetries = maxRetries;

  final http.Client _client;
  final Duration _timeout;
  final int _maxRetries;

  Future<void> executeStepApis({
    required JourneyStep step,
    required Map<String, dynamic> formValues,
    required String trigger,
  }) async {
    final apis = <StepAPI>[
      ...step.apiCalls,
      ...step.actions
          .where((a) =>
              a.actionType == 'apiCall' &&
              _triggerMatches(a.trigger, trigger))
          .map(
            (a) => StepAPI(
              method: 'POST',
              url: a.details,
              description: a.details,
            ),
          ),
    ];

    for (final api in apis) {
      final resolvedUrl = _interpolate(api.url, formValues).trim();
      if (resolvedUrl.isEmpty) continue;
      if (!_isRunnableUrl(resolvedUrl)) continue;
      await _executeApi(api, formValues);
    }
  }

  bool _isRunnableUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  bool _triggerMatches(String actionTrigger, String currentTrigger) {
    final normalized = actionTrigger.toLowerCase();
    if (normalized == currentTrigger.toLowerCase()) return true;
    if (normalized == 'onsubmit' &&
        (currentTrigger == 'submit' || currentTrigger == 'next')) {
      return true;
    }
    if (normalized == 'onnext' && currentTrigger == 'next') return true;
    if (normalized == 'onsavedraft' && currentTrigger == 'saveDraft') {
      return true;
    }
    return false;
  }

  Future<void> _executeApi(
    StepAPI api,
    Map<String, dynamic> formValues,
  ) async {
    final url = _interpolate(api.url, formValues);
    if (url.trim().isEmpty) return;

    final uri = Uri.parse(url);
    final method = api.method.toUpperCase();
    final headers = _resolveHeaders(api.headers, formValues);
    final bodyText = api.body == null
        ? jsonEncode(formValues)
        : _interpolate(api.body!, formValues);

    Object? lastError;
    for (var attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        final response = await _send(method, uri, headers, bodyText);
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return;
        }
        lastError = JourneyApiFailure(
          api.description.isNotEmpty
              ? api.description
              : 'API failed with status ${response.statusCode}',
          statusCode: response.statusCode,
        );
      } catch (e) {
        lastError = e;
      }
      if (attempt < _maxRetries) {
        await Future<void>.delayed(Duration(milliseconds: 300 * (attempt + 1)));
      }
    }

    throw lastError ??
        JourneyApiFailure('API call failed for ${api.description}');
  }

  Future<http.Response> _send(
    String method,
    Uri uri,
    Map<String, String> headers,
    String bodyText,
  ) async {
    switch (method) {
      case 'POST':
        return _client
            .post(uri, headers: headers, body: bodyText)
            .timeout(_timeout);
      case 'PUT':
        return _client
            .put(uri, headers: headers, body: bodyText)
            .timeout(_timeout);
      case 'DELETE':
        return _client
            .delete(uri, headers: headers, body: bodyText)
            .timeout(_timeout);
      case 'PATCH':
        return _client
            .patch(uri, headers: headers, body: bodyText)
            .timeout(_timeout);
      default:
        return _client.get(uri, headers: headers).timeout(_timeout);
    }
  }

  Map<String, String> _resolveHeaders(
    Map<String, dynamic>? rawHeaders,
    Map<String, dynamic> formValues,
  ) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (rawHeaders == null) return headers;

    rawHeaders.forEach((key, value) {
      headers[key.toString()] = _interpolate(value.toString(), formValues);
    });
    return headers;
  }

  String _interpolate(String template, Map<String, dynamic> values) {
    return template.replaceAllMapped(RegExp(r'\{\{(\w+)\}\}'), (match) {
      return values[match.group(1)!]?.toString() ?? '';
    });
  }
}
