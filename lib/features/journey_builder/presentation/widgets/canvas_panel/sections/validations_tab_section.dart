import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/features/journey_builder/domain/entities/journey_models.dart';
import 'package:revojourneytryone/features/journey_builder/application/controllers/journey_controller.dart';
import '../canvas_fields.dart';

class ValidationsTabSection extends ConsumerWidget {
  final JourneyStep step;

  const ValidationsTabSection({
    super.key,
    required this.step,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allFields = step.fields;

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
                    "Step Validations Builder",
                    style: TextStyle(fontFamily: 'Outfit', fontSize: 20, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Define custom validation constraints, regex matches, or required fields for this step.",
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
                  final newValidation = StepValidation(
                    type: "required",
                    field: defaultField,
                    message: "This field is required",
                  );
                  ref.read(journeyConfigProvider.notifier).addValidationToStep(step.id, newValidation);
                },
                icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                label: const Text("Add Validation"),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: step.validations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.gpp_maybe_outlined, size: 48, color: RevoTheme.textSecondary.withValues(alpha:0.4)),
                        const SizedBox(height: 12),
                        Text(
                          "No custom validations configured for this step.",
                          style: TextStyle(fontFamily: 'Inter', color: RevoTheme.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: step.validations.length,
                    itemBuilder: (context, index) {
                      final validation = step.validations[index];
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
                                  "Validation #${index + 1}",
                                  style: TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.bold, color: RevoTheme.primaryLight),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                  onPressed: () {
                                    ref.read(journeyConfigProvider.notifier).removeValidationFromStep(step.id, index);
                                  },
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                // 1. Target Field
                                Expanded(
                                  flex: 3,
                                  child: CanvasDropdownField(
                                    label: "Target Field",
                                    value: validation.field,
                                    items: allFields.map((f) => f.id).toList(),
                                    fallback: "Select Field",
                                    onChanged: (val) {
                                      ref.read(journeyConfigProvider.notifier)
                                          .updateValidationInStep(step.id, index, validation.copyWith(field: val));
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // 2. Validation Type
                                Expanded(
                                  flex: 2,
                                  child: CanvasDropdownField(
                                    label: "Validation Type",
                                    value: validation.type,
                                    items: const ["required", "regex", "async", "dependency"],
                                    fallback: "required",
                                    onChanged: (val) {
                                      ref.read(journeyConfigProvider.notifier)
                                          .updateValidationInStep(step.id, index, validation.copyWith(type: val));
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // 3. Error Message
                                Expanded(
                                  flex: 5,
                                  child: CanvasTextField(
                                    label: "Error Message",
                                    initialValue: validation.message,
                                    onChanged: (val) {
                                      ref.read(journeyConfigProvider.notifier)
                                          .updateValidationInStep(step.id, index, validation.copyWith(message: val.trim()));
                                    },
                                  ),
                                ),
                              ],
                            ),
                            if (validation.type == 'regex') ...[
                              const SizedBox(height: 12),
                              CanvasTextField(
                                label: "Regex Pattern",
                                initialValue: validation.regexPattern ?? "",
                                hint: "e.g. ^[a-zA-Z]+\$ or ^[0-9]{6}\$",
                                onChanged: (val) {
                                  ref.read(journeyConfigProvider.notifier)
                                      .updateValidationInStep(step.id, index, validation.copyWith(regexPattern: val.trim().isEmpty ? null : val.trim()));
                                },
                              ),
                            ] else if (validation.type == 'async') ...[
                              const SizedBox(height: 12),
                              CanvasTextField(
                                label: "Async Validation URL Path",
                                initialValue: validation.validationUrl ?? "",
                                hint: "e.g. /api/v1/validate/pan-number or https://api.val.com/check",
                                onChanged: (val) {
                                  ref.read(journeyConfigProvider.notifier)
                                      .updateValidationInStep(step.id, index, validation.copyWith(validationUrl: val.trim().isEmpty ? null : val.trim()));
                                },
                              ),
                            ] else if (validation.type == 'dependency') ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: CanvasDropdownField(
                                      label: "Dependent Field ID",
                                      value: validation.dependentField ?? "",
                                      items: allFields.map((f) => f.id).where((id) => id != validation.field).toList(),
                                      fallback: "Select Dependent Field",
                                      onChanged: (val) {
                                        ref.read(journeyConfigProvider.notifier)
                                            .updateValidationInStep(step.id, index, validation.copyWith(dependentField: val.isEmpty ? null : val));
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: CanvasTextField(
                                      label: "Expected Value to Require Field",
                                      initialValue: validation.dependentValue ?? "",
                                      hint: "e.g. Married or Yes",
                                      onChanged: (val) {
                                        ref.read(journeyConfigProvider.notifier)
                                            .updateValidationInStep(step.id, index, validation.copyWith(dependentValue: val.trim().isEmpty ? null : val.trim()));
                                      },
                                    ),
                                  ),
                                ],
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
