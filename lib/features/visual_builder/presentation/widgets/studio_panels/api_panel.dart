import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme.dart';
import '../../../../../core/component_engine/models/api_config.dart';
import '../../../application/studio_providers.dart';
import 'studio_panel_wrapper.dart';

// Recursive JSON to Dart Model class generator
class DartModelGenerator {
  final Map<String, String> _classesToGenerate = {};

  String generate(String rootClassName, Map<String, dynamic> jsonMap) {
    _classesToGenerate.clear();
    _generateClass(rootClassName, jsonMap);

    final buffer = StringBuffer();
    // Root class is written first
    if (_classesToGenerate.containsKey(rootClassName)) {
      buffer.writeln(_classesToGenerate[rootClassName]);
    }
    _classesToGenerate.forEach((className, classCode) {
      if (className != rootClassName) {
        buffer.writeln(classCode);
      }
    });
    return buffer.toString();
  }

  void _generateClass(String className, Map<String, dynamic> jsonMap) {
    if (_classesToGenerate.containsKey(className)) return;

    final fields = <String, String>{};
    final listTypes = <String, String>{};
    final nestedObjects = <String, String>{};

    for (final entry in jsonMap.entries) {
      final key = entry.key;
      final val = entry.value;
      final fieldName = _safeFieldName(key);

      if (val is String) {
        fields[fieldName] = 'String';
      } else if (val is int) {
        fields[fieldName] = 'int';
      } else if (val is double) {
        fields[fieldName] = 'double';
      } else if (val is bool) {
        fields[fieldName] = 'bool';
      } else if (val is Map<String, dynamic>) {
        final subClassName = _capitalize(className) + _capitalize(fieldName);
        fields[fieldName] = subClassName;
        nestedObjects[fieldName] = subClassName;
        _generateClass(subClassName, val);
      } else if (val is List) {
        if (val.isEmpty) {
          fields[fieldName] = 'List<dynamic>';
        } else {
          final first = val.first;
          if (first is String) {
            fields[fieldName] = 'List<String>';
          } else if (first is int) {
            fields[fieldName] = 'List<int>';
          } else if (first is double) {
            fields[fieldName] = 'List<double>';
          } else if (first is bool) {
            fields[fieldName] = 'List<bool>';
          } else if (first is Map<String, dynamic>) {
            final subClassName = _capitalize(className) + _capitalize(_singular(fieldName));
            fields[fieldName] = 'List<$subClassName>';
            listTypes[fieldName] = subClassName;
            _generateClass(subClassName, first);
          } else {
            fields[fieldName] = 'List<dynamic>';
          }
        }
      } else {
        fields[fieldName] = 'dynamic';
      }
    }

    final buffer = StringBuffer();
    buffer.writeln('class $className {');

    fields.forEach((fieldName, typeName) {
      buffer.writeln('  final $typeName $fieldName;');
    });
    buffer.writeln('');

    buffer.writeln('  $className({');
    fields.forEach((fieldName, _) {
      buffer.writeln('    required this.$fieldName,');
    });
    buffer.writeln('  });');
    buffer.writeln('');

    buffer.writeln('  factory $className.fromJson(Map<String, dynamic> json) {');
    buffer.writeln('    return $className(');
    fields.forEach((fieldName, typeName) {
      final jsonKey = jsonMap.keys.firstWhere((k) => _safeFieldName(k) == fieldName, orElse: () => fieldName);
      if (nestedObjects.containsKey(fieldName)) {
        final subClass = nestedObjects[fieldName]!;
        buffer.writeln("      $fieldName: json['$jsonKey'] != null ? $subClass.fromJson(json['$jsonKey'] as Map<String, dynamic>) : $subClass.empty(),");
      } else if (listTypes.containsKey(fieldName)) {
        final subClass = listTypes[fieldName]!;
        buffer.writeln("      $fieldName: json['$jsonKey'] != null ? (json['$jsonKey'] as List).map((i) => $subClass.fromJson(i as Map<String, dynamic>)).toList() : [],");
      } else {
        String fallback = 'null';
        if (typeName == 'String') {
          fallback = "''";
        } else if (typeName == 'int') {
          fallback = '0';
        } else if (typeName == 'double') {
          fallback = '0.0';
        } else if (typeName == 'bool') {
          fallback = 'false';
        } else if (typeName.startsWith('List')) {
          fallback = 'const []';
        }

        if (fallback == 'null') {
          buffer.writeln("      $fieldName: json['$jsonKey'],");
        } else {
          buffer.writeln("      $fieldName: json['$jsonKey'] ?? $fallback,");
        }
      }
    });
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln('');

    buffer.writeln('  Map<String, dynamic> toJson() {');
    buffer.writeln('    return {');
    fields.forEach((fieldName, typeName) {
      final jsonKey = jsonMap.keys.firstWhere((k) => _safeFieldName(k) == fieldName, orElse: () => fieldName);
      if (nestedObjects.containsKey(fieldName)) {
        buffer.writeln("      '$jsonKey': $fieldName.toJson(),");
      } else if (listTypes.containsKey(fieldName)) {
        buffer.writeln("      '$jsonKey': $fieldName.map((i) => i.toJson()).toList(),");
      } else {
        buffer.writeln("      '$jsonKey': $fieldName,");
      }
    });
    buffer.writeln('    };');
    buffer.writeln('  }');

    buffer.writeln('');
    buffer.writeln('  factory $className.empty() {');
    buffer.writeln('    return $className(');
    fields.forEach((fieldName, typeName) {
      if (nestedObjects.containsKey(fieldName)) {
        final subClass = nestedObjects[fieldName]!;
        buffer.writeln("      $fieldName: $subClass.empty(),");
      } else if (typeName.startsWith('List')) {
        buffer.writeln("      $fieldName: const [],");
      } else if (typeName == 'String') {
        buffer.writeln("      $fieldName: '',");
      } else if (typeName == 'int') {
        buffer.writeln("      $fieldName: 0,");
      } else if (typeName == 'double') {
        buffer.writeln("      $fieldName: 0.0,");
      } else if (typeName == 'bool') {
        buffer.writeln("      $fieldName: false,");
      } else {
        buffer.writeln("      $fieldName: null,");
      }
    });
    buffer.writeln('    );');
    buffer.writeln('  }');

    buffer.writeln('}');
    buffer.writeln('');

    _classesToGenerate[className] = buffer.toString();
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  String _singular(String s) {
    if (s.toLowerCase().endsWith('s') && s.length > 1) {
      return s.substring(0, s.length - 1);
    }
    return s;
  }

  String _safeFieldName(String s) {
    var clean = s.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
    if (clean.isEmpty) return 'field';
    if (RegExp(r'^[0-9]').hasMatch(clean)) {
      clean = 'val_$clean';
    }
    final parts = clean.split('_');
    final buffer = StringBuffer(parts.first);
    for (int i = 1; i < parts.length; i++) {
      buffer.write(_capitalize(parts[i]));
    }
    final finalStr = buffer.toString();
    const keywords = {'class', 'interface', 'extends', 'implements', 'import', 'export', 'final', 'const', 'var', 'dynamic', 'void', 'null', 'true', 'false', 'return', 'if', 'else', 'switch', 'case', 'default', 'for', 'while', 'do', 'break', 'continue', 'in', 'is', 'as', 'new', 'this', 'super'};
    if (keywords.contains(finalStr.toLowerCase())) {
      return '${finalStr}Value';
    }
    return finalStr;
  }
}

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

  // Environment substitution helper
  String _substituteVariables(String input) {
    final activeEnv = ref.read(activeEnvironmentProvider);
    final envVars = ref.read(envVariablesProvider)[activeEnv] ?? {};
    var result = input;
    envVars.forEach((key, val) {
      result = result.replaceAll('{{$key}}', val);
      result = result.replaceAll('{$key}', val);
    });

    final appVars = ref.read(appVariablesProvider);
    for (final v in appVars) {
      result = result.replaceAll('{{${v.name}}}', v.currentValue?.toString() ?? '');
      result = result.replaceAll('{${v.name}}', v.currentValue?.toString() ?? '');
    }
    return result;
  }

  void _showEnvVariablesDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final activeEnv = ref.read(activeEnvironmentProvider);
            final envVars = ref.watch(envVariablesProvider);
            final vars = envVars[activeEnv] ?? {};
            final notifier = ref.read(envVariablesProvider.notifier);

            return AlertDialog(
              backgroundColor: RevoTheme.sidebarBackground,
              title: Text("Configure Environment Variables ($activeEnv)", style: GoogleFonts.outfit(color: RevoTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: 400,
                height: 350,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text("Configure keys replaced in URLs/endpoints via {{name}} format.", style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary)),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.add_rounded, size: 12),
                          label: const Text("Add", style: TextStyle(fontSize: 10)),
                          onPressed: () {
                            _showAddVariableDialog(context, () {
                              setModalState(() {});
                            });
                          },
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView(
                        children: vars.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(entry.key, style: GoogleFonts.sourceCodePro(fontSize: 10, fontWeight: FontWeight.bold, color: RevoTheme.primary)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    initialValue: entry.value,
                                    onChanged: (val) {
                                      notifier.updateVariable(activeEnv, entry.key, val);
                                    },
                                    style: GoogleFonts.inter(fontSize: 11),
                                    decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(6)),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 14, color: Colors.red),
                                  onPressed: () {
                                    notifier.removeVariable(entry.key);
                                    setModalState(() {});
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Done", style: TextStyle(fontSize: 11)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddVariableDialog(BuildContext parentCtx, VoidCallback onAdded) {
    final ctrl = TextEditingController();
    showDialog(
      context: parentCtx,
      builder: (ctx) => AlertDialog(
        backgroundColor: RevoTheme.sidebarBackground,
        title: const Text("New Variable Key", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(fontSize: 11),
          decoration: const InputDecoration(hintText: "e.g. baseUrl", isDense: true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(fontSize: 11))),
          ElevatedButton(
            onPressed: () {
              final key = ctrl.text.trim();
              if (key.isNotEmpty) {
                ref.read(envVariablesProvider.notifier).addVariable(key);
                Navigator.pop(ctx);
                onAdded();
              }
            },
            child: const Text("Add", style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildEnvSelector() {
    final activeEnv = ref.watch(activeEnvironmentProvider);
    final envNotifier = ref.read(activeEnvironmentProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: RevoTheme.sidebarBackground,
        border: Border(bottom: BorderSide(color: RevoTheme.cardBorder)),
      ),
      child: Row(
        children: [
          Text(
            "Active Environment: ",
            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: RevoTheme.textSecondary),
          ),
          const SizedBox(width: 4),
          DropdownButton<String>(
            value: activeEnv,
            onChanged: (val) {
              if (val != null) envNotifier.state = val;
            },
            isDense: true,
            style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.primary, fontWeight: FontWeight.bold),
            underline: const SizedBox(),
            items: ['DEV', 'UAT', 'PROD', 'LOCAL'].map((e) {
              return DropdownMenuItem(value: e, child: Text(e));
            }).toList(),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 14),
            onPressed: _showEnvVariablesDialog,
            tooltip: "Configure Env Keys",
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  void _showSnippetDialog(String title, String code) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: RevoTheme.sidebarBackground,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.outfit(color: RevoTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.copy_all, size: 16, color: Color(0xFF5B4FCF)),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied to clipboard!')));
                },
              ),
            ],
          ),
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
              child: const Text("Close", style: TextStyle(color: Color(0xFF5B4FCF), fontSize: 11)),
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

    // Mock testing response bypass
    if (config.isMockEnabled) {
      await Future.delayed(Duration(seconds: config.mockDelay));
      if (config.mockError.isNotEmpty) {
        setState(() {
          _isTesting = false;
          _testError = "MOCK SERVER ERROR: ${config.mockError}";
        });
      } else {
        String mockResponsePretty = config.mockResponse;
        try {
          final parsed = json.decode(config.mockResponse);
          mockResponsePretty = const JsonEncoder.withIndent('  ').convert(parsed);
        } catch (_) {}
        setState(() {
          _isTesting = false;
          _responseStatus = 200;
          _responseBody = mockResponsePretty;
        });
      }
      return;
    }

    try {
      String urlStr = _substituteVariables(config.baseUrl);
      String endpointStr = _substituteVariables(config.endpoint);

      if (!urlStr.endsWith('/') && !endpointStr.startsWith('/')) {
        urlStr += '/';
      }
      urlStr += endpointStr;

      final uri = Uri.parse(urlStr);
      final queryParams = Map<String, String>.from(uri.queryParameters);
      config.queryParams.forEach((key, val) {
        queryParams[key] = _substituteVariables(val);
      });

      final finalUri = uri.replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final headers = <String, String>{};
      config.headers.forEach((key, val) {
        headers[key] = _substituteVariables(val);
      });

      if (config.method != 'GET' && !headers.containsKey('Content-Type') && !headers.containsKey('content-type')) {
        headers['Content-Type'] = 'application/json';
      }

      // Authorization manager integration
      final authType = config.authentication;
      if (authType == 'Bearer Token' && config.authPassword.isNotEmpty) {
        headers['Authorization'] = 'Bearer ${_substituteVariables(config.authPassword)}';
      } else if (authType == 'Basic Auth') {
        final user = _substituteVariables(config.authUsername);
        final pass = _substituteVariables(config.authPassword);
        final creds = base64Encode(utf8.encode('$user:$pass'));
        headers['Authorization'] = 'Basic $creds';
      } else if (authType == 'API Key') {
        final name = _substituteVariables(config.apiKeyName);
        final val = _substituteVariables(config.apiKeyValue);
        if (name.isNotEmpty) {
          if (config.apiKeyLocation == 'query') {
            queryParams[name] = val;
          } else {
            headers[name] = val;
          }
        }
      } else if (authType == 'OAuth2') {
        headers['Authorization'] = 'Bearer simulated_oauth2_access_token';
      }

      http.Response response;
      final bodyStr = _substituteVariables(config.requestBody);

      switch (config.method.toUpperCase()) {
        case 'POST':
          response = await http.post(finalUri, headers: headers, body: bodyStr);
          break;
        case 'PUT':
          response = await http.put(finalUri, headers: headers, body: bodyStr);
          break;
        case 'PATCH':
          response = await http.patch(finalUri, headers: headers, body: bodyStr);
          break;
        case 'DELETE':
          response = await http.delete(finalUri, headers: headers, body: bodyStr);
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
    final rootClassName = '${config.name.replaceAll(' ', '')}Response';
    if (responseBody != null && responseBody.trim().isNotEmpty) {
      try {
        final decoded = json.decode(responseBody);
        final generator = DartModelGenerator();
        if (decoded is Map<String, dynamic>) {
          return generator.generate(rootClassName, decoded);
        } else if (decoded is List && decoded.isNotEmpty && decoded.first is Map<String, dynamic>) {
          return generator.generate(rootClassName, decoded.first as Map<String, dynamic>);
        }
      } catch (_) {}
    }

    return '''
class $rootClassName {
  final bool success;
  final String message;

  $rootClassName({
    required this.success,
    required this.message,
  });

  factory $rootClassName.fromJson(Map<String, dynamic> json) {
    return $rootClassName(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
    };
  }

  factory $rootClassName.empty() {
    return $rootClassName(success: false, message: '');
  }
}
''';
  }

  String _generateCurl(ApiConfig config) {
    final method = config.method.toUpperCase();
    final substitutedUrl = _substituteVariables(config.baseUrl + config.endpoint);
    final buffer = StringBuffer('curl -X $method "$substitutedUrl"');

    config.headers.forEach((key, val) {
      buffer.write(' \\\n  -H "$key: ${_substituteVariables(val)}"');
    });

    if (config.authentication == 'Bearer Token' && config.authPassword.isNotEmpty) {
      buffer.write(' \\\n  -H "Authorization: Bearer ${_substituteVariables(config.authPassword)}"');
    } else if (config.authentication == 'Basic Auth') {
      final user = _substituteVariables(config.authUsername);
      final pass = _substituteVariables(config.authPassword);
      final creds = base64Encode(utf8.encode('$user:$pass'));
      buffer.write(' \\\n  -H "Authorization: Basic $creds"');
    } else if (config.authentication == 'API Key' && config.apiKeyLocation == 'header') {
      buffer.write(' \\\n  -H "${config.apiKeyName}: ${_substituteVariables(config.apiKeyValue)}"');
    }

    if (method != 'GET' && config.requestBody.trim().isNotEmpty) {
      final escapBody = config.requestBody.replaceAll("'", "'\\''");
      buffer.write(' \\\n  -d \'$escapBody\'');
    }

    return buffer.toString();
  }

  String _generateDioCode(ApiConfig config) {
    final name = config.name.replaceAll(' ', '');
    final rootClassName = '${name}Response';
    final method = config.method.toLowerCase();

    return '''import 'package:dio/dio.dart';
import '${config.name.toLowerCase().replaceAll(' ', '_')}_model.dart';

class ${name}Repository {
  final Dio _dio;

  ${name}Repository(this._dio);

  Future<$rootClassName> execute() async {
    try {
      final response = await _dio.$method(
        '${config.endpoint}',
        ${method == 'get' ? 'queryParameters: const {}' : 'data: ${config.requestBody.isNotEmpty ? config.requestBody : 'const {}'}'},
        options: Options(
          headers: const {
            ${config.headers.entries.map((e) => "'${e.key}': '${e.value}'").join(',\n            ')}
          },
        ),
      );
      return $rootClassName.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception('Dio execution failure: \${e.message}');
    }
  }
}
''';
  }

  String _generateCleanArchitecture(ApiConfig config) {
    final name = config.name.replaceAll(' ', '');
    return '''// ─── Clean Architecture layers ────────────────────────────────────────────────
// 1. Entity
class ${name}Entity {
  final String status;
  const ${name}Entity({required this.status});
}

// 2. Datasource
abstract class ${name}RemoteDataSource {
  Future<${name}Response> callApi();
}

class ${name}RemoteDataSourceImpl implements ${name}RemoteDataSource {
  final Dio _dio;
  ${name}RemoteDataSourceImpl(this._dio);

  @override
  Future<${name}Response> callApi() async {
    final response = await _dio.${config.method.toLowerCase()}('${config.endpoint}');
    return ${name}Response.fromJson(response.data);
  }
}

// 3. Repository
abstract class ${name}Repository {
  Future<${name}Entity> execute();
}

class ${name}RepositoryImpl implements ${name}Repository {
  final ${name}RemoteDataSource dataSource;
  ${name}RepositoryImpl(this.dataSource);

  @override
  Future<${name}Entity> execute() async {
    final res = await dataSource.callApi();
    return ${name}Entity(status: res.toString());
  }
}
''';
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

  Widget _buildAuthPanel(ApiConfig config, ApiConfigsNotifier notifier) {
    final authTypes = ['None', 'Bearer Token', 'Basic Auth', 'API Key', 'OAuth2'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDropdown(
          label: "Authorization Type",
          value: config.authentication,
          options: authTypes,
          onChanged: (val) {
            final upd = config.copyWith(authentication: val ?? 'None');
            setState(() => _selectedConfig = upd);
            notifier.updateConfig(config.id, upd);
          },
        ),
        if (config.authentication == 'Bearer Token') ...[
          _buildTextField(
            label: "Token",
            value: config.authPassword,
            onChanged: (val) {
              final upd = config.copyWith(authPassword: val);
              setState(() => _selectedConfig = upd);
              notifier.updateConfig(config.id, upd);
            },
          ),
        ] else if (config.authentication == 'Basic Auth') ...[
          _buildTextField(
            label: "Username",
            value: config.authUsername,
            onChanged: (val) {
              final upd = config.copyWith(authUsername: val);
              setState(() => _selectedConfig = upd);
              notifier.updateConfig(config.id, upd);
            },
          ),
          _buildTextField(
            label: "Password",
            value: config.authPassword,
            onChanged: (val) {
              final upd = config.copyWith(authPassword: val);
              setState(() => _selectedConfig = upd);
              notifier.updateConfig(config.id, upd);
            },
          ),
        ] else if (config.authentication == 'API Key') ...[
          _buildTextField(
            label: "API Key Header/Query Name",
            value: config.apiKeyName,
            onChanged: (val) {
              final upd = config.copyWith(apiKeyName: val);
              setState(() => _selectedConfig = upd);
              notifier.updateConfig(config.id, upd);
            },
          ),
          _buildTextField(
            label: "API Key Value",
            value: config.apiKeyValue,
            onChanged: (val) {
              final upd = config.copyWith(apiKeyValue: val);
              setState(() => _selectedConfig = upd);
              notifier.updateConfig(config.id, upd);
            },
          ),
          _buildDropdown(
            label: "Key Location",
            value: config.apiKeyLocation,
            options: const ['header', 'query'],
            onChanged: (val) {
              final upd = config.copyWith(apiKeyLocation: val ?? 'header');
              setState(() => _selectedConfig = upd);
              notifier.updateConfig(config.id, upd);
            },
          ),
        ] else if (config.authentication == 'OAuth2') ...[
          _buildTextField(
            label: "Token URL",
            value: config.oauthTokenUrl,
            onChanged: (val) {
              final upd = config.copyWith(oauthTokenUrl: val);
              setState(() => _selectedConfig = upd);
              notifier.updateConfig(config.id, upd);
            },
          ),
          _buildTextField(
            label: "Client ID",
            value: config.oauthClientId,
            onChanged: (val) {
              final upd = config.copyWith(oauthClientId: val);
              setState(() => _selectedConfig = upd);
              notifier.updateConfig(config.id, upd);
            },
          ),
          _buildTextField(
            label: "Client Secret",
            value: config.oauthClientSecret,
            onChanged: (val) {
              final upd = config.copyWith(oauthClientSecret: val);
              setState(() => _selectedConfig = upd);
              notifier.updateConfig(config.id, upd);
            },
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildJsonBodyEditor(ApiConfig config, ApiConfigsNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              "Request Body (JSON)",
              style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                try {
                  final decoded = json.decode(config.requestBody);
                  final pretty = const JsonEncoder.withIndent('  ').convert(decoded);
                  final upd = config.copyWith(requestBody: pretty);
                  setState(() => _selectedConfig = upd);
                  notifier.updateConfig(config.id, upd);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('JSON beautified successfully.')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid JSON formatting: $e'), backgroundColor: Colors.red));
                }
              },
              child: const Text('Beautify', style: TextStyle(fontSize: 10)),
            ),
            TextButton(
              onPressed: () {
                try {
                  json.decode(config.requestBody);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('JSON is completely valid!'), backgroundColor: Colors.green));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid JSON syntax: $e'), backgroundColor: Colors.red));
                }
              },
              child: const Text('Validate', style: TextStyle(fontSize: 10)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          key: ValueKey('${config.id}_body'),
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
    );
  }

  Widget _buildMockingPanel(ApiConfig config, ApiConfigsNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.05),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.circle_notifications_outlined, size: 14, color: Colors.amber),
              const SizedBox(width: 6),
              Text("API Mocking Options", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary)),
              const Spacer(),
              Switch(
                value: config.isMockEnabled,
                onChanged: (v) {
                  final upd = config.copyWith(isMockEnabled: v);
                  setState(() => _selectedConfig = upd);
                  notifier.updateConfig(config.id, upd);
                },
              ),
            ],
          ),
          if (config.isMockEnabled) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text("Mock Delay: ", style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary)),
                const SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    value: config.mockDelay.toDouble().clamp(0.0, 10.0),
                    min: 0.0, max: 10.0,
                    divisions: 10,
                    label: '${config.mockDelay}s',
                    onChanged: (val) {
                      final upd = config.copyWith(mockDelay: val.toInt());
                      setState(() => _selectedConfig = upd);
                      notifier.updateConfig(config.id, upd);
                    },
                  ),
                ),
                Text('${config.mockDelay}s', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 6),
            _buildTextField(
              label: "Mock Response (JSON Body)",
              value: config.mockResponse,
              onChanged: (val) {
                final upd = config.copyWith(mockResponse: val);
                setState(() => _selectedConfig = upd);
                notifier.updateConfig(config.id, upd);
              },
            ),
            _buildTextField(
              label: "Mock Error Message (Trigger Failure)",
              value: config.mockError,
              onChanged: (val) {
                final upd = config.copyWith(mockError: val);
                setState(() => _selectedConfig = upd);
                notifier.updateConfig(config.id, upd);
              },
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(apiConfigsProvider);
    final notifier = ref.read(apiConfigsProvider.notifier);

    if (_selectedConfig != null) {
      final config = _selectedConfig!;
      return RevoStudioPanelWrapper(
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
              label: "Collection Group / Folder",
              value: config.group,
              onChanged: (val) {
                final upd = config.copyWith(group: val);
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
              options: const ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
              onChanged: (val) {
                final upd = config.copyWith(method: val);
                setState(() => _selectedConfig = upd);
                notifier.updateConfig(config.id, upd);
              },
            ),
            const Divider(),
            _buildAuthPanel(config, notifier),
            const Divider(),
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
              _buildJsonBodyEditor(config, notifier),
            ],
            const SizedBox(height: 8),
            _buildMockingPanel(config, notifier),
            const Divider(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => _testApi(config),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[700]),
                  child: const Text("Test Endpoint", style: TextStyle(fontSize: 11, color: Colors.white)),
                ),
                ElevatedButton(
                  onPressed: () {
                    _showSnippetDialog(
                      "Recursive Response Model",
                      _generateResponseModel(config, _responseBody),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B4FCF)),
                  child: const Text("Gen Model", style: TextStyle(fontSize: 11, color: Colors.white)),
                ),
                ElevatedButton(
                  onPressed: () {
                    _showSnippetDialog(
                      "cURL Request Command",
                      _generateCurl(config),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                  child: const Text("Gen cURL", style: TextStyle(fontSize: 11, color: Colors.white)),
                ),
                ElevatedButton(
                  onPressed: () {
                    _showSnippetDialog(
                      "Dio Clean Architecture Generator",
                      '${_generateDioCode(config)}\n${_generateCleanArchitecture(config)}',
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                  child: const Text("Gen Architecture", style: TextStyle(fontSize: 11, color: Colors.white)),
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
      );
    }

    // Grouping list view into Folders
    final Map<String, List<ApiConfig>> groupedApis = {};
    for (final api in list) {
      final grp = api.group.isEmpty ? 'General' : api.group;
      groupedApis.putIfAbsent(grp, () => []).add(api);
    }

    return SizedBox(
      width: 300,
      child: Column(
        children: [
          _buildEnvSelector(),
          Expanded(
            child: RevoStudioPanelWrapper(
              title: "API Studio",
              subtitle: "Configure REST APIs & collections",
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
                      group: 'Users',
                    );
                    notifier.addConfig(newApi);
                    setState(() => _selectedConfig = newApi);
                  },
                ),
              ],
              child: ListView(
                padding: const EdgeInsets.all(8),
                children: groupedApis.entries.map((groupEntry) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ExpansionTile(
                      title: Text(groupEntry.key, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: RevoTheme.primary)),
                      leading: const Icon(Icons.folder_open_rounded, size: 16, color: Colors.amber),
                      initiallyExpanded: true,
                      children: groupEntry.value.map((api) {
                        return ListTile(
                          onTap: () => setState(() => _selectedConfig = api),
                          leading: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                          title: Text(api.name, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                          subtitle: Text(api.endpoint, style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary), overflow: TextOverflow.ellipsis),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                            onPressed: () => notifier.deleteConfig(api.id),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
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
