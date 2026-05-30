import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/features/journey_builder/domain/entities/journey_models.dart';
import 'package:revojourneytryone/features/journey_builder/application/controllers/journey_controller.dart';
import '../property_fields.dart';

class ValidationSettingsSection extends ConsumerWidget {
  final JourneyField field;
  final String activeStepId;
  final bool isExpanded;
  final VoidCallback onToggle;

  const ValidationSettingsSection({
    super.key,
    required this.field,
    required this.activeStepId,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CollapsibleSection(
      title: "Validations & Input Config",
      accentColor: RevoTheme.warning,
      icon: Icons.gpp_maybe_outlined,
      isExpanded: isExpanded,
      onToggle: onToggle,
      children: [
        PropertyTextField(
          label: "Validation Pattern (Regex)",
          initialValue: field.validationPattern ?? '',
          hint: "e.g. ^[0-9]{10}\$ or Letters only",
          onChanged: (val) {
            final updated = field.copyWith()..validationPattern = val.trim().isEmpty ? null : val.trim();
            ref.read(journeyConfigProvider.notifier)
                .updateFieldInStep(activeStepId, field.id, updated);
          },
        ),
        const SizedBox(height: 10),
        PropertyTextField(
          label: "Validation Error Message",
          initialValue: field.errorMessage ?? '',
          hint: "Message shown on validation failure",
          onChanged: (val) {
            final updated = field.copyWith()..errorMessage = val.trim().isEmpty ? null : val.trim();
            ref.read(journeyConfigProvider.notifier)
                .updateFieldInStep(activeStepId, field.id, updated);
          },
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: PropertyTextField(
                label: "Min Length",
                initialValue: field.minLength?.toString() ?? '',
                hint: "e.g. 2",
                onChanged: (val) {
                  final parsed = int.tryParse(val.trim());
                  final updated = field.copyWith()..minLength = parsed;
                  ref.read(journeyConfigProvider.notifier)
                      .updateFieldInStep(activeStepId, field.id, updated);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PropertyTextField(
                label: "Max Length",
                initialValue: field.maxLength?.toString() ?? '',
                hint: "e.g. 50",
                onChanged: (val) {
                  final parsed = int.tryParse(val.trim());
                  final updated = field.copyWith()..maxLength = parsed;
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
              child: PropertyDropdownField(
                label: "Keyboard Type",
                currentValue: field.keyboardType ?? 'text',
                items: const ['text', 'number', 'email', 'phone', 'datetime'],
                onChanged: (val) {
                  final updated = field.copyWith()..keyboardType = val;
                  ref.read(journeyConfigProvider.notifier)
                      .updateFieldInStep(activeStepId, field.id, updated);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PropertyDropdownField(
                label: "Input Action",
                currentValue: field.textInputAction ?? 'done',
                items: const ['done', 'next', 'search', 'none', 'go', 'send'],
                onChanged: (val) {
                  final updated = field.copyWith()..textInputAction = val;
                  ref.read(journeyConfigProvider.notifier)
                      .updateFieldInStep(activeStepId, field.id, updated);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        PropertyDropdownField(
          label: "Text Capitalization",
          currentValue: field.textCapitalization ?? 'none',
          items: const ['none', 'characters', 'words', 'sentences'],
          onChanged: (val) {
            final updated = field.copyWith()..textCapitalization = val;
            ref.read(journeyConfigProvider.notifier)
                .updateFieldInStep(activeStepId, field.id, updated);
          },
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 2.8,
          children: [
            CompactSwitchTile(
              label: "Obscure Text",
              value: field.obscureText,
              onChanged: (val) {
                final updated = field.copyWith()..obscureText = val;
                ref.read(journeyConfigProvider.notifier)
                    .updateFieldInStep(activeStepId, field.id, updated);
              },
            ),
            CompactSwitchTile(
              label: "Autocorrect",
              value: field.autocorrect,
              onChanged: (val) {
                final updated = field.copyWith()..autocorrect = val;
                ref.read(journeyConfigProvider.notifier)
                    .updateFieldInStep(activeStepId, field.id, updated);
              },
            ),
            CompactSwitchTile(
              label: "Suggestions",
              value: field.enableSuggestions,
              onChanged: (val) {
                final updated = field.copyWith()..enableSuggestions = val;
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
