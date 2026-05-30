import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/features/journey_builder/domain/entities/journey_models.dart';
import 'package:revojourneytryone/features/journey_builder/application/controllers/journey_controller.dart';
import '../property_fields.dart';
import 'component_config_helper.dart';

class DataComponentSection extends ConsumerStatefulWidget {
  final JourneyField field;
  final String activeStepId;

  const DataComponentSection({
    super.key,
    required this.field,
    required this.activeStepId,
  });

  @override
  ConsumerState<DataComponentSection> createState() => _DataComponentSectionState();
}

class _DataComponentSectionState extends ConsumerState<DataComponentSection> {
  bool _showDataComponentSettings = true;

  // Grid API test states
  bool _testingGridApi = false;
  String? _gridApiTestResult;
  bool _gridApiTestSuccess = false;
  List<Map<String, dynamic>>? _gridApiPreviewRows;

  Future<void> _testGridApiConnection(JourneyField field, String activeStepId) async {
    final config = field.componentConfig ?? {};
    final urlText = config['gridApiUrl']?.toString().trim() ?? '';
    if (urlText.isEmpty) {
      setState(() {
        _gridApiTestSuccess = false;
        _gridApiTestResult = "Error: Grid API URL is required.";
      });
      return;
    }

    setState(() {
      _testingGridApi = true;
      _gridApiTestResult = null;
      _gridApiPreviewRows = null;
    });

    try {
      final uri = _gridApiUri(urlText, config);
      final method = (config['gridApiMethod']?.toString() ?? 'GET').toUpperCase();
      final headers = _gridApiHeaders(config['gridApiHeaders']);
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

      if (!mounted) return;

      if (response.statusCode < 200 || response.statusCode >= 300) {
        setState(() {
          _testingGridApi = false;
          _gridApiTestSuccess = false;
          _gridApiTestResult = "HTTP Error: Status ${response.statusCode}\nResponse: ${response.body}";
        });
        return;
      }

      final decoded = json.decode(response.body);
      final rows = _extractGridRows(decoded, config['gridApiListKey']?.toString() ?? '');
      final updatedConfig = {
        ...config,
        'gridApiSampleData': rows,
        'dataSource': 'api',
      };
      final updated = field.copyWith()..componentConfig = updatedConfig;
      ref.read(journeyConfigProvider.notifier).updateFieldInStep(activeStepId, field.id, updated);

      setState(() {
        _testingGridApi = false;
        _gridApiTestSuccess = true;
        _gridApiTestResult = "Connection successful!\nStatus: ${response.statusCode}\nParsed ${rows.length} grid row(s) and saved sample data.";
        _gridApiPreviewRows = rows.take(2).toList();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _testingGridApi = false;
        _gridApiTestSuccess = false;
        _gridApiTestResult = "Grid API test failed: ${e.toString()}";
      });
    }
  }

  void _submitGridApiConfig(JourneyField field, String activeStepId) {
    final config = field.componentConfig ?? {};
    final updatedConfig = {...config, 'dataSource': 'api'};
    final updated = field.copyWith()..componentConfig = updatedConfig;
    ref.read(journeyConfigProvider.notifier).updateFieldInStep(activeStepId, field.id, updated);
    setState(() {
      _gridApiTestSuccess = true;
      _gridApiTestResult = "Grid API config submitted and saved for code generation.";
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Grid API config for '${field.label}' submitted."), backgroundColor: RevoTheme.secondary),
    );
  }

  Uri _gridApiUri(String urlText, Map<String, dynamic> config) {
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

  Map<String, String> _gridApiHeaders(dynamic rawHeaders) {
    final headers = <String, String>{};
    if (rawHeaders is Map) {
      rawHeaders.forEach((key, value) => headers[key.toString()] = value.toString());
    }
    return headers;
  }

  List<Map<String, dynamic>> _extractGridRows(dynamic decoded, String listKey) {
    dynamic source = decoded;
    if (decoded is Map && listKey.trim().isNotEmpty) {
      source = _readJsonPath(decoded, listKey) ?? decoded[listKey];
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

  dynamic _readJsonPath(dynamic source, String path) {
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

  Widget _textConfigField(JourneyField field, String activeStepId, Map<String, dynamic> config, String key, String label, {String? fallback}) {
    return PropertyTextField(
      label: label,
      initialValue: config[key]?.toString() ?? fallback ?? '',
      onChanged: (val) {
        updateComponentConfig(ref, field, activeStepId, key, val.trim());
      },
    );
  }

  Widget _numberConfigField(JourneyField field, String activeStepId, Map<String, dynamic> config, String key, String label, int fallback) {
    return PropertyTextField(
      label: label,
      initialValue: intConfig(config, key, fallback).toString(),
      onChanged: (val) => updateComponentConfig(ref, field, activeStepId, key, int.tryParse(val.trim()) ?? fallback),
    );
  }

  Widget _buildTableGridProperties(JourneyField field, String activeStepId) {
    final config = getComponentConfig(field);
    final columns = (config['columns'] as List)
        .map((item) => item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{})
        .where((item) => item.isNotEmpty)
        .toList();

    return CollapsibleSection(
      title: "Table / Grid Properties",
      accentColor: RevoTheme.accent,
      icon: Icons.table_chart_outlined,
      isExpanded: _showDataComponentSettings,
      onToggle: () => setState(() => _showDataComponentSettings = !_showDataComponentSettings),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Columns", style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary)),
            TextButton.icon(
              onPressed: () {
                final updatedColumns = List<Map<String, dynamic>>.from(columns);
                final next = updatedColumns.length + 1;
                updatedColumns.add({
                  'label': 'Column $next',
                  'fieldId': 'column$next',
                  'type': 'text',
                  'required': false,
                  'sortable': true,
                  'filterable': true,
                  'sticky': false,
                });
                updateComponentConfig(ref, field, activeStepId, 'columns', updatedColumns);
              },
              icon: const Icon(Icons.add_rounded, size: 14),
              label: Text("Add Column", style: TextStyle(fontFamily: 'Inter', fontSize: 10)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...columns.asMap().entries.map((entry) {
          final index = entry.key;
          final column = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: RevoTheme.sidebarBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: RevoTheme.cardBorder),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: PropertyTextField(
                        label: "Label",
                        initialValue: column['label']?.toString() ?? '',
                        onChanged: (val) {
                          final updatedColumns = List<Map<String, dynamic>>.from(columns);
                          updatedColumns[index] = {...column, 'label': val.trim()};
                          updateComponentConfig(ref, field, activeStepId, 'columns', updatedColumns);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: PropertyTextField(
                        label: "Field ID",
                        initialValue: column['fieldId']?.toString() ?? '',
                        onChanged: (val) {
                          final updatedColumns = List<Map<String, dynamic>>.from(columns);
                          updatedColumns[index] = {...column, 'fieldId': val.trim()};
                          updateComponentConfig(ref, field, activeStepId, 'columns', updatedColumns);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: PropertyDropdownField(
                        label: "Type",
                        currentValue: column['type']?.toString() ?? 'text',
                        items: const ['text', 'number', 'dropdown', 'date', 'checkbox'],
                        onChanged: (val) {
                          final updatedColumns = List<Map<String, dynamic>>.from(columns);
                          updatedColumns[index] = {...column, 'type': val};
                          updateComponentConfig(ref, field, activeStepId, 'columns', updatedColumns);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CompactSwitchTile(
                        label: "Required",
                        value: column['required'] == true,
                        onChanged: (val) {
                          final updatedColumns = List<Map<String, dynamic>>.from(columns);
                          updatedColumns[index] = {...column, 'required': val};
                          updateComponentConfig(ref, field, activeStepId, 'columns', updatedColumns);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CompactSwitchTile(
                        label: "Sticky",
                        value: column['sticky'] == true,
                        onChanged: (val) {
                          final updatedColumns = List<Map<String, dynamic>>.from(columns);
                          updatedColumns[index] = {...column, 'sticky': val};
                          updateComponentConfig(ref, field, activeStepId, 'columns', updatedColumns);
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                      onPressed: columns.length <= 1
                          ? null
                          : () {
                              final updatedColumns = List<Map<String, dynamic>>.from(columns)..removeAt(index);
                              updateComponentConfig(ref, field, activeStepId, 'columns', updatedColumns);
                            },
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 6),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 2.8,
          children: [
            CompactSwitchTile(label: "Allow Add", value: boolConfig(config, 'allowAddRow', true), onChanged: (val) => updateComponentConfig(ref, field, activeStepId, 'allowAddRow', val)),
            CompactSwitchTile(label: "Inline Edit", value: boolConfig(config, 'inlineEdit', true), onChanged: (val) => updateComponentConfig(ref, field, activeStepId, 'inlineEdit', val)),
            CompactSwitchTile(label: "Allow Delete", value: boolConfig(config, 'allowDeleteRow', true), onChanged: (val) => updateComponentConfig(ref, field, activeStepId, 'allowDeleteRow', val)),
            CompactSwitchTile(label: "Bulk Select", value: boolConfig(config, 'bulkSelection', true), onChanged: (val) => updateComponentConfig(ref, field, activeStepId, 'bulkSelection', val)),
            CompactSwitchTile(label: "Export CSV", value: boolConfig(config, 'exportCsv', true), onChanged: (val) => updateComponentConfig(ref, field, activeStepId, 'exportCsv', val)),
            CompactSwitchTile(label: "Search", value: boolConfig(config, 'search', true), onChanged: (val) => updateComponentConfig(ref, field, activeStepId, 'search', val)),
            CompactSwitchTile(label: "Sorting", value: boolConfig(config, 'sorting', true), onChanged: (val) => updateComponentConfig(ref, field, activeStepId, 'sorting', val)),
            CompactSwitchTile(label: "Filtering", value: boolConfig(config, 'filtering', true), onChanged: (val) => updateComponentConfig(ref, field, activeStepId, 'filtering', val)),
            CompactSwitchTile(label: "Sticky Columns", value: boolConfig(config, 'stickyColumns', true), onChanged: (val) => updateComponentConfig(ref, field, activeStepId, 'stickyColumns', val)),
            CompactSwitchTile(label: "Pagination", value: boolConfig(config, 'pagination', true), onChanged: (val) => updateComponentConfig(ref, field, activeStepId, 'pagination', val)),
            CompactSwitchTile(label: "API Pagination", value: boolConfig(config, 'apiPagination', false), onChanged: (val) => updateComponentConfig(ref, field, activeStepId, 'apiPagination', val)),
            CompactSwitchTile(label: "Row Validation", value: boolConfig(config, 'dynamicRowValidation', true), onChanged: (val) => updateComponentConfig(ref, field, activeStepId, 'dynamicRowValidation', val)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _numberConfigField(field, activeStepId, config, 'minRows', 'Min Rows', 0)),
            const SizedBox(width: 8),
            Expanded(child: _numberConfigField(field, activeStepId, config, 'maxRows', 'Max Rows', 10)),
            const SizedBox(width: 8),
            Expanded(child: _numberConfigField(field, activeStepId, config, 'rowsPerPage', 'Rows/Page', 10)),
          ],
        ),
        const SizedBox(height: 10),
        PropertyTextField(
          label: "Row Actions",
          initialValue: (config['rowActions'] is List ? (config['rowActions'] as List).join(', ') : config['rowActions']?.toString()) ?? '',
          hint: "view, edit, delete, duplicate",
          onChanged: (val) {
            final actions = val
                .split(',')
                .map((item) => item.trim())
                .where((item) => item.isNotEmpty)
                .toList();
            updateComponentConfig(ref, field, activeStepId, 'rowActions', actions);
          },
        ),
        const SizedBox(height: 10),
        PropertyDropdownField(
          label: "Data Source",
          currentValue: config['dataSource']?.toString() ?? 'manual',
          items: const ['manual', 'api'],
          onChanged: (val) => updateComponentConfig(ref, field, activeStepId, 'dataSource', val),
        ),
        if ((config['dataSource']?.toString() ?? 'manual') == 'api') ...[
          const SizedBox(height: 10),
          PropertyTextField(
            label: "Grid API URL",
            initialValue: config['gridApiUrl']?.toString() ?? '',
            hint: "https://api.example.com/users",
            onChanged: (val) => updateComponentConfig(ref, field, activeStepId, 'gridApiUrl', val.trim()),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: PropertyDropdownField(
                  label: "Grid API Method",
                  currentValue: config['gridApiMethod']?.toString() ?? 'GET',
                  items: const ['GET', 'POST', 'PUT', 'DELETE'],
                  onChanged: (val) => updateComponentConfig(ref, field, activeStepId, 'gridApiMethod', val),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PropertyTextField(
                  label: "Response List Key",
                  initialValue: config['gridApiListKey']?.toString() ?? '',
                  hint: "data.items",
                  onChanged: (val) => updateComponentConfig(ref, field, activeStepId, 'gridApiListKey', val.trim()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          PropertyTextField(
            label: "Grid API Headers (JSON)",
            initialValue: config['gridApiHeaders'] == null || (config['gridApiHeaders'] is Map && (config['gridApiHeaders'] as Map).isEmpty)
                ? ''
                : json.encode(config['gridApiHeaders']),
            hint: '{"Authorization": "Bearer token"}',
            maxLines: 3,
            onChanged: (val) {
              try {
                final decoded = val.trim().isEmpty ? <String, dynamic>{} : json.decode(val);
                if (decoded is Map) {
                  updateComponentConfig(ref, field, activeStepId, 'gridApiHeaders', Map<String, dynamic>.from(decoded));
                }
              } catch (_) {}
            },
          ),
          const SizedBox(height: 10),
          PropertyTextField(
            label: "Grid API Body (JSON)",
            initialValue: config['gridApiBody']?.toString() ?? '',
            hint: '{"status": "active"}',
            maxLines: 3,
            onChanged: (val) => updateComponentConfig(ref, field, activeStepId, 'gridApiBody', val.trim()),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RevoTheme.cardBg,
                    foregroundColor: RevoTheme.textPrimary,
                    side: BorderSide(color: RevoTheme.primaryLight.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _testingGridApi ? null : () => _testGridApiConnection(field, activeStepId),
                  icon: _testingGridApi
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.bolt_rounded, size: 14),
                  label: const Text("Test Connection", style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RevoTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => _submitGridApiConfig(field, activeStepId),
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 14),
                  label: const Text("Submit Config", style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          if (_gridApiTestResult != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _gridApiTestSuccess ? Colors.greenAccent.withValues(alpha: 0.08) : Colors.redAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _gridApiTestSuccess ? Colors.greenAccent.withValues(alpha: 0.25) : Colors.redAccent.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _gridApiTestResult!,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: _gridApiTestSuccess ? Colors.greenAccent : Colors.redAccent),
                  ),
                  if (_gridApiTestSuccess && _gridApiPreviewRows != null && _gridApiPreviewRows!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    const Text(
                      "Sample Row Preview:",
                      style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: RevoTheme.background,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        json.encode(_gridApiPreviewRows),
                        style: TextStyle(fontFamily: 'Source Code Pro', fontSize: 9, color: Colors.greenAccent.withValues(alpha: 0.8)),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: PropertyTextField(
                label: "API Page Param",
                initialValue: config['apiPageParam']?.toString() ?? 'page',
                onChanged: (val) => updateComponentConfig(ref, field, activeStepId, 'apiPageParam', val.trim()),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PropertyTextField(
                label: "API Size Param",
                initialValue: config['apiPageSizeParam']?.toString() ?? 'limit',
                onChanged: (val) => updateComponentConfig(ref, field, activeStepId, 'apiPageSizeParam', val.trim()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRepeaterProperties(JourneyField field, String activeStepId) {
    final config = getComponentConfig(field);
    final fields = (config['fields'] as List)
        .map((item) => item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{})
        .where((item) => item.isNotEmpty)
        .toList();
    return CollapsibleSection(
      title: "Repeater Properties",
      accentColor: RevoTheme.accent,
      icon: Icons.view_week_outlined,
      isExpanded: _showDataComponentSettings,
      onToggle: () => setState(() => _showDataComponentSettings = !_showDataComponentSettings),
      children: [
        Row(
          children: [
            Expanded(child: _textConfigField(field, activeStepId, config, 'itemLabel', 'Item Label')),
            const SizedBox(width: 8),
            Expanded(child: _textConfigField(field, activeStepId, config, 'addButtonLabel', 'Add Button')),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _numberConfigField(field, activeStepId, config, 'minItems', 'Min Items', 0)),
            const SizedBox(width: 8),
            Expanded(child: _numberConfigField(field, activeStepId, config, 'maxItems', 'Max Items', 5)),
          ],
        ),
        const SizedBox(height: 10),
        PropertyDropdownField(
          label: "Layout",
          currentValue: config['layout']?.toString() ?? 'singleColumn',
          items: const ['singleColumn', 'twoColumn', 'compact', 'cardList'],
          onChanged: (val) => updateComponentConfig(ref, field, activeStepId, 'layout', val),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Repeated Fields", style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary)),
            TextButton.icon(
              onPressed: () {
                final updatedFields = List<Map<String, dynamic>>.from(fields);
                final next = updatedFields.length + 1;
                updatedFields.add({'label': 'Field $next', 'fieldId': 'field$next', 'type': 'text', 'required': false});
                updateComponentConfig(ref, field, activeStepId, 'fields', updatedFields);
              },
              icon: const Icon(Icons.add_rounded, size: 14),
              label: Text("Add Field", style: TextStyle(fontFamily: 'Inter', fontSize: 10)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...fields.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: RevoTheme.sidebarBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: RevoTheme.cardBorder),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: PropertyTextField(
                        label: "Label",
                        initialValue: item['label']?.toString() ?? '',
                        onChanged: (val) {
                          final updatedFields = List<Map<String, dynamic>>.from(fields);
                          updatedFields[index] = {...item, 'label': val.trim()};
                          updateComponentConfig(ref, field, activeStepId, 'fields', updatedFields);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: PropertyTextField(
                        label: "Field ID",
                        initialValue: item['fieldId']?.toString() ?? '',
                        onChanged: (val) {
                          final updatedFields = List<Map<String, dynamic>>.from(fields);
                          updatedFields[index] = {...item, 'fieldId': val.trim()};
                          updateComponentConfig(ref, field, activeStepId, 'fields', updatedFields);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: PropertyDropdownField(
                        label: "Type",
                        currentValue: item['type']?.toString() ?? 'text',
                        items: const ['text', 'number', 'dropdown', 'date', 'checkbox', 'file'],
                        onChanged: (val) {
                          final updatedFields = List<Map<String, dynamic>>.from(fields);
                          updatedFields[index] = {...item, 'type': val};
                          updateComponentConfig(ref, field, activeStepId, 'fields', updatedFields);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CompactSwitchTile(
                        label: "Required",
                        value: item['required'] == true,
                        onChanged: (val) {
                          final updatedFields = List<Map<String, dynamic>>.from(fields);
                          updatedFields[index] = {...item, 'required': val};
                          updateComponentConfig(ref, field, activeStepId, 'fields', updatedFields);
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                      onPressed: fields.length <= 1
                          ? null
                          : () {
                              final updatedFields = List<Map<String, dynamic>>.from(fields)..removeAt(index);
                              updateComponentConfig(ref, field, activeStepId, 'fields', updatedFields);
                            },
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 2.8,
          children: [
            CompactSwitchTile(label: "Allow Add", value: boolConfig(config, 'allowAdd', true), onChanged: (val) => updateComponentConfig(ref, field, activeStepId, 'allowAdd', val)),
            CompactSwitchTile(label: "Allow Remove", value: boolConfig(config, 'allowRemove', true), onChanged: (val) => updateComponentConfig(ref, field, activeStepId, 'allowRemove', val)),
            CompactSwitchTile(label: "Allow Reorder", value: boolConfig(config, 'allowReorder', true), onChanged: (val) => updateComponentConfig(ref, field, activeStepId, 'allowReorder', val)),
            CompactSwitchTile(label: "Show Index", value: boolConfig(config, 'showItemIndex', true), onChanged: (val) => updateComponentConfig(ref, field, activeStepId, 'showItemIndex', val)),
            CompactSwitchTile(label: "Collapsible", value: boolConfig(config, 'collapsibleItems', true), onChanged: (val) => updateComponentConfig(ref, field, activeStepId, 'collapsibleItems', val)),
          ],
        ),
      ],
    );
  }

  Widget _buildTimelineProperties(JourneyField field, String activeStepId) {
    final config = getComponentConfig(field);
    final items = (config['items'] as List)
        .map((item) => item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{})
        .where((item) => item.isNotEmpty)
        .toList();
    return CollapsibleSection(
      title: "Timeline Properties",
      accentColor: RevoTheme.accent,
      icon: Icons.format_list_bulleted_rounded,
      isExpanded: _showDataComponentSettings,
      onToggle: () => setState(() => _showDataComponentSettings = !_showDataComponentSettings),
      children: [
        Row(
          children: [
            Expanded(
              child: PropertyDropdownField(
                label: "Orientation",
                currentValue: config['orientation']?.toString() ?? 'vertical',
                items: const ['vertical', 'horizontal'],
                onChanged: (val) => updateComponentConfig(ref, field, activeStepId, 'orientation', val),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PropertyDropdownField(
                label: "Marker Style",
                currentValue: config['markerStyle']?.toString() ?? 'numbered',
                items: const ['numbered', 'dot', 'icon'],
                onChanged: (val) => updateComponentConfig(ref, field, activeStepId, 'markerStyle', val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: PropertyDropdownField(
                label: "Default Status",
                currentValue: config['defaultStatus']?.toString() ?? 'pending',
                items: const ['pending', 'active', 'completed', 'failed'],
                onChanged: (val) => updateComponentConfig(ref, field, activeStepId, 'defaultStatus', val),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PropertyDropdownField(
                label: "Items Source",
                currentValue: config['itemsSource']?.toString() ?? 'static',
                items: const ['static', 'api', 'journeySteps'],
                onChanged: (val) => updateComponentConfig(ref, field, activeStepId, 'itemsSource', val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _textConfigField(field, activeStepId, config, 'titleField', 'Title Key')),
            const SizedBox(width: 8),
            Expanded(child: _textConfigField(field, activeStepId, config, 'dateField', 'Date Key')),
            const SizedBox(width: 8),
            Expanded(child: _textConfigField(field, activeStepId, config, 'statusField', 'Status Key')),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Static Timeline Items", style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary)),
            TextButton.icon(
              onPressed: () {
                final updatedItems = List<Map<String, dynamic>>.from(items);
                final next = updatedItems.length + 1;
                updatedItems.add({'title': 'Step $next', 'description': 'Timeline item', 'status': 'pending'});
                updateComponentConfig(ref, field, activeStepId, 'items', updatedItems);
              },
              icon: const Icon(Icons.add_rounded, size: 14),
              label: Text("Add Item", style: TextStyle(fontFamily: 'Inter', fontSize: 10)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: RevoTheme.sidebarBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: RevoTheme.cardBorder),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: PropertyTextField(
                        label: "Title",
                        initialValue: item['title']?.toString() ?? '',
                        onChanged: (val) {
                          final updatedItems = List<Map<String, dynamic>>.from(items);
                          updatedItems[index] = {...item, 'title': val.trim()};
                          updateComponentConfig(ref, field, activeStepId, 'items', updatedItems);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: PropertyDropdownField(
                        label: "Status",
                        currentValue: item['status']?.toString() ?? 'pending',
                        items: const ['pending', 'active', 'completed', 'failed'],
                        onChanged: (val) {
                          final updatedItems = List<Map<String, dynamic>>.from(items);
                          updatedItems[index] = {...item, 'status': val};
                          updateComponentConfig(ref, field, activeStepId, 'items', updatedItems);
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                      onPressed: items.length <= 1
                          ? null
                          : () {
                              final updatedItems = List<Map<String, dynamic>>.from(items)..removeAt(index);
                              updateComponentConfig(ref, field, activeStepId, 'items', updatedItems);
                            },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                PropertyTextField(
                  label: "Description",
                  initialValue: item['description']?.toString() ?? '',
                  onChanged: (val) {
                    final updatedItems = List<Map<String, dynamic>>.from(items);
                    updatedItems[index] = {...item, 'description': val.trim()};
                    updateComponentConfig(ref, field, activeStepId, 'items', updatedItems);
                  },
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 2.8,
          children: [
            CompactSwitchTile(label: "Timestamp", value: boolConfig(config, 'showTimestamp', true), onChanged: (val) => updateComponentConfig(ref, field, activeStepId, 'showTimestamp', val)),
            CompactSwitchTile(label: "Connector", value: boolConfig(config, 'showConnector', true), onChanged: (val) => updateComponentConfig(ref, field, activeStepId, 'showConnector', val)),
            CompactSwitchTile(label: "Future Steps", value: boolConfig(config, 'allowFutureSteps', true), onChanged: (val) => updateComponentConfig(ref, field, activeStepId, 'allowFutureSteps', val)),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.field.type) {
      case 'table_grid':
        return _buildTableGridProperties(widget.field, widget.activeStepId);
      case 'repeater':
        return _buildRepeaterProperties(widget.field, widget.activeStepId);
      case 'timeline':
        return _buildTimelineProperties(widget.field, widget.activeStepId);
      default:
        return const SizedBox.shrink();
    }
  }
}
