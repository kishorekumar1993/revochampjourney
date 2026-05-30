import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/features/journey_builder/domain/entities/journey_models.dart';
import '../property_fields.dart';
import 'component_config_helper.dart';

class LayoutComponentSection extends ConsumerStatefulWidget {
  final JourneyField field;
  final String activeStepId;

  const LayoutComponentSection({
    super.key,
    required this.field,
    required this.activeStepId,
  });

  @override
  ConsumerState<LayoutComponentSection> createState() => _LayoutComponentSectionState();
}

class _LayoutComponentSectionState extends ConsumerState<LayoutComponentSection> {
  bool _showLayoutComponentSettings = true;

  Widget _textConfigField(
    JourneyField field,
    String activeStepId,
    Map<String, dynamic> config,
    String key,
    String label, {
    String? fallback,
  }) {
    return PropertyTextField(
      label: label,
      initialValue: config[key]?.toString() ?? fallback ?? '',
      onChanged: (val) {
        if (key == 'tabsCsv') {
          final tabs = val.split(',').map((item) => item.trim()).where((item) => item.isNotEmpty).toList();
          updateComponentConfig(ref, field, activeStepId, 'tabs', tabs);
        } else {
          updateComponentConfig(ref, field, activeStepId, key, val.trim());
        }
      },
    );
  }

  Widget _paddingConfigField(JourneyField field, String activeStepId, Map<String, dynamic> config) {
    return PropertyDropdownField(
      label: "Padding",
      currentValue: config['padding']?.toString() ?? 'medium',
      items: const ['none', 'small', 'medium', 'large'],
      onChanged: (val) => updateComponentConfig(ref, field, activeStepId, 'padding', val),
    );
  }

  Widget _layoutSwitches(JourneyField field, String activeStepId, Map<String, dynamic> config, List<String> keys) {
    String labelFor(String key) {
      switch (key) {
        case 'defaultExpanded':
          return 'Expanded';
        case 'showDivider':
          return 'Divider';
        case 'showHeader':
          return 'Header';
        case 'showFooter':
          return 'Footer';
        case 'persistActiveTab':
          return 'Persist Tab';
        case 'allowMultipleOpen':
          return 'Multi Open';
        default:
          return key.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(1)}').trim();
      }
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 2.8,
      children: keys
          .map(
            (key) => CompactSwitchTile(
              label: labelFor(key),
              value: boolConfig(config, key, false),
              onChanged: (val) => updateComponentConfig(ref, field, activeStepId, key, val),
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = getComponentConfig(widget.field);
    return CollapsibleSection(
      title: "Layout Properties",
      accentColor: RevoTheme.primaryLight,
      icon: Icons.dashboard_customize_outlined,
      isExpanded: _showLayoutComponentSettings,
      onToggle: () => setState(() => _showLayoutComponentSettings = !_showLayoutComponentSettings),
      children: [
        if (widget.field.type == 'section') ...[
          Row(
            children: [
              Expanded(
                child: PropertyDropdownField(
                  label: "Heading Level",
                  currentValue: config['headingLevel']?.toString() ?? 'H2',
                  items: const ['H1', 'H2', 'H3', 'H4'],
                  onChanged: (val) => updateComponentConfig(ref, widget.field, widget.activeStepId, 'headingLevel', val),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: _paddingConfigField(widget.field, widget.activeStepId, config)),
            ],
          ),
          const SizedBox(height: 10),
          _layoutSwitches(widget.field, widget.activeStepId, config, const ['collapsible', 'defaultExpanded', 'showDivider']),
        ] else if (widget.field.type == 'card') ...[
          Row(
            children: [
              Expanded(
                child: PropertyDropdownField(
                  label: "Variant",
                  currentValue: config['variant']?.toString() ?? 'outlined',
                  items: const ['outlined', 'filled', 'elevated'],
                  onChanged: (val) => updateComponentConfig(ref, widget.field, widget.activeStepId, 'variant', val),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: _paddingConfigField(widget.field, widget.activeStepId, config)),
            ],
          ),
          const SizedBox(height: 10),
          _layoutSwitches(widget.field, widget.activeStepId, config, const ['showHeader', 'showFooter']),
        ] else if (widget.field.type == 'tabs') ...[
          Row(
            children: [
              Expanded(
                child: PropertyDropdownField(
                  label: "Variant",
                  currentValue: config['variant']?.toString() ?? 'underline',
                  items: const ['underline', 'boxed', 'pills'],
                  onChanged: (val) => updateComponentConfig(ref, widget.field, widget.activeStepId, 'variant', val),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PropertyDropdownField(
                  label: "Alignment",
                  currentValue: config['alignment']?.toString() ?? 'start',
                  items: const ['start', 'center', 'end'],
                  onChanged: (val) => updateComponentConfig(ref, widget.field, widget.activeStepId, 'alignment', val),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _textConfigField(widget.field, widget.activeStepId, config, 'tabsCsv', 'Tabs CSV', fallback: (config['tabs'] as List?)?.join(', ') ?? 'Tab 1, Tab 2'),
          const SizedBox(height: 10),
          _layoutSwitches(widget.field, widget.activeStepId, config, const ['persistActiveTab']),
        ] else if (widget.field.type == 'accordion') ...[
          Row(
            children: [
              Expanded(
                child: PropertyDropdownField(
                  label: "Variant",
                  currentValue: config['variant']?.toString() ?? 'bordered',
                  items: const ['bordered', 'filled', 'plain'],
                  onChanged: (val) => updateComponentConfig(ref, widget.field, widget.activeStepId, 'variant', val),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PropertyDropdownField(
                  label: "Icon Position",
                  currentValue: config['iconPosition']?.toString() ?? 'right',
                  items: const ['left', 'right'],
                  onChanged: (val) => updateComponentConfig(ref, widget.field, widget.activeStepId, 'iconPosition', val),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _layoutSwitches(widget.field, widget.activeStepId, config, const ['allowMultipleOpen', 'defaultExpanded']),
        ],
      ],
    );
  }
}
