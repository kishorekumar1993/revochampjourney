import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/features/journey_builder/domain/entities/journey_models.dart';
import 'package:revojourneytryone/features/journey_builder/application/controllers/journey_controller.dart';
import 'package:revojourneytryone/features/journey_builder/presentation/widgets/properties_panel/property_fields.dart';
import 'package:revojourneytryone/features/journey_builder/presentation/widgets/properties_panel/sections/component_config_helper.dart';
import 'data_component_helper.dart';

class TableGridProperties extends ConsumerStatefulWidget {
  final JourneyField field;
  final String activeStepId;

  const TableGridProperties({
    super.key,
    required this.field,
    required this.activeStepId,
  });

  @override
  ConsumerState<TableGridProperties> createState() => _TableGridPropertiesState();
}

class _TableGridPropertiesState extends ConsumerState<TableGridProperties> {
  bool _showDataComponentSettings = true;

  void _submitGridApiConfig(WidgetRef ref, BuildContext context, JourneyField field, String activeStepId) {
    final config = field.componentConfig ?? {};
    final updatedConfig = {...config, 'dataSource': 'api'};
    final updated = field.copyWith()..componentConfig = updatedConfig;
    ref.read(journeyConfigProvider.notifier).updateFieldInStep(activeStepId, field.id, updated);
    
    ref.read(gridApiTestProvider.notifier).setSuccess(
      "Grid API config submitted and saved for code generation.",
      [],
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Grid API config for '${field.label}' submitted."), backgroundColor: RevoTheme.secondary),
    );
  }

  Widget _numberConfigField(JourneyField field, String activeStepId, Map<String, dynamic> config, String key, String label, int fallback) {
    return PropertyTextField(
      label: label,
      initialValue: intConfig(config, key, fallback).toString(),
      onChanged: (val) => updateComponentConfig(ref, field, activeStepId, key, int.tryParse(val.trim()) ?? fallback),
    );
  }

  @override
  Widget build(BuildContext context) {
    final field = widget.field;
    final activeStepId = widget.activeStepId;
    final config = getComponentConfig(field);
    final apiState = ref.watch(gridApiTestProvider);

    final columns = (config['columns'] as List? ?? [])
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
              label: const Text("Add Column", style: TextStyle(fontFamily: 'Inter', fontSize: 10)),
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
                  onPressed: apiState.testing ? null : () => DataComponentHelper.testGridApiConnection(ref, field, activeStepId),
                  icon: apiState.testing
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
                  onPressed: () => _submitGridApiConfig(ref, context, field, activeStepId),
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 14),
                  label: const Text("Submit Config", style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          if (apiState.result != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: apiState.success ? Colors.greenAccent.withValues(alpha: 0.08) : Colors.redAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: apiState.success ? Colors.greenAccent.withValues(alpha: 0.25) : Colors.redAccent.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    apiState.result!,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: apiState.success ? Colors.greenAccent : Colors.redAccent),
                  ),
                  if (apiState.success && apiState.previewRows != null && apiState.previewRows!.isNotEmpty) ...[
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
                        json.encode(apiState.previewRows),
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
}
