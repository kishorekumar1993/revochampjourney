import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/features/journey_builder/domain/entities/journey_models.dart';
import 'package:revojourneytryone/features/journey_builder/application/controllers/journey_controller.dart';
import '../property_fields.dart';

class GeneralSettingsSection extends ConsumerWidget {
  final JourneyField field;
  final String activeStepId;
  final bool isExpanded;
  final VoidCallback onToggle;

  const GeneralSettingsSection({
    super.key,
    required this.field,
    required this.activeStepId,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRadioOrSelectionOrDivider = field.type == 'radio' ||
        field.type == 'checkbox' ||
        field.type == 'switch' ||
        field.type == 'divider';

    return CollapsibleSection(
      title: "General Settings",
      accentColor: RevoTheme.primaryLight,
      icon: Icons.tune_rounded,
      isExpanded: isExpanded,
      onToggle: onToggle,
      children: [
        Row(
          children: [
            Expanded(
              child: PropertyTextField(
                label: "Field ID",
                initialValue: field.id,
                onChanged: (val) {
                  final updated = field.copyWith()..id = val.trim();
                  ref.read(journeyConfigProvider.notifier)
                      .updateFieldInStep(activeStepId, field.id, updated);
                  ref.read(selectedFieldIdProvider.notifier).state = val.trim();
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PropertyDropdownField(
                label: "Type",
                currentValue: field.type,
                items: const [
                  'text',
                  'textarea',
                  'number',
                  'dropdown',
                  'api_dropdown',
                  'radio',
                  'checkbox',
                  'switch',
                  'date',
                  'time',
                  'datetime',
                  'file',
                  'image',
                  'otp',
                  'phone',
                  'multi_select',
                  'table_grid',
                  'repeater',
                  'timeline',
                  'row',
                  'formula',
                  'section',
                  'card',
                  'tabs',
                  'accordion',
                  'divider'
                ],
                onChanged: (val) {
                  final updated = field.copyWith()..type = val;
                  ref.read(journeyConfigProvider.notifier)
                      .updateFieldInStep(activeStepId, field.id, updated);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: PropertyTextField(
                label: "Label Text",
                initialValue: field.label,
                onChanged: (val) {
                  final updated = field.copyWith()..label = val.trim();
                  ref.read(journeyConfigProvider.notifier)
                      .updateFieldInStep(activeStepId, field.id, updated);
                },
              ),
            ),
            if (!isRadioOrSelectionOrDivider) ...[
              const SizedBox(width: 8),
              Expanded(
                child: PropertyTextField(
                  label: "Metadata Type",
                  initialValue: field.fieldtype ?? '',
                  hint: "e.g. text, select",
                  onChanged: (val) {
                    final updated = field.copyWith()..fieldtype = val.trim().isEmpty ? null : val.trim();
                    ref.read(journeyConfigProvider.notifier)
                        .updateFieldInStep(activeStepId, field.id, updated);
                  },
                ),
              ),
            ],
          ],
        ),
        if (!isRadioOrSelectionOrDivider) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: PropertyTextField(
                  label: "Placeholder",
                  initialValue: field.placeholder ?? '',
                  onChanged: (val) {
                    final updated = field.copyWith()..placeholder = val.trim().isEmpty ? null : val.trim();
                    ref.read(journeyConfigProvider.notifier)
                        .updateFieldInStep(activeStepId, field.id, updated);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PropertyTextField(
                  label: "Hint Text",
                  initialValue: field.hintText ?? '',
                  onChanged: (val) {
                    final updated = field.copyWith()..hintText = val.trim().isEmpty ? null : val.trim();
                    ref.read(journeyConfigProvider.notifier)
                        .updateFieldInStep(activeStepId, field.id, updated);
                  },
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 10),
        PropertyTextField(
          label: "Default Value / Initial Value",
          initialValue: field.defaultValue ?? '',
          hint: "Initial value of the field",
          onChanged: (val) {
            final updated = field.copyWith()..defaultValue = val.trim().isEmpty ? null : val.trim();
            ref.read(journeyConfigProvider.notifier)
                .updateFieldInStep(activeStepId, field.id, updated);
          },
        ),
      ],
    );
  }
}
