import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/features/journey_builder/domain/entities/journey_models.dart';
import 'package:revojourneytryone/features/journey_builder/application/controllers/journey_controller.dart';

import 'sections/json_config_section.dart';
import 'sections/general_settings_section.dart';
import 'sections/state_flags_section.dart';
import 'sections/validation_settings_section.dart';
import 'sections/enterprise_settings_section.dart';
import 'sections/data_component_section.dart';
import 'sections/layout_component_section.dart';
import 'sections/options_api_section.dart';

class RevoPropertiesPanel extends ConsumerStatefulWidget {
  const RevoPropertiesPanel({super.key});

  @override
  ConsumerState<RevoPropertiesPanel> createState() => _RevoPropertiesPanelState();
}

class _RevoPropertiesPanelState extends ConsumerState<RevoPropertiesPanel> {
  bool _showJsonConfig = false;
  bool _showGeneralSettings = true;
  bool _showStateFlags = false;
  bool _showValidations = false;
  bool _showEnterpriseSettings = false;

  bool _isDataComponent(String type) {
    return const {'table_grid', 'repeater', 'timeline'}.contains(type);
  }

  bool _isLayoutComponent(String type) {
    return const {'section', 'card', 'tabs', 'accordion'}.contains(type);
  }

  JourneyField? _findFieldById(List<JourneyField> fields, String? fieldId) {
    if (fieldId == null) return null;
    for (final field in fields) {
      if (field.id == fieldId) return field;
      final nested = field.nestedFields;
      if (nested != null && nested.isNotEmpty) {
        final match = _findFieldById(nested, fieldId);
        if (match != null) return match;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeModeProvider);
    final config = ref.watch(journeyConfigProvider);
    final activeStepId = ref.watch(activeStepIdProvider);
    final selectedFieldId = ref.watch(selectedFieldIdProvider);

    // Find the highlighted field in the active step
    JourneyField? selectedField;
    final stepIndex = config.steps.indexWhere((s) => s.id == activeStepId);
    if (stepIndex != -1) {
      final step = config.steps[stepIndex];
      selectedField = _findFieldById(step.fields, selectedFieldId);
    }

    final isRadioOrSelectionOrDivider = selectedField?.type == 'radio' ||
        selectedField?.type == 'checkbox' ||
        selectedField?.type == 'switch' ||
        selectedField?.type == 'divider';
    final supportsOptions = selectedField?.type == 'dropdown' ||
        selectedField?.type == 'api_dropdown' ||
        selectedField?.type == 'radio' ||
        selectedField?.type == 'multi_select';

    return Container(
      width: 340,
      decoration: BoxDecoration(
        color: RevoTheme.sidebarBackground,
        border: Border(
          left: BorderSide(color: RevoTheme.cardBorder, width: 1),
        ),
      ),
      child: Column(
        children: [
          // 1. JSON Configuration Segment (Collapsible)
          JsonConfigSection(
            isExpanded: _showJsonConfig,
            onToggle: () => setState(() => _showJsonConfig = !_showJsonConfig),
          ),
          if (_showJsonConfig)
            Divider(color: RevoTheme.cardBorder, height: 16),

          // 2. Component Properties Segment
          Expanded(
            flex: _showJsonConfig ? 5 : 1,
            child: selectedField == null
                ? Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit_note_rounded, size: 36, color: RevoTheme.textSecondary.withValues(alpha:0.5)),
                          const SizedBox(height: 12),
                          Text(
                            "Select a component from the canvas grid to start customizing its properties.",
                            style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: RevoTheme.textSecondary, height: 1.4),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Heading Title
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: RevoTheme.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: RevoTheme.cardBorder),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      selectedField.label.isNotEmpty ? selectedField.label : "Unnamed Field",
                                      style: TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "ID: ${selectedField.id}",
                                      style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: RevoTheme.textSecondary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: RevoTheme.primary.withValues(alpha:0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: RevoTheme.primaryLight.withValues(alpha:0.4)),
                                ),
                                child: Text(
                                  selectedField.type.toUpperCase(),
                                  style: TextStyle(fontFamily: 'Inter', fontSize: 9, color: RevoTheme.primaryLight, fontWeight: FontWeight.bold),
                                ),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Section 1: General Settings (Collapsible)
                        GeneralSettingsSection(
                          field: selectedField,
                          activeStepId: activeStepId,
                          isExpanded: _showGeneralSettings,
                          onToggle: () => setState(() => _showGeneralSettings = !_showGeneralSettings),
                        ),

                        // Section 2: Visibility & Status Flags (Collapsible)
                        StateFlagsSection(
                          field: selectedField,
                          activeStepId: activeStepId,
                          isExpanded: _showStateFlags,
                          onToggle: () => setState(() => _showStateFlags = !_showStateFlags),
                        ),

                        if (_isDataComponent(selectedField.type))
                          DataComponentSection(
                            field: selectedField,
                            activeStepId: activeStepId,
                          ),

                        if (_isLayoutComponent(selectedField.type))
                          LayoutComponentSection(
                            field: selectedField,
                            activeStepId: activeStepId,
                          ),

                        // Section 3: Enterprise Settings (Collapsible)
                        EnterpriseSettingsSection(
                          field: selectedField,
                          activeStepId: activeStepId,
                          isExpanded: _showEnterpriseSettings,
                          onToggle: () => setState(() => _showEnterpriseSettings = !_showEnterpriseSettings),
                        ),

                        if (!isRadioOrSelectionOrDivider)
                          ValidationSettingsSection(
                            field: selectedField,
                            activeStepId: activeStepId,
                            isExpanded: _showValidations,
                            onToggle: () => setState(() => _showValidations = !_showValidations),
                          ),

                        if (supportsOptions)
                          OptionsApiSection(
                            field: selectedField,
                            activeStepId: activeStepId,
                          ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
