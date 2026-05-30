import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/features/journey_builder/data/models.dart';
import 'package:revojourneytryone/features/journey_builder/presentation/providers/journey_provider.dart';
import 'steps_panel_dialogs.dart';

class StepsFlowTab extends ConsumerWidget {
  final JourneyConfig config;
  final String activeStepId;

  const StepsFlowTab({
    super.key,
    required this.config,
    required this.activeStepId,
  });

  IconData _getStepIcon(String stepId) {
    switch (stepId) {
      case 'personal':
        return Icons.person_outline_rounded;
      case 'vehicle':
        return Icons.directions_car_filled_outlined;
      case 'nominee':
        return Icons.people_alt_outlined;
      case 'documents':
        return Icons.file_upload_outlined;
      case 'review':
        return Icons.rate_review_outlined;
      case 'payment':
        return Icons.payment_outlined;
      case 'success':
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Widget _buildProgressMetric(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: RevoTheme.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalSteps = config.steps.length;
    final activeIndex = config.steps.indexWhere((s) => s.id == activeStepId);
    final completedSteps = activeIndex >= 0 ? activeIndex : 0;
    final percentage = totalSteps > 0 
        ? ((completedSteps / totalSteps) * 100).round() 
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Steps list title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Journey Steps",
                style: TextStyle(fontFamily: 'Outfit', 
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: RevoTheme.textPrimary,
                ),
              ),
              TextButton.icon(
                onPressed: () => showAddStepDialog(context, ref),
                icon: Icon(Icons.add, size: 14, color: RevoTheme.primaryLight),
                label: Text(
                  "Add Step",
                  style: TextStyle(fontFamily: 'Inter', 
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: RevoTheme.primaryLight,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),

        // Reorderable Steps List
        Expanded(
          child: Theme(
            data: Theme.of(context).copyWith(
              canvasColor: Colors.transparent,
            ),
            child: ReorderableListView.builder(
              itemCount: config.steps.length,
              onReorder: (oldIndex, newIndex) {
                ref.read(journeyConfigProvider.notifier).reorderSteps(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final step = config.steps[index];
                final isSelected = step.id == activeStepId;
                final stepNum = index + 1;

                return Padding(
                  key: ValueKey(step.id),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: ListTile(
                    selected: isSelected,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected 
                            ? RevoTheme.primary 
                            : RevoTheme.cardBorder,
                        width: 1.5,
                      ),
                    ),
                    tileColor: RevoTheme.cardBg,
                    selectedTileColor: RevoTheme.primary.withValues(alpha: 0.1),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ReorderableDragStartListener(
                          index: index,
                          child: Icon(
                            Icons.drag_indicator_rounded, 
                            color: RevoTheme.textSecondary, 
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? RevoTheme.primary 
                                : RevoTheme.cardBorder,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "$stepNum",
                            style: TextStyle(fontFamily: 'Inter', 
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : RevoTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    title: Text(
                      step.title,
                      style: TextStyle(fontFamily: 'Inter', 
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: RevoTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        "${step.fields.length} fields • id: ${step.id}",
                        style: TextStyle(fontFamily: 'Inter', 
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: RevoTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStepIcon(step.id),
                          color: isSelected ? RevoTheme.primary : RevoTheme.textSecondary,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert_rounded, size: 16, color: RevoTheme.textSecondary),
                          color: RevoTheme.cardBg,
                          onSelected: (val) {
                            if (val == 'delete') {
                              final currentActive = ref.read(activeStepIdProvider);
                              ref.read(journeyConfigProvider.notifier).removeStep(step.id);
                              if (currentActive == step.id) {
                                final steps = ref.read(journeyConfigProvider).steps;
                                final newActive = steps.isNotEmpty ? steps.first.id : '';
                                ref.read(activeStepIdProvider.notifier).state = newActive;
                              }
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline_rounded, color: Colors.red, size: 16),
                                  SizedBox(width: 8),
                                  Text("Delete Step", style: TextStyle(color: Colors.red, fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    onTap: () {
                      ref.read(activeStepIdProvider.notifier).state = step.id;
                      ref.read(selectedFieldIdProvider.notifier).state = null;
                    },
                  ),
                );
              },
            ),
          ),
        ),

        // Journey Progress Radial Gauge & Preview Button
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: RevoTheme.sidebarBackground,
            border: Border(
              top: BorderSide(color: RevoTheme.cardBorder, width: 1),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: RevoTheme.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: RevoTheme.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Journey Progress",
                      style: TextStyle(fontFamily: 'Outfit', 
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: RevoTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 70,
                              height: 70,
                              child: CircularProgressIndicator(
                                value: totalSteps > 0 ? (completedSteps / totalSteps) : 0,
                                strokeWidth: 8,
                                backgroundColor: RevoTheme.cardBorder,
                                color: RevoTheme.primary,
                              ),
                            ),
                            Text(
                              "$percentage%",
                              style: TextStyle(fontFamily: 'Outfit', 
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: RevoTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildProgressMetric("Completed Steps", "$completedSteps/$totalSteps"),
                              const SizedBox(height: 6),
                               _buildProgressMetric("In Progress", activeIndex >= 0 ? "1" : "0"),
                              const SizedBox(height: 6),
                              _buildProgressMetric("Remaining", "${totalSteps - completedSteps}"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.push('/runner');
                  },
                  icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                  label: const Text("Preview Journey"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: RevoTheme.primary),
                    foregroundColor: RevoTheme.primaryLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
