import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/features/journey_builder/domain/entities/journey_models.dart';
import 'package:revojourneytryone/features/journey_builder/application/controllers/journey_controller.dart';
import '../property_fields.dart';

class EnterpriseSettingsSection extends ConsumerWidget {
  final JourneyField field;
  final String activeStepId;
  final bool isExpanded;
  final VoidCallback onToggle;

  const EnterpriseSettingsSection({
    super.key,
    required this.field,
    required this.activeStepId,
    required this.isExpanded,
    required this.onToggle,
  });

  void _updateField(WidgetRef ref, void Function(JourneyField updated) mutate) {
    final updated = field.copyWith();
    mutate(updated);
    ref.read(journeyConfigProvider.notifier).updateFieldInStep(activeStepId, field.id, updated);
  }

  Map<String, dynamic>? _tryJsonMap(String value) {
    if (value.trim().isEmpty) return null;
    try {
      final decoded = json.decode(value);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  List<Map<String, dynamic>>? _tryJsonMapList(String value) {
    if (value.trim().isEmpty) return null;
    try {
      final decoded = json.decode(value);
      if (decoded is! List) return null;
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (_) {
      return null;
    }
  }

  List<String>? _csvToList(String value) {
    final list = value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    return list.isEmpty ? null : list;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CollapsibleSection(
      title: "Enterprise Field Rules",
      accentColor: RevoTheme.primaryLight,
      icon: Icons.account_tree_outlined,
      isExpanded: isExpanded,
      onToggle: onToggle,
      children: [
        Row(
          children: [
            Expanded(
              child: PropertyTextField(
                label: "Group ID",
                initialValue: field.groupId ?? '',
                hint: "customerDetails",
                onChanged: (val) => _updateField(ref, (updated) => updated.groupId = val.trim().isEmpty ? null : val.trim()),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PropertyTextField(
                label: "Section ID",
                initialValue: field.sectionId ?? '',
                hint: "kyc",
                onChanged: (val) => _updateField(ref, (updated) => updated.sectionId = val.trim().isEmpty ? null : val.trim()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        CompactSwitchTile(
          label: "Repeatable Group",
          value: field.repeatableGroup,
          onChanged: (val) => _updateField(ref, (updated) => updated.repeatableGroup = val),
        ),
        const SizedBox(height: 10),
        PropertyTextField(
          label: "Formula / Calculated Value",
          initialValue: field.formula ?? '',
          hint: "sum(lineItems.amount)",
          onChanged: (val) => _updateField(ref, (updated) => updated.formula = val.trim().isEmpty ? null : val.trim()),
        ),
        const SizedBox(height: 10),
        PropertyTextField(
          label: "Dynamic Expression",
          initialValue: field.expression ?? '',
          hint: "age >= 18 && country == 'IN'",
          onChanged: (val) => _updateField(ref, (updated) => updated.expression = val.trim().isEmpty ? null : val.trim()),
        ),
        const SizedBox(height: 10),
        PropertyTextField(
          label: "Dynamic Default Expression",
          initialValue: field.defaultValueExpression ?? '',
          hint: "currentUser.email",
          onChanged: (val) => _updateField(ref, (updated) => updated.defaultValueExpression = val.trim().isEmpty ? null : val.trim()),
        ),
        const SizedBox(height: 10),
        PropertyTextField(
          label: "Depends On",
          initialValue: field.dependsOn ?? '',
          hint: "country",
          onChanged: (val) => _updateField(ref, (updated) => updated.dependsOn = val.trim().isEmpty ? null : val.trim()),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: PropertyTextField(
                label: "Visible Roles",
                initialValue: field.visibleForRoles?.join(', ') ?? '',
                hint: "admin, maker",
                onChanged: (val) => _updateField(ref, (updated) => updated.visibleForRoles = _csvToList(val)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PropertyTextField(
                label: "Editable Roles",
                initialValue: field.editableForRoles?.join(', ') ?? '',
                hint: "admin, checker",
                onChanged: (val) => _updateField(ref, (updated) => updated.editableForRoles = _csvToList(val)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        PropertyTextField(
          label: "Async Validation JSON",
          initialValue: field.asyncValidation == null ? '' : json.encode(field.asyncValidation),
          hint: '{"url": "/validate-pan", "method": "POST"}',
          maxLines: 3,
          onChanged: (val) {
            try {
              final parsed = _tryJsonMap(val);
              _updateField(ref, (updated) => updated.asyncValidation = parsed);
            } catch (_) {}
          },
        ),
        const SizedBox(height: 10),
        PropertyTextField(
          label: "Cascade Config JSON",
          initialValue: field.cascadeConfig == null ? '' : json.encode(field.cascadeConfig),
          hint: '{"parentField": "country", "param": "countryId"}',
          maxLines: 3,
          onChanged: (val) {
            try {
              final parsed = _tryJsonMap(val);
              _updateField(ref, (updated) => updated.cascadeConfig = parsed);
            } catch (_) {}
          },
        ),
        const SizedBox(height: 10),
        PropertyTextField(
          label: "Localization JSON",
          initialValue: field.localization == null ? '' : json.encode(field.localization),
          hint: '{"en": {"label": "Name"}, "hi": {"label": "Naam"}}',
          maxLines: 3,
          onChanged: (val) {
            try {
              final parsed = _tryJsonMap(val);
              _updateField(ref, (updated) => updated.localization = parsed);
            } catch (_) {}
          },
        ),
        const SizedBox(height: 10),
        PropertyTextField(
          label: "Conditional Validations JSON",
          initialValue: field.conditionalValidations == null ? '' : json.encode(field.conditionalValidations),
          hint: '[{"if": "age < 18", "type": "required", "message": "Guardian required"}]',
          maxLines: 3,
          onChanged: (val) {
            try {
              final parsed = _tryJsonMapList(val);
              _updateField(ref, (updated) => updated.conditionalValidations = parsed);
            } catch (_) {}
          },
        ),
      ],
    );
  }
}
