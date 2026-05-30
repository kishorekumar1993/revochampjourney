import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/features/journey_builder/domain/entities/journey_models.dart';
import 'package:revojourneytryone/features/journey_builder/application/controllers/journey_controller.dart';
import '../canvas_fields.dart';

class RulesTabSection extends ConsumerWidget {
  final JourneyStep step;

  const RulesTabSection({
    super.key,
    required this.step,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allFields = ref.watch(journeyConfigProvider.select((config) => config.steps.expand((s) => s.fields).toList()));
    final allSteps = ref.watch(journeyConfigProvider.select((config) => config.steps));

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
                    "Step Conditional Rules",
                    style: TextStyle(fontFamily: 'Outfit', fontSize: 20, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Define conditions to show/hide/enable fields or branch steps dynamically.",
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
                  final defaultField = allFields.isNotEmpty ? allFields.first.id : "";
                  final newCondition = StepCondition(
                    type: "visibleIf",
                    field: defaultField,
                    operator: "equals",
                    value: "",
                  );
                  ref.read(journeyConfigProvider.notifier).addConditionToStep(step.id, newCondition);
                },
                icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                label: const Text("Add Rule"),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: step.conditions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.rule_folder_outlined, size: 48, color: RevoTheme.textSecondary.withValues(alpha:0.4)),
                        const SizedBox(height: 12),
                        Text(
                          "No conditional rules defined for this step.",
                          style: TextStyle(fontFamily: 'Inter', color: RevoTheme.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: step.conditions.length,
                    itemBuilder: (context, index) {
                      final condition = step.conditions[index];
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
                                  "Rule #${index + 1}",
                                  style: TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.bold, color: RevoTheme.primaryLight),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                  onPressed: () {
                                    ref.read(journeyConfigProvider.notifier).removeConditionFromStep(step.id, index);
                                  },
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                // 1. If Field
                                Expanded(
                                  flex: 3,
                                  child: CanvasDropdownField(
                                    label: "If Field",
                                    value: condition.field,
                                    items: allFields.map((f) => f.id).toList(),
                                    fallback: "Select Field",
                                    onChanged: (val) {
                                      ref.read(journeyConfigProvider.notifier)
                                          .updateConditionInStep(step.id, index, condition.copyWith(field: val));
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // 2. Action Type
                                Expanded(
                                  flex: 2,
                                  child: CanvasDropdownField(
                                    label: "Action",
                                    value: condition.type,
                                    items: const ["visibleIf", "showIf", "enableIf", "nextStepIf"],
                                    fallback: "visibleIf",
                                    onChanged: (val) {
                                      ref.read(journeyConfigProvider.notifier)
                                          .updateConditionInStep(step.id, index, condition.copyWith(type: val));
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // 3. Operator
                                Expanded(
                                  flex: 2,
                                  child: CanvasDropdownField(
                                    label: "Operator",
                                    value: condition.operator,
                                    items: const ["equals", "notEquals", "contains"],
                                    fallback: "equals",
                                    onChanged: (val) {
                                      ref.read(journeyConfigProvider.notifier)
                                          .updateConditionInStep(step.id, index, condition.copyWith(operator: val));
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // 4. Value
                                Expanded(
                                  flex: 3,
                                  child: CanvasTextField(
                                    label: "Value",
                                    initialValue: condition.value,
                                    onChanged: (val) {
                                      ref.read(journeyConfigProvider.notifier)
                                          .updateConditionInStep(step.id, index, condition.copyWith(value: val.trim()));
                                    },
                                  ),
                                ),
                              ],
                            ),
                            if (condition.type == 'nextStepIf') ...[
                              const SizedBox(height: 12),
                              CanvasDropdownField(
                                label: "Branch Target Step",
                                value: condition.targetStep ?? "",
                                items: allSteps.map((s) => s.id).toList(),
                                fallback: "Select Target Step",
                                onChanged: (val) {
                                  ref.read(journeyConfigProvider.notifier)
                                      .updateConditionInStep(step.id, index, condition.copyWith(targetStep: val));
                                },
                              ),
                            ],
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
