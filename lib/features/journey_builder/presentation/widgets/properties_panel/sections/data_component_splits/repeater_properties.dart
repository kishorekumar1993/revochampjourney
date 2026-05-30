import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/features/journey_builder/domain/entities/journey_models.dart';
import 'package:revojourneytryone/features/journey_builder/presentation/widgets/properties_panel/property_fields.dart';
import 'package:revojourneytryone/features/journey_builder/presentation/widgets/properties_panel/sections/component_config_helper.dart';

class RepeaterProperties extends ConsumerStatefulWidget {
  final JourneyField field;
  final String activeStepId;

  const RepeaterProperties({
    super.key,
    required this.field,
    required this.activeStepId,
  });

  @override
  ConsumerState<RepeaterProperties> createState() => _RepeaterPropertiesState();
}

class _RepeaterPropertiesState extends ConsumerState<RepeaterProperties> {
  bool _showDataComponentSettings = true;

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

  @override
  Widget build(BuildContext context) {
    final field = widget.field;
    final activeStepId = widget.activeStepId;
    final config = getComponentConfig(field);

    final fields = (config['fields'] as List? ?? [])
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
              label: const Text("Add Field", style: TextStyle(fontFamily: 'Inter', fontSize: 10)),
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
}
