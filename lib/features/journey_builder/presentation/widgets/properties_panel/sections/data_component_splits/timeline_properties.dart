import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/features/journey_builder/domain/entities/journey_models.dart';
import 'package:revojourneytryone/features/journey_builder/presentation/widgets/properties_panel/property_fields.dart';
import 'package:revojourneytryone/features/journey_builder/presentation/widgets/properties_panel/sections/component_config_helper.dart';

class TimelineProperties extends ConsumerStatefulWidget {
  final JourneyField field;
  final String activeStepId;

  const TimelineProperties({
    super.key,
    required this.field,
    required this.activeStepId,
  });

  @override
  ConsumerState<TimelineProperties> createState() => _TimelinePropertiesState();
}

class _TimelinePropertiesState extends ConsumerState<TimelineProperties> {
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

  @override
  Widget build(BuildContext context) {
    final field = widget.field;
    final activeStepId = widget.activeStepId;
    final config = getComponentConfig(field);

    final items = (config['items'] as List? ?? [])
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
              label: const Text("Add Item", style: TextStyle(fontFamily: 'Inter', fontSize: 10)),
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
}
