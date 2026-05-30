import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/features/journey_builder/domain/entities/journey_models.dart';
import 'package:revojourneytryone/features/journey_builder/application/controllers/journey_controller.dart';
import '../canvas_fields.dart';

class SettingsTabSection extends ConsumerWidget {
  final JourneyStep step;

  const SettingsTabSection({
    super.key,
    required this.step,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allSteps = ref.watch(journeyConfigProvider.select((config) => config.steps));
    final otherStepIds = allSteps.map((s) => s.id).where((id) => id != step.id).toList();

    return Container(
      color: RevoTheme.background,
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Step Details & Settings",
              style: TextStyle(fontFamily: 'Outfit', fontSize: 20, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              "Configure basic metadata and step flow transition configurations.",
              style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: RevoTheme.textSecondary),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: RevoTheme.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: RevoTheme.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CanvasTextField(
                    label: "Step ID (Unique identifier)",
                    initialValue: step.id,
                    onChanged: (val) {
                      final clean = val.trim();
                      if (clean.isEmpty || clean == step.id) return;

                      final exists = allSteps.any((s) => s.id == clean);
                      if (exists) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Step ID must be unique!"), backgroundColor: Colors.redAccent),
                        );
                        return;
                      }

                      final updated = step.copyWith(id: clean);
                      ref.read(journeyConfigProvider.notifier).updateStep(step.id, updated);
                      ref.read(activeStepIdProvider.notifier).state = clean;
                    },
                  ),
                  const SizedBox(height: 16),
                  CanvasTextField(
                    label: "Step Title",
                    initialValue: step.title,
                    onChanged: (val) {
                      final updated = step.copyWith(title: val.trim());
                      ref.read(journeyConfigProvider.notifier).updateStep(step.id, updated);
                    },
                  ),
                  const SizedBox(height: 16),
                  CanvasTextField(
                    label: "Step Description / Subtitle",
                    initialValue: step.description,
                    maxLines: 3,
                    onChanged: (val) {
                      final updated = step.copyWith(description: val.trim());
                      ref.read(journeyConfigProvider.notifier).updateStep(step.id, updated);
                    },
                  ),
                  const SizedBox(height: 16),
                  CanvasDropdownField(
                    label: "Next Flow Step ID",
                    value: step.nextStep ?? "",
                    items: otherStepIds,
                    fallback: "None (End of Journey)",
                    onChanged: (val) {
                      final updated = step.copyWith(nextStep: val.isEmpty ? null : val);
                      ref.read(journeyConfigProvider.notifier).updateStep(step.id, updated);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
