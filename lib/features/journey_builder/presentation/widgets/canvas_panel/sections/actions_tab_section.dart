import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/features/journey_builder/domain/entities/journey_models.dart';
import 'package:revojourneytryone/features/journey_builder/application/controllers/journey_controller.dart';
import '../canvas_fields.dart';

class ActionsTabSection extends ConsumerWidget {
  final JourneyStep step;

  const ActionsTabSection({
    super.key,
    required this.step,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: RevoTheme.background,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Step Lifecycle Actions",
                    style: TextStyle(fontFamily: 'Outfit', fontSize: 20, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Trigger background behaviors, navigation, or popups when actions run.",
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: RevoTheme.textSecondary),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: RevoTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onPressed: () {
                  final newAction = StepAction(
                    trigger: "onSubmit",
                    actionType: "showBanner",
                    details: "Action details here",
                  );
                  ref.read(journeyConfigProvider.notifier).addActionToStep(step.id, newAction);
                },
                icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                label: const Text("Add Action"),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: step.actions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.flash_on_rounded, size: 48, color: RevoTheme.textSecondary.withValues(alpha:0.4)),
                        const SizedBox(height: 12),
                        Text(
                          "No step-level actions configured yet.",
                          style: TextStyle(fontFamily: 'Inter', color: RevoTheme.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: step.actions.length,
                    itemBuilder: (context, index) {
                      final action = step.actions[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: RevoTheme.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: RevoTheme.cardBorder, width: 1.2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Action #${index + 1}",
                                  style: TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.bold, color: RevoTheme.primaryLight),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                  onPressed: () {
                                    ref.read(journeyConfigProvider.notifier).removeActionFromStep(step.id, index);
                                  },
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                // Trigger Event
                                Expanded(
                                  flex: 3,
                                  child: CanvasDropdownField(
                                    label: "Trigger Event",
                                    value: action.trigger,
                                    items: const ["onSubmit", "onFieldChange"],
                                    fallback: "onSubmit",
                                    onChanged: (val) {
                                      ref.read(journeyConfigProvider.notifier)
                                          .updateActionInStep(step.id, index, action.copyWith(trigger: val));
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Action Type
                                Expanded(
                                  flex: 3,
                                  child: CanvasDropdownField(
                                    label: "Action Type",
                                    value: action.actionType,
                                    items: const ["apiCall", "navigate", "showBanner"],
                                    fallback: "showBanner",
                                    onChanged: (val) {
                                      ref.read(journeyConfigProvider.notifier)
                                          .updateActionInStep(step.id, index, action.copyWith(actionType: val));
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Action Details / Payload
                                Expanded(
                                  flex: 6,
                                  child: CanvasTextField(
                                    label: "Action Details / Payload",
                                    initialValue: action.details,
                                    hint: "e.g. Save details or stepId",
                                    onChanged: (val) {
                                      ref.read(journeyConfigProvider.notifier)
                                          .updateActionInStep(step.id, index, action.copyWith(details: val.trim()));
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
