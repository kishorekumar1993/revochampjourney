import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/features/journey_builder/application/controllers/journey_controller.dart';
import 'package:revojourneytryone/features/visual_builder/application/studio_providers.dart';
import 'package:revojourneytryone/features/journey_builder/presentation/widgets/steps_panel/steps_flow_tab.dart';
import 'package:revojourneytryone/features/journey_builder/presentation/widgets/steps_panel/steps_build_tab.dart';
import 'package:revojourneytryone/features/journey_builder/presentation/widgets/steps_panel/steps_settings_tab.dart';
import 'package:revojourneytryone/features/journey_builder/presentation/widgets/steps_panel/steps_history_tab.dart';
import 'package:revojourneytryone/features/journey_builder/data/models.dart';

class RevoStepsPanel extends ConsumerWidget {
  const RevoStepsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch themeModeProvider to trigger a rebuild when the global theme changes
    ref.watch(themeModeProvider);
    final config = ref.watch(journeyConfigProvider);
    final activeStepId = ref.watch(activeStepIdProvider);
    final activeTab = ref.watch(activeSidebarTabProvider);

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: RevoTheme.sidebarBackground,
        border: Border(
          right: BorderSide(color: RevoTheme.cardBorder, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header / Info
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        config.journeyName,
                        style: TextStyle(fontFamily: 'Outfit', 
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: RevoTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Tooltip(
                      message: "Rename Journey",
                      child: IconButton(
                        icon: Icon(Icons.edit, size: 16, color: RevoTheme.textSecondary),
                        onPressed: () {
                          // Rename journey dialog
                          final nameCtrl = TextEditingController(text: config.journeyName);
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: RevoTheme.cardBg,
                              title: const Text("Rename Journey"),
                              content: TextField(
                                controller: nameCtrl,
                                decoration: const InputDecoration(labelText: "Journey Name"),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Cancel"),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    ref.read(journeyConfigProvider.notifier)
                                        .updateJourneyName(nameCtrl.text.trim());
                                    Navigator.pop(context);
                                  },
                                  child: const Text("Save"),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  "Version ${config.version}",
                  style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: RevoTheme.textSecondary),
                ),
              ],
            ),
          ),

          // Tabs
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildTabItem(ref, "Journey Flow", activeTab == 'Journey Flow'),
                _buildTabItem(ref, "Build", activeTab == 'Build'),
                _buildTabItem(ref, "Settings", activeTab == 'Settings'),
                _buildTabItem(ref, "History", activeTab == 'History'),
              ],
            ),
          ),
          Divider(color: RevoTheme.cardBorder),

          // Active Tab Content
          Expanded(
            child: _buildTabContent(activeTab, config, activeStepId),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(WidgetRef ref, String text, bool isSelected) {
    return Expanded(
      child: InkWell(
        onTap: () {
          ref.read(activeSidebarTabProvider.notifier).state = text;
        },
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: isSelected 
                ? Border(bottom: BorderSide(color: RevoTheme.primary, width: 2))
                : null,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              style: TextStyle(fontFamily: 'Inter', 
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? RevoTheme.textPrimary : RevoTheme.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(String activeTab, JourneyConfig config, String activeStepId) {
    switch (activeTab) {
      case 'Build':
        return StepsBuildTab(config: config);
      case 'Settings':
        return StepsSettingsTab(config: config);
      case 'History':
        return StepsHistoryTab(config: config);
      case 'Journey Flow':
      default:
        return StepsFlowTab(config: config, activeStepId: activeStepId);
    }
  }
}
