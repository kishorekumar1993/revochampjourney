import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/core/component_engine/models/api_config.dart';
import 'package:revojourneytryone/features/visual_builder/application/studio_providers.dart';
import 'studio_panel_wrapper.dart';
import 'api_panel/widgets/code_gen_dialog.dart';
import 'api_panel/widgets/env_selector.dart';
import 'api_panel/widgets/collection_folders.dart';
import 'api_panel/widgets/api_address_bar.dart';
import 'api_panel/widgets/auth_manager.dart';
import 'api_panel/widgets/json_body_editor.dart';
import 'api_panel/widgets/mocking_panel.dart';
import 'api_panel/widgets/response_preview.dart';

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

  // Environment and folder defaults substitution helper
  String _substituteVariables(String input, ApiConfig config) {
    final activeEnv = ref.read(activeEnvironmentProvider);
    final envVars = ref.read(envVariablesProvider)[activeEnv] ?? {};
    var result = input;

    // 1. Substitute Environment Variables
    envVars.forEach((key, val) {
      result = result.replaceAll('{{$key}}', val);
      result = result.replaceAll('{$key}', val);
    });

    // 2. Substitute App/Session Variables
    final appVars = ref.read(appVariablesProvider);
    for (final v in appVars) {
      result = result.replaceAll('{{${v.name}}}', v.currentValue?.toString() ?? '');
      result = result.replaceAll('{${v.name}}', v.currentValue?.toString() ?? '');
    }
    return result;
  }

  // Resolve headers dynamically, supporting folder inheritance
  Map<String, String> _resolveHeaders(ApiConfig config) {
    final Map<String, String> resolved = {};

    // 1. Inherit from collection if enabled
    if (config.inheritParentSettings && config.collectionId.isNotEmpty) {
      final collections = ref.read(apiCollectionsProvider);
      final parent = collections.firstWhere((c) => c.id == config.collectionId, orElse: () => ApiCollection(id: '', name: ''));
      if (parent.id.isNotEmpty) {
        resolved.addAll(parent.headers);
      }
    }

    // 2. Local headers override
    resolved.addAll(config.headers);
    return resolved;
  }

  // Resolve base URL dynamically, supporting folder inheritance
  String _resolveBaseUrl(ApiConfig config) {
    if (config.inheritParentSettings && config.collectionId.isNotEmpty) {
      final collections = ref.read(apiCollectionsProvider);
      final parent = collections.firstWhere((c) => c.id == config.collectionId, orElse: () => ApiCollection(id: '', name: ''));
      if (parent.id.isNotEmpty && parent.baseUrl.isNotEmpty) {
        return parent.baseUrl;
      }
    }
    return config.baseUrl;
  }

  // Resolve authentication dynamically, supporting folder inheritance
  String _resolveAuth(ApiConfig config, {required String field}) {
    String authType = config.authentication;
    ApiCollection? parent;

    if (config.inheritParentSettings && config.collectionId.isNotEmpty) {
      final collections = ref.read(apiCollectionsProvider);
      parent = collections.firstWhere((c) => c.id == config.collectionId, orElse: () => ApiCollection(id: '', name: ''));
      if (parent.id.isNotEmpty && authType == 'Inherit') {
        authType = parent.authentication;
      }
    }

    if (field == 'type') return authType;

    // Resolve username / password / api key details
    if (authType == parent?.authentication && parent != null) {
      if (field == 'username') return parent.authUsername;
      if (field == 'password') return parent.authPassword;
      if (field == 'keyName') return parent.apiKeyName;
      if (field == 'keyValue') return parent.apiKeyValue;
      if (field == 'keyLocation') return parent.apiKeyLocation;
    }

    if (field == 'username') return config.authUsername;
    if (field == 'password') return config.authPassword;
    if (field == 'keyName') return config.apiKeyName;
    if (field == 'keyValue') return config.apiKeyValue;
    if (field == 'keyLocation') return config.apiKeyLocation;

    return '';
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
      String urlStr = _substituteVariables(_resolveBaseUrl(config), config);
      String endpointStr = _substituteVariables(config.endpoint, config);

      if (!urlStr.endsWith('/') && !endpointStr.startsWith('/')) {
        urlStr += '/';
      }
      urlStr += endpointStr;

      final uri = Uri.parse(urlStr);
      final queryParams = Map<String, String>.from(uri.queryParameters);
      config.queryParams.forEach((key, val) {
        queryParams[key] = _substituteVariables(val, config);
      });

      final finalUri = uri.replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final headers = <String, String>{};
      _resolveHeaders(config).forEach((key, val) {
        headers[key] = _substituteVariables(val, config);
      });

      if (config.method != 'GET' && !headers.containsKey('Content-Type') && !headers.containsKey('content-type')) {
        headers['Content-Type'] = 'application/json';
      }

      // Authorization manager integration
      final authType = _resolveAuth(config, field: 'type');
      final authPass = _resolveAuth(config, field: 'password');
      final authUser = _resolveAuth(config, field: 'username');
      final apiKeyName = _resolveAuth(config, field: 'keyName');
      final apiKeyValue = _resolveAuth(config, field: 'keyValue');
      final apiKeyLocation = _resolveAuth(config, field: 'keyLocation');

      if (authType == 'Bearer Token' && authPass.isNotEmpty) {
        headers['Authorization'] = 'Bearer ${_substituteVariables(authPass, config)}';
      } else if (authType == 'Basic Auth') {
        final user = _substituteVariables(authUser, config);
        final pass = _substituteVariables(authPass, config);
        final creds = base64Encode(utf8.encode('$user:$pass'));
        headers['Authorization'] = 'Basic $creds';
      } else if (authType == 'API Key') {
        final name = _substituteVariables(apiKeyName, config);
        final val = _substituteVariables(apiKeyValue, config);
        if (name.isNotEmpty) {
          if (apiKeyLocation == 'query') {
            queryParams[name] = val;
          } else {
            headers[name] = val;
          }
        }
      } else if (authType == 'OAuth2') {
        headers['Authorization'] = 'Bearer simulated_oauth2_access_token';
      }

      http.Response response;
      final bodyStr = _substituteVariables(config.requestBody, config);

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

  void _showCodeGenDialog(ApiConfig config) {
    showDialog(
      context: context,
      builder: (ctx) => RevoCodeGenDialog(
        config: config,
        lastResponseBody: _responseBody,
        substituteEnvVars: (input) => _substituteVariables(input, config),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(apiConfigsProvider);
    final notifier = ref.read(apiConfigsProvider.notifier);

    if (_selectedConfig != null) {
      // Find current config from state to keep it updated on hot rebuilds
      final config = list.firstWhere((c) => c.id == _selectedConfig!.id, orElse: () => _selectedConfig!);

      return RevoStudioPanelWrapper(
        title: "Edit Request",
        subtitle: config.name,
        actions: [
          IconButton(
            icon: const Icon(Icons.code_rounded, size: 16),
            tooltip: "Developer Tools (Code Gen)",
            onPressed: () => _showCodeGenDialog(config),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            tooltip: "Back to Collections",
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
        child: Column(
          children: [
            const RevoEnvSelector(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                children: [
                  TextFormField(
                    initialValue: config.name,
                    key: ValueKey('${config.id}_name_field'),
                    onChanged: (val) {
                      final upd = config.copyWith(name: val);
                      notifier.updateConfig(config.id, upd);
                    },
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      labelText: "Request Name",
                      isDense: true,
                      contentPadding: EdgeInsets.all(8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Inherit collection variables",
                        style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary),
                      ),
                      Switch(
                        value: config.inheritParentSettings,
                        onChanged: (val) {
                          final upd = config.copyWith(inheritParentSettings: val);
                          notifier.updateConfig(config.id, upd);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  if (!config.inheritParentSettings) ...[
                    const SizedBox(height: 6),
                    TextFormField(
                      initialValue: config.baseUrl,
                      key: ValueKey('${config.id}_base_url_field'),
                      onChanged: (val) {
                        final upd = config.copyWith(baseUrl: val);
                        notifier.updateConfig(config.id, upd);
                      },
                      style: GoogleFonts.inter(fontSize: 11),
                      decoration: const InputDecoration(
                        labelText: "Manual Base URL Override",
                        isDense: true,
                        contentPadding: EdgeInsets.all(8),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  RevoApiAddressBar(
                    config: config,
                    isTesting: _isTesting,
                    onConfigUpdated: (upd) {
                      notifier.updateConfig(config.id, upd);
                    },
                    onSendPressed: () => _testApi(config),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  RevoAuthManager(
                    config: config,
                    onConfigUpdated: (upd) {
                      notifier.updateConfig(config.id, upd);
                    },
                  ),
                  const Divider(),
                  RevoMapEditor(
                    title: "Headers",
                    dataMap: config.headers,
                    onUpdated: (newMap) {
                      final upd = config.copyWith(headers: newMap);
                      notifier.updateConfig(config.id, upd);
                    },
                  ),
                  const Divider(),
                  RevoMapEditor(
                    title: "Query Parameters",
                    dataMap: config.queryParams,
                    onUpdated: (newMap) {
                      final upd = config.copyWith(queryParams: newMap);
                      notifier.updateConfig(config.id, upd);
                    },
                  ),
                  const Divider(),
                  if (config.method != 'GET') ...[
                    RevoJsonBodyEditor(
                      config: config,
                      onConfigUpdated: (upd) {
                        notifier.updateConfig(config.id, upd);
                      },
                    ),
                    const Divider(),
                  ],
                  RevoMockingPanel(
                    config: config,
                    onConfigUpdated: (upd) {
                      notifier.updateConfig(config.id, upd);
                    },
                  ),
                  const Divider(height: 24),
                  RevoResponsePreview(
                    isTesting: _isTesting,
                    testError: _testError,
                    responseStatus: _responseStatus,
                    responseBody: _responseBody,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: 300,
      child: Column(
        children: [
          const RevoEnvSelector(),
          Expanded(
            child: RevoStudioPanelWrapper(
              title: "API Studio",
              subtitle: "Configure REST collections & endpoints",
              child: RevoCollectionFolders(
                selectedConfig: _selectedConfig,
                onSelectedConfigChanged: (config) {
                  setState(() {
                    _selectedConfig = config;
                    _responseStatus = null;
                    _responseBody = null;
                    _testError = null;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Focus-Stable Local State Map Editor Widget ─────────────────────────────
class RevoMapEditor extends StatefulWidget {
  final String title;
  final Map<String, String> dataMap;
  final ValueChanged<Map<String, String>> onUpdated;

  const RevoMapEditor({
    super.key,
    required this.title,
    required this.dataMap,
    required this.onUpdated,
  });

  @override
  State<RevoMapEditor> createState() => _RevoMapEditorState();
}

class _RevoMapEditorState extends State<RevoMapEditor> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.title,
              style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary, fontWeight: FontWeight.w600),
            ),
            IconButton(
              icon: const Icon(Icons.add_rounded, size: 16, color: Color(0xFF5B4FCF)),
              onPressed: () {
                final updMap = Map<String, String>.from(widget.dataMap);
                int count = 1;
                final baseKey = widget.title.toLowerCase().contains('header') ? 'header' : 'param';
                while (updMap.containsKey('${baseKey}_$count')) {
                  count++;
                }
                updMap['${baseKey}_$count'] = 'value';
                widget.onUpdated(updMap);
              },
            ),
          ],
        ),
        if (widget.dataMap.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              "No ${widget.title.toLowerCase()} configured",
              style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary, fontStyle: FontStyle.italic),
            ),
          ),
        ...widget.dataMap.entries.map((entry) {
          return MapEntryRowEditor(
            key: ValueKey(entry.key),
            entryKey: entry.key,
            entryValue: entry.value,
            onChanged: (newKey, newVal) {
              final updMap = Map<String, String>.from(widget.dataMap);
              updMap.remove(entry.key);
              updMap[newKey] = newVal;
              widget.onUpdated(updMap);
            },
            onDelete: () {
              final updMap = Map<String, String>.from(widget.dataMap);
              updMap.remove(entry.key);
              widget.onUpdated(updMap);
            },
          );
        }),
        const SizedBox(height: 6),
      ],
    );
  }
}

// Sub-component row editor using focus nodes to avoid focus jumping
class MapEntryRowEditor extends StatefulWidget {
  final String entryKey;
  final String entryValue;
  final void Function(String key, String val) onChanged;
  final VoidCallback onDelete;

  const MapEntryRowEditor({
    super.key,
    required this.entryKey,
    required this.entryValue,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<MapEntryRowEditor> createState() => _MapEntryRowEditorState();
}

class _MapEntryRowEditorState extends State<MapEntryRowEditor> {
  late TextEditingController _keyController;
  late TextEditingController _valueController;
  late FocusNode _keyFocusNode;
  late FocusNode _valueFocusNode;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(text: widget.entryKey);
    _valueController = TextEditingController(text: widget.entryValue);
    _keyFocusNode = FocusNode();
    _valueFocusNode = FocusNode();

    // Notify parent only when focus is lost or typing is complete
    _keyFocusNode.addListener(_onFocusChange);
    _valueFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_keyFocusNode.hasFocus && !_valueFocusNode.hasFocus) {
      _triggerUpdate();
    }
  }

  void _triggerUpdate() {
    final finalKey = _keyController.text.trim();
    if (finalKey.isNotEmpty) {
      widget.onChanged(finalKey, _valueController.text);
    }
  }

  @override
  void dispose() {
    _keyFocusNode.removeListener(_onFocusChange);
    _valueFocusNode.removeListener(_onFocusChange);
    _keyController.dispose();
    _valueController.dispose();
    _keyFocusNode.dispose();
    _valueFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _keyController,
              focusNode: _keyFocusNode,
              onFieldSubmitted: (_) => _triggerUpdate(),
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
              controller: _valueController,
              focusNode: _valueFocusNode,
              onFieldSubmitted: (_) => _triggerUpdate(),
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
            onPressed: widget.onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
