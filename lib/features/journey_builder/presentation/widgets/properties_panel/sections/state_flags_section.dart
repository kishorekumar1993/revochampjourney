import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/features/journey_builder/domain/entities/journey_models.dart';
import 'package:revojourneytryone/features/journey_builder/application/controllers/journey_controller.dart';
import '../property_fields.dart';

class StateFlagsSection extends ConsumerWidget {
  final JourneyField field;
  final String activeStepId;
  final bool isExpanded;
  final VoidCallback onToggle;

  const StateFlagsSection({
    super.key,
    required this.field,
    required this.activeStepId,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CollapsibleSection(
      title: "State & Visibility Flags",
      accentColor: RevoTheme.success,
      icon: Icons.visibility_outlined,
      isExpanded: isExpanded,
      onToggle: onToggle,
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 2.8,
          children: [
            CompactSwitchTile(
              label: "Required",
              value: field.required,
              onChanged: (val) {
                final updated = field.copyWith()..required = val;
                ref.read(journeyConfigProvider.notifier)
                    .updateFieldInStep(activeStepId, field.id, updated);
              },
            ),
            CompactSwitchTile(
              label: "Visible",
              value: field.visible,
              onChanged: (val) {
                final updated = field.copyWith()..visible = val;
                ref.read(journeyConfigProvider.notifier)
                    .updateFieldInStep(activeStepId, field.id, updated);
              },
            ),
            CompactSwitchTile(
              label: "Read Only",
              value: field.readOnly,
              onChanged: (val) {
                final updated = field.copyWith()..readOnly = val;
                ref.read(journeyConfigProvider.notifier)
                    .updateFieldInStep(activeStepId, field.id, updated);
              },
            ),
            CompactSwitchTile(
              label: "Disabled",
              value: field.disable,
              onChanged: (val) {
                final updated = field.copyWith()..disable = val;
                ref.read(journeyConfigProvider.notifier)
                    .updateFieldInStep(activeStepId, field.id, updated);
              },
            ),
            CompactSwitchTile(
              label: "Hidden",
              value: field.hidden,
              onChanged: (val) {
                final updated = field.copyWith()..hidden = val;
                ref.read(journeyConfigProvider.notifier)
                    .updateFieldInStep(activeStepId, field.id, updated);
              },
            ),
          ],
        ),
      ],
    );
  }
}
