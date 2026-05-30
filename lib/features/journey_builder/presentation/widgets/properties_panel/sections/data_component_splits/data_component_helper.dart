import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:revojourneytryone/features/journey_builder/domain/entities/journey_models.dart';
import 'package:revojourneytryone/features/journey_builder/application/controllers/journey_controller.dart';

class GridApiTestState {
  final bool testing;
  final String? result;
  final bool success;
  final List<Map<String, dynamic>>? previewRows;

  GridApiTestState({
    this.testing = false,
    this.result,
    this.success = false,
    this.previewRows,
  });
}

class GridApiTestNotifier extends StateNotifier<GridApiTestState> {
  GridApiTestNotifier() : super(GridApiTestState());

  void reset() {
    state = GridApiTestState();
  }

  void startTesting() {
    state = GridApiTestState(testing: true);
  }

  void setError(String err) {
    state = GridApiTestState(success: false, result: err);
  }

  void setSuccess(String msg, List<Map<String, dynamic>> rows) {
    state = GridApiTestState(success: true, result: msg, previewRows: rows);
  }
}

final gridApiTestProvider = StateNotifierProvider<GridApiTestNotifier, GridApiTestState>((ref) {
  return GridApiTestNotifier();
});

class DataComponentHelper {
  static Uri gridApiUri(String urlText, Map<String, dynamic> config) {
    final uri = Uri.parse(urlText);
    if (config['apiPagination'] != true) return uri;
    final pageParam = config['apiPageParam']?.toString() ?? 'page';
    final sizeParam = config['apiPageSizeParam']?.toString() ?? 'limit';
    final rowsPerPage = config['rowsPerPage']?.toString() ?? '10';

    final newParams = Map<String, dynamic>.from(uri.queryParametersAll);
    if (pageParam.isNotEmpty) newParams[pageParam] = ['1'];
    if (sizeParam.isNotEmpty) newParams[sizeParam] = [rowsPerPage];

    return uri.replace(queryParameters: newParams);
  }

  static Map<String, String> gridApiHeaders(dynamic rawHeaders) {
    final headers = <String, String>{};
    if (rawHeaders is Map) {
      rawHeaders.forEach((key, value) => headers[key.toString()] = value.toString());
    }
    return headers;
  }

  static List<Map<String, dynamic>> extractGridRows(dynamic decoded, String listKey) {
    dynamic source = decoded;
    if (decoded is Map && listKey.trim().isNotEmpty) {
      source = readJsonPath(decoded, listKey) ?? decoded[listKey];
    }
    if (source is! List && decoded is Map) {
      for (final key in ['data', 'items', 'results', 'rows']) {
        if (decoded[key] is List) {
          source = decoded[key];
          break;
        }
      }
    }
    if (source is! List) return <Map<String, dynamic>>[];
    return source.map<Map<String, dynamic>>((item) {
      if (item is Map) return Map<String, dynamic>.from(item);
      return {'value': item.toString()};
    }).toList();
  }

  static dynamic readJsonPath(dynamic source, String path) {
    if (path.trim().isEmpty) return null;
    dynamic cursor = source;
    for (final part in path.split('.')) {
      if (cursor is Map) {
        cursor = cursor[part];
      } else {
        return null;
      }
    }
    return cursor;
  }

  static Future<void> testGridApiConnection(
    WidgetRef ref,
    JourneyField field,
    String activeStepId,
  ) async {
    final config = field.componentConfig ?? {};
    final urlText = config['gridApiUrl']?.toString().trim() ?? '';
    final testNotifier = ref.read(gridApiTestProvider.notifier);

    if (urlText.isEmpty) {
      testNotifier.setError("Error: Grid API URL is required.");
      return;
    }

    testNotifier.startTesting();

    try {
      final uri = gridApiUri(urlText, config);
      final method = (config['gridApiMethod']?.toString() ?? 'GET').toUpperCase();
      final headers = gridApiHeaders(config['gridApiHeaders']);
      if (!headers.containsKey('Content-Type') && method != 'GET') {
        headers['Content-Type'] = 'application/json';
      }
      final bodyText = config['gridApiBody']?.toString().trim() ?? '';
      final body = bodyText.isEmpty ? null : bodyText;

      http.Response response;
      if (method == 'POST') {
        response = await http.post(uri, headers: headers, body: body).timeout(const Duration(seconds: 15));
      } else if (method == 'PUT') {
        response = await http.put(uri, headers: headers, body: body).timeout(const Duration(seconds: 15));
      } else if (method == 'DELETE') {
        response = await http.delete(uri, headers: headers, body: body).timeout(const Duration(seconds: 15));
      } else {
        response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 15));
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        testNotifier.setError("HTTP Error: Status ${response.statusCode}\nResponse: ${response.body}");
        return;
      }

      final decoded = json.decode(response.body);
      final rows = extractGridRows(decoded, config['gridApiListKey']?.toString() ?? '');
      final updatedConfig = {
        ...config,
        'gridApiSampleData': rows,
        'dataSource': 'api',
      };
      final updated = field.copyWith()..componentConfig = updatedConfig;
      ref.read(journeyConfigProvider.notifier).updateFieldInStep(activeStepId, field.id, updated);

      testNotifier.setSuccess(
        "Connection successful!\nStatus: ${response.statusCode}\nParsed ${rows.length} grid row(s) and saved sample data.",
        rows,
      );
    } catch (e) {
      testNotifier.setError("Grid API test failed: ${e.toString()}");
    }
  }
}
