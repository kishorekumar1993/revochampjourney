import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/features/journey_builder/domain/entities/journey_models.dart';
import 'package:revojourneytryone/features/journey_builder/application/controllers/journey_controller.dart';

import 'canvas_toolbox.dart';
import 'sections/canvas_config_helper.dart';
import 'sections/rules_tab_section.dart';
import 'sections/validations_tab_section.dart';
import 'sections/api_tab_section.dart';
import 'sections/actions_tab_section.dart';
import 'sections/settings_tab_section.dart';
import 'sections/design_workspace_section.dart';
import 'sections/live_preview_section.dart';

class RevoCanvasPanel extends ConsumerStatefulWidget {
  const RevoCanvasPanel({super.key});

  @override
  ConsumerState<RevoCanvasPanel> createState() => _RevoCanvasPanelState();
}

class _RevoCanvasPanelState extends ConsumerState<RevoCanvasPanel> {
  String _activeTab = 'Design';
  bool _isMobilePreview = true;
  bool _showPreview = false;

  @override
  Widget build(BuildContext context) {
    ref.watch(themeModeProvider);
    final activeStepId = ref.watch(activeStepIdProvider);

    final step = ref.watch(journeyConfigProvider.select((config) =>
        config.steps.firstWhereOrNull((s) => s.id == activeStepId)
    ));

    final activeStepIndex = ref.watch(journeyConfigProvider.select((config) =>
        config.steps.indexWhere((s) => s.id == activeStepId)
    ));

    final previousStepId = ref.watch(journeyConfigProvider.select((config) {
      final idx = config.steps.indexWhere((s) => s.id == activeStepId);
      return (idx > 0) ? config.steps[idx - 1].id : null;
    }));

    final nextStepId = ref.watch(journeyConfigProvider.select((config) {
      final idx = config.steps.indexWhere((s) => s.id == activeStepId);
      return (idx >= 0 && idx < config.steps.length - 1) ? config.steps[idx + 1].id : null;
    }));

    if (step == null || activeStepIndex == -1) {
      return Center(
        child: Text(
          "Select or create a step to begin building.",
          style: TextStyle(fontFamily: 'Inter', color: RevoTheme.textSecondary),
        ),
      );
    }

    final selectedFieldId = ref.watch(selectedFieldIdProvider);
    final formValues = ref.watch(formValuesProvider);

    return Container(
      color: RevoTheme.background,
      child: Column(
        children: [
          // Panel Header
          _buildHeader(context, step, activeStepIndex, previousStepId, nextStepId),

          // Tabs sub-bar
          _buildTabBar(step),

          // Workspace Layout
          Expanded(
            child: Row(
              children: [
                // 1. ToolBox Palette
                CanvasToolbox(
                  componentGroups: componentGroups,
                  onAddField: (type) => addField(ref, type),
                ),

                // 2. Editor Canvas / Section Routers
                _buildTabContent(step, selectedFieldId),

                // 3. Mobile/Desktop Live simulator view
                if (_showPreview)
                  LivePreviewSection(
                    step: step,
                    formValues: formValues,
                    previousStepId: previousStepId,
                    nextStepId: nextStepId,
                    isMobilePreview: _isMobilePreview,
                  ),
              ],
            ),
          ),

          // Step Configurations (bottom bar)
          CanvasBottomStats(step: step),
        ],
      ),
    );
  }

  Widget _buildTabContent(JourneyStep step, String? selectedFieldId) {
    switch (_activeTab) {
      case 'Rules':
        return RulesTabSection(step: step);
      case 'Validations':
        return ValidationsTabSection(step: step);
      case 'API':
        return ApiTabSection(step: step);
      case 'Actions':
        return ActionsTabSection(step: step);
      case 'Settings':
        return SettingsTabSection(step: step);
      default:
        return DesignWorkspaceSection(
          step: step,
          selectedFieldId: selectedFieldId,
        );
    }
  }

  Widget _buildHeader(BuildContext context, JourneyStep step, int index, String? previousStepId, String? nextStepId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "Step ${index + 1}: ${step.title}",
                    style: TextStyle(fontFamily: 'Outfit',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: RevoTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: RevoTheme.secondary.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: RevoTheme.secondary.withValues(alpha:0.4)),
                  ),
                  child: Text(
                    "Enabled",
                    style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: RevoTheme.secondary, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Screen switch
                  Container(
                    decoration: BoxDecoration(
                      color: RevoTheme.cardBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        _buildSwitchIconButton(
                          Icons.phone_android_rounded,
                          _showPreview && _isMobilePreview,
                          () => setState(() {
                            _showPreview = true;
                            _isMobilePreview = true;
                          }),
                        ),
                        _buildSwitchIconButton(
                          Icons.laptop_chromebook_rounded,
                          _showPreview && !_isMobilePreview,
                          () => setState(() {
                            _showPreview = true;
                            _isMobilePreview = false;
                          }),
                        ),
                        _buildSwitchIconButton(
                          Icons.visibility_off_rounded,
                          !_showPreview,
                          () => setState(() {
                            _showPreview = false;
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Navigation buttons
                  OutlinedButton(
                    onPressed: previousStepId != null ? () {
                      ref.read(activeStepIdProvider.notifier).state = previousStepId;
                      ref.read(selectedFieldIdProvider.notifier).state = null;
                    } : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text("Back"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: nextStepId != null ? () {
                      ref.read(activeStepIdProvider.notifier).state = nextStepId;
                      ref.read(selectedFieldIdProvider.notifier).state = null;
                    } : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text("Next"),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text("Step Configuration Auto-Saved!"),
                          backgroundColor: RevoTheme.secondary,
                        ),
                      );
                    },
                    icon: const Icon(Icons.cloud_done_rounded, size: 16),
                    label: const Text("Save Step"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchIconButton(IconData icon, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected ? RevoTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: isSelected ? Colors.white : RevoTheme.textSecondary),
      ),
    );
  }

  Widget _buildTabBar(JourneyStep step) {
    final tabs = [
      {'id': 'Design', 'label': 'Design Workspace', 'icon': Icons.design_services_outlined},
      {'id': 'Rules', 'label': 'Rules (${step.conditions.length})', 'icon': Icons.rule_rounded},
      {'id': 'Validations', 'label': 'Validations (${step.validations.length})', 'icon': Icons.gpp_maybe_rounded},
      {'id': 'API', 'label': 'API Calls (${step.apiCalls.length})', 'icon': Icons.api_rounded},
      {'id': 'Settings', 'label': 'Settings', 'icon': Icons.settings_rounded},
      {'id': 'Actions', 'label': 'Actions (${step.actions.length})', 'icon': Icons.flash_on_rounded},
    ];

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: RevoTheme.sidebarBackground,
        border: Border(
          bottom: BorderSide(color: RevoTheme.cardBorder, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((tab) {
            final isSelected = _activeTab == tab['id'];
            return InkWell(
              onTap: () => setState(() => _activeTab = tab['id'] as String),
              child: Container(
                height: 48,
                margin: const EdgeInsets.only(right: 32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: isSelected
                      ? Border(bottom: BorderSide(color: RevoTheme.primary, width: 2))
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      tab['icon'] as IconData,
                      size: 16,
                      color: isSelected ? RevoTheme.primaryLight : RevoTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tab['label'] as String,
                      style: TextStyle(fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? RevoTheme.textPrimary : RevoTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
