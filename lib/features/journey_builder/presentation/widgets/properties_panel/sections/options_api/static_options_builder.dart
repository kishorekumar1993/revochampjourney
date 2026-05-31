import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/features/journey_builder/domain/entities/journey_models.dart';
import 'package:revojourneytryone/features/journey_builder/application/controllers/journey_controller.dart';
import '../../property_fields.dart';

class StaticOptionsBuilder extends ConsumerWidget {
  final JourneyField field;
  final String activeStepId;

  const StaticOptionsBuilder({
    super.key,
    required this.field,
    required this.activeStepId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = field.staticOptions ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Static Options Builder",
          style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.bold, color: RevoTheme.textSecondary),
        ),
        const SizedBox(height: 6),
        ...options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final keyStr = option['key'] ?? '';
          final valStr = option['value'] ?? '';

          return Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: PropertyTextField(
                    label: "Key",
                    initialValue: keyStr,
                    onChanged: (newKey) {
                      final updatedList = List<Map<String, String>>.from(options);
                      updatedList[index] = {'key': newKey.trim(), 'value': valStr};
                      final updated = field.copyWith()..staticOptions = updatedList;
                      ref.read(journeyConfigProvider.notifier)
                          .updateFieldInStep(activeStepId, field.id, updated);
                    },
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 5,
                  child: PropertyTextField(
                    label: "Value",
                    initialValue: valStr,
                    onChanged: (newVal) {
                      final updatedList = List<Map<String, String>>.from(options);
                      updatedList[index] = {'key': keyStr, 'value': newVal};
                      final updated = field.copyWith()..staticOptions = updatedList;
                      ref.read(journeyConfigProvider.notifier)
                          .updateFieldInStep(activeStepId, field.id, updated);
                    },
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                    onPressed: () {
                      final updatedList = List<Map<String, String>>.from(options)..removeAt(index);
                      final updated = field.copyWith()..staticOptions = updatedList;
                      ref.read(journeyConfigProvider.notifier)
                          .updateFieldInStep(activeStepId, field.id, updated);
                    },
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 6),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: RevoTheme.cardBg,
            minimumSize: const Size(double.infinity, 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: RevoTheme.cardBorder),
            ),
          ),
          onPressed: () {
            final updatedList = List<Map<String, String>>.from(options);
            final newIdx = updatedList.length + 1;
            updatedList.add({'key': newIdx.toString(), 'value': 'Option $newIdx'});
            final updated = field.copyWith()..staticOptions = updatedList;
            ref.read(journeyConfigProvider.notifier)
                .updateFieldInStep(activeStepId, field.id, updated);
          },
          icon: const Icon(Icons.add_rounded, size: 12),
          label: const Text("Add New Option", style: TextStyle(fontFamily: 'Inter', fontSize: 10)),
        ),
      ],
    );
  }
}
