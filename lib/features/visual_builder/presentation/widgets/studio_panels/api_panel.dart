import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme.dart';
import '../../../../../core/component_engine/models/api_config.dart';
import '../../../application/studio_providers.dart';

import 'studio_panel_wrapper.dart';

// 3. API Studio config panel
class RevoApiStudioPanel extends ConsumerStatefulWidget {
  const RevoApiStudioPanel({super.key});

  @override
  ConsumerState<RevoApiStudioPanel> createState() => _RevoApiStudioPanelState();
}

class _RevoApiStudioPanelState extends ConsumerState<RevoApiStudioPanel> {
  ApiConfig? _selectedConfig;
  bool _isTesting = false;
  int? _responseStatus;
  String? _responseBody;
  String? _testError;

  void _showCodeSnippetDialog(String title, String code) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: RevoTheme.sidebarBackground,
          title: Text(title, style: GoogleFonts.outfit(color: RevoTheme.textPrimary)),
          content: SizedBox(
            width: 500,
            height: 400,
            child: TextField(
              controller: TextEditingController(text: code),
              maxLines: null,
              readOnly: true,
              style: GoogleFonts.sourceCodePro(fontSize: 11, color: Colors.greenAccent),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                fillColor: Colors.black,
                filled: true,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close", style: TextStyle(color: Color(0xFF5B4FCF))),
            ),
          ],
        );
      },
    );
  }

  Future<void> _testApi(ApiConfig config) async {
    setState(() {
      _isTesting = true;
      _responseStatus = null;
      _responseBody = null;
      _testError = null;
    });

    try {
      String urlStr = config.baseUrl;
      if (!urlStr.endsWith('/') && !config.endpoint.startsWith('/')) {
        urlStr += '/';
      }
      urlStr += config.endpoint;

      // Replace variables in URL paths
      final variables = ref.read(appVariablesProvider);
      for (final v in variables) {
        urlStr = urlStr.replaceAll('{${v.name}}', v.currentValue?.toString() ?? '');
      }

      final uri = Uri.parse(urlStr);
      final queryParams = Map<String, String>.from(uri.queryParameters)..addAll(config.queryParams);
      final finalUri = uri.replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final headers = Map<String, String>.from(config.headers);
      if (config.method != 'GET' && !headers.containsKey('Content-Type') && !headers.containsKey('content-type')) {
        headers['Content-Type'] = 'application/json';
      }

      if (config.authentication.toLowerCase().contains('bearer')) {
        headers['Authorization'] = 'Bearer dummy_jwt_token';
      }

      http.Response response;
      switch (config.method.toUpperCase()) {
        case 'POST':
          response = await http.post(finalUri, headers: headers, body: config.requestBody);
          break;
        case 'PUT':
          response = await http.put(finalUri, headers: headers, body: config.requestBody);
          break;
        case 'PATCH':
          response = await http.patch(finalUri, headers: headers, body: config.requestBody);
          break;
        case 'DELETE':
          response = await http.delete(finalUri, headers: headers, body: config.requestBody);
          break;
        default: // GET
          response = await http.get(finalUri, headers: headers);
          break;
      }

      String formattedBody = response.body;
      try {
        final parsed = json.decode(response.body);
        formattedBody = const JsonEncoder.withIndent('  ').convert(parsed);
      } catch (_) {}

      setState(() {
        _isTesting = false;
        _responseStatus = response.statusCode;
        _responseBody = formattedBody;
      });
    } catch (e) {
      setState(() {
        _isTesting = false;
        _testError = e.toString();
      });
    }
  }

  String _generateResponseModel(ApiConfig config, String? responseBody) {
    if (responseBody != null && responseBody.trim().isNotEmpty) {
      try {
        final decoded = json.decode(responseBody);
        if (decoded is Map<String, dynamic>) {
          return _generateModelFromJson(config.name.replaceAll(' ', ''), decoded);
        } else if (decoded is List && decoded.isNotEmpty && decoded.first is Map<String, dynamic>) {
          return _generateModelFromJson(config.name.replaceAll(' ', ''), decoded.first as Map<String, dynamic>);
        }
      } catch (_) {}
    }
    return '''
class ${config.name.replaceAll(' ', '')}Response {
  final bool success;
  final String message;
  final Map<String, dynamic> data;

  ${config.name.replaceAll(' ', '')}Response({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ${config.name.replaceAll(' ', '')}Response.fromJson(Map<String, dynamic> json) {
    return ${config.name.replaceAll(' ', '')}Response(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? Map<String, dynamic>.from(json['data']) : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data,
    };
  }
}
''';
  }

  String _generateModelFromJson(String className, Map<String, dynamic> jsonMap) {
    final buffer = StringBuffer();
    buffer.writeln('class $className {');
    
    for (final entry in jsonMap.entries) {
      final key = entry.key;
      final value = entry.value;
      String type = 'dynamic';
      if (value is String) {
        type = 'String';
      } else if (value is int) {
        type = 'int';
      } else if (value is double) {
        type = 'double';
      } else if (value is bool) {
        type = 'bool';
      } else if (value is List) {
        type = 'List<dynamic>';
      } else if (value is Map) {
        type = 'Map<String, dynamic>';
      }
      
      buffer.writeln('  final $type $key;');
    }
    
    buffer.writeln('');
    buffer.writeln('  $className({');
    for (final key in jsonMap.keys) {
      buffer.writeln('    required this.$key,');
    }
    buffer.writeln('  });');
    buffer.writeln('');
    
    buffer.writeln('  factory $className.fromJson(Map<String, dynamic> json) {');
    buffer.writeln('    return $className(');
    for (final entry in jsonMap.entries) {
      final key = entry.key;
      final value = entry.value;
      String fallback = 'null';
      if (value is String) {
        fallback = "''";
      } else if (value is int) {
        fallback = '0';
      } else if (value is double) {
        fallback = '0.0';
      } else if (value is bool) {
        fallback = 'false';
      } else if (value is List) {
        fallback = 'const []';
      } else if (value is Map) {
        fallback = 'const {}';
      }
      
      if (fallback == 'null') {
        buffer.writeln("      $key: json['$key'],");
      } else {
        buffer.writeln("      $key: json['$key'] ?? $fallback,");
      }
    }
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln('');
    
    buffer.writeln('  Map<String, dynamic> toJson() {');
    buffer.writeln('    return {');
    for (final key in jsonMap.keys) {
      buffer.writeln("      '$key': $key,");
    }
    buffer.writeln('    };');
    buffer.writeln('  }');
    
    buffer.writeln('}');
    return buffer.toString();
  }

  Widget _buildMapEditor({
    required String title,
    required Map<String, String> dataMap,
    required void Function(Map<String, String>) onUpdated,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary, fontWeight: FontWeight.w600),
            ),
            IconButton(
              icon: const Icon(Icons.add_rounded, size: 16, color: Color(0xFF5B4FCF)),
              onPressed: () {
                final updMap = Map<String, String>.from(dataMap);
                int count = 1;
                final baseKey = title.toLowerCase().contains('header') ? 'header' : 'param';
                while (updMap.containsKey('${baseKey}_$count')) {
                  count++;
                }
                updMap['${baseKey}_$count'] = 'value';
                onUpdated(updMap);
              },
            ),
          ],
        ),
        if (dataMap.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              "No $title configured",
              style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary, fontStyle: FontStyle.italic),
            ),
          ),
        ...dataMap.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: entry.key,
                    onChanged: (newKey) {
                      if (newKey.trim().isEmpty || newKey == entry.key) return;
                      final updMap = Map<String, String>.from(dataMap);
                      final val = updMap.remove(entry.key);
                      updMap[newKey] = val ?? '';
                      onUpdated(updMap);
                    },
                    style: GoogleFonts.inter(fontSize: 11),
                    decoration: const InputDecoration(
                      hintText: 'Key',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: entry.value,
                    onChanged: (newVal) {
                      final updMap = Map<String, String>.from(dataMap);
                      updMap[entry.key] = newVal;
                      onUpdated(updMap);
                    },
                    style: GoogleFonts.inter(fontSize: 11),
                    decoration: const InputDecoration(
                      hintText: 'Value',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                  onPressed: () {
                    final updMap = Map<String, String>.from(dataMap);
                    updMap.remove(entry.key);
                    onUpdated(updMap);
                  },
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(apiConfigsProvider);
    final notifier = ref.read(apiConfigsProvider.notifier);

    if (_selectedConfig != null) {
      final config = _selectedConfig!;
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Center(
              child: SizedBox(
                child: RevoStudioPanelWrapper(
                    title: "Edit API Endpoint",
                    subtitle: config.name,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        onPressed: () {
                          setState(() {
                            _selectedConfig = null;
                            _responseStatus = null;
                            _responseBody = null;
                            _testError = null;
                          });
                        },
                      ),
                    ],
                    child: SizedBox(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildTextField(
                            label: "API Name",
                            value: config.name,
                            onChanged: (val) {
                              final upd = config.copyWith(name: val);
                              setState(() => _selectedConfig = upd);
                              notifier.updateConfig(config.id, upd);
                            },
                          ),
                          _buildTextField(
                            label: "Base URL",
                            value: config.baseUrl,
                            onChanged: (val) {
                              final upd = config.copyWith(baseUrl: val);
                              setState(() => _selectedConfig = upd);
                              notifier.updateConfig(config.id, upd);
                            },
                          ),
                          _buildTextField(
                            label: "Endpoint Path",
                            value: config.endpoint,
                            onChanged: (val) {
                              final upd = config.copyWith(endpoint: val);
                              setState(() => _selectedConfig = upd);
                              notifier.updateConfig(config.id, upd);
                            },
                          ),
                          _buildDropdown(
                            label: "HTTP Method",
                            value: config.method,
                            options: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
                            onChanged: (val) {
                              final upd = config.copyWith(method: val);
                              setState(() => _selectedConfig = upd);
                              notifier.updateConfig(config.id, upd);
                            },
                          ),
                          _buildTextField(
                            label: "Authorization Type",
                            value: config.authentication,
                            onChanged: (val) {
                              final upd = config.copyWith(authentication: val);
                              setState(() => _selectedConfig = upd);
                              notifier.updateConfig(config.id, upd);
                            },
                          ),
                          const SizedBox(height: 8),
                          _buildMapEditor(
                            title: "Headers",
                            dataMap: config.headers,
                            onUpdated: (newMap) {
                              final upd = config.copyWith(headers: newMap);
                              setState(() => _selectedConfig = upd);
                              notifier.updateConfig(config.id, upd);
                            },
                          ),
                          _buildMapEditor(
                            title: "Query Parameters",
                            dataMap: config.queryParams,
                            onUpdated: (newMap) {
                              final upd = config.copyWith(queryParams: newMap);
                              setState(() => _selectedConfig = upd);
                              notifier.updateConfig(config.id, upd);
                            },
                          ),
                          if (config.method != 'GET') ...[
                            Text(
                              "Request Body (JSON)",
                              style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              initialValue: config.requestBody,
                              onChanged: (val) {
                                final upd = config.copyWith(requestBody: val);
                                setState(() => _selectedConfig = upd);
                                notifier.updateConfig(config.id, upd);
                              },
                              maxLines: 4,
                              style: GoogleFonts.sourceCodePro(fontSize: 11),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _testApi(config),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    backgroundColor: Colors.teal[700],
                                  ),
                                  child: const Text("Test Endpoint", style: TextStyle(fontSize: 11, color: Colors.white)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    _showCodeSnippetDialog(
                                      "Generated Response Model",
                                      _generateResponseModel(config, _responseBody),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    backgroundColor: const Color(0xFF5B4FCF),
                                  ),
                                  child: const Text("Generate Model", style: TextStyle(fontSize: 11, color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Text(
                            "Response Preview",
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
                          ),
                          const SizedBox(height: 8),
                          if (_isTesting)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF5B4FCF)),
                              ),
                            )
                          else if (_testError != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                _testError!,
                                style: GoogleFonts.inter(fontSize: 11, color: Colors.redAccent),
                              ),
                            )
                          else if (_responseStatus != null) ...[
                            Row(
                              children: [
                                Text(
                                  "Status: ",
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: RevoTheme.textSecondary),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (_responseStatus! >= 200 && _responseStatus! < 300)
                                        ? Colors.green.withValues(alpha: 0.15)
                                        : Colors.red.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _responseStatus.toString(),
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: (_responseStatus! >= 200 && _responseStatus! < 300) ? Colors.green : Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_responseBody != null)
                              Container(
                                height: 180,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: RevoTheme.cardBorder),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: SingleChildScrollView(
                                  child: SelectableText(
                                    _responseBody!,
                                    style: GoogleFonts.sourceCodePro(fontSize: 10, color: Colors.greenAccent),
                                  ),
                                ),
                              ),
                          ] else
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                "No response loaded yet. Click Test Endpoint.",
                                style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary, fontStyle: FontStyle.italic),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
      );
    }

    return RevoStudioPanelWrapper(
      title: "API Studio",
      subtitle: "Configure REST APIs & endpoints",
      actions: [
        IconButton(
          icon: const Icon(Icons.add_rounded, size: 18),
          onPressed: () {
            final id = 'api_${DateTime.now().millisecondsSinceEpoch}';
            final newApi = ApiConfig(
              id: id,
              name: 'New Custom API',
              baseUrl: 'https://api.example.com',
              endpoint: '/v1/users',
              method: 'GET',
            );
            notifier.addConfig(newApi);
            setState(() => _selectedConfig = newApi);
          },
        ),
      ],
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final api = list[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Card(
              child: ListTile(
                onTap: () => setState(() => _selectedConfig = api),
                leading: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getMethodColor(api.method).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    api.method,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: _getMethodColor(api.method),
                    ),
                  ),
                ),
                title: Text(
                  api.name,
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  api.endpoint,
                  style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                  onPressed: () => notifier.deleteConfig(api.id),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return Colors.green;
      case 'POST':
        return Colors.blue;
      case 'PUT':
        return Colors.orange;
      case 'DELETE':
        return Colors.red;
      default:
        return Colors.purple;
    }
  }
}

// --- Common UI helper widgets ---

Widget _buildTextField({
  required String label,
  required String value,
  required ValueChanged<String> onChanged,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: value,
          onChanged: onChanged,
          style: GoogleFonts.inter(fontSize: 12),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          ),
        ),
      ],
    ),
  );
}

Widget _buildDropdown({
  required String label,
  required String value,
  required List<String> options,
  required ValueChanged<String?> onChanged,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: options.contains(value) ? value : options.first,
          onChanged: onChanged,
          isDense: true,
          style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textPrimary),
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          ),
          items: options
              .map((opt) => DropdownMenuItem(
                    value: opt,
                    child: Text(opt),
                  ))
              .toList(),
        ),
      ],
    ),
  );
}

