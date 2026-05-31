import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/features/journey_builder/domain/entities/journey_models.dart';
import 'package:revojourneytryone/features/journey_builder/application/controllers/journey_controller.dart';
import '../../property_fields.dart';

class ResponseParserPreview extends ConsumerStatefulWidget {
  final JourneyField field;
  final String activeStepId;
  final String? testDataError;
  final ValueChanged<String?> onTestDataErrorChanged;

  const ResponseParserPreview({
    super.key,
    required this.field,
    required this.activeStepId,
    required this.testDataError,
    required this.onTestDataErrorChanged,
  });

  @override
  ConsumerState<ResponseParserPreview> createState() => _ResponseParserPreviewState();
}

class _ResponseParserPreviewState extends ConsumerState<ResponseParserPreview> {
  String? _validateJsonResponseData(String val) {
    if (val.trim().isEmpty) return null;
    try {
      final decoded = json.decode(val);
      if (decoded is! List && decoded is! Map) {
        return "Must be a valid JSON Array or Object response.";
      }
      return null;
    } catch (e) {
      return "Invalid JSON syntax: ${e.toString()}";
    }
  }

  Widget _buildResponsePreview(JourneyField field) {
    final data = field.dropdowndata;
    final displayKey = field.dropdownValue ?? 'title';

    if (data == null || data.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: RevoTheme.background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: RevoTheme.cardBorder),
        ),
        child: Text(
          "Enter mock/test response JSON array in the field above to see live dropdown parse preview.",
          style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: RevoTheme.textSecondary, fontStyle: FontStyle.italic),
        ),
      );
    }

    try {
      final parsedOptions = field.getResolvedOptions();
      if (parsedOptions.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.orangeAccent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.25)),
          ),
          child: Text(
            "Parsed 0 options. Double-check if the Display Key '$displayKey' matches properties in your JSON.",
            style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: Colors.orangeAccent),
          ),
        );
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.greenAccent.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 12),
                const SizedBox(width: 4),
                Text(
                  "Parsed ${parsedOptions.length} option(s) successfully:",
                  style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: Colors.greenAccent, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: parsedOptions.map((opt) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: RevoTheme.background,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: RevoTheme.cardBorder),
                  ),
                  child: Text(
                    opt,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 9, color: Colors.white70),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    } catch (e) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.25)),
        ),
        child: Text(
          "Parsing error: ${e.toString()}",
          style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: Colors.redAccent),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final field = widget.field;
    final activeStepId = widget.activeStepId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: PropertyTextField(
                label: "Value Key",
                initialValue: field.dropdownkey ?? 'id',
                hint: "e.g. id, code",
                onChanged: (val) {
                  final updated = field.copyWith()..dropdownkey = val.trim().isEmpty ? null : val.trim();
                  ref.read(journeyConfigProvider.notifier)
                      .updateFieldInStep(activeStepId, field.id, updated);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PropertyTextField(
                label: "Display Value Key",
                initialValue: field.dropdownValue ?? 'title',
                hint: "e.g. title, name",
                onChanged: (val) {
                  final updated = field.copyWith()..dropdownValue = val.trim().isEmpty ? null : val.trim();
                  ref.read(journeyConfigProvider.notifier)
                      .updateFieldInStep(activeStepId, field.id, updated);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        PropertyTextField(
          label: "List Key (optional)",
          initialValue: field.dropdownListKey ?? '',
          hint: "e.g. data.items, result",
          onChanged: (val) {
            final updated = field.copyWith()..dropdownListKey = val.trim().isEmpty ? null : val.trim();
            ref.read(journeyConfigProvider.notifier)
                .updateFieldInStep(activeStepId, field.id, updated);
          },
        ),
        const SizedBox(height: 10),
        PropertyTextField(
          label: "Response JSON Data (Test/Preloaded)",
          initialValue: field.dropdowndata != null ? json.encode(field.dropdowndata) : '',
          hint: '[{"id": 1, "title": "Option One"}, {"id": 2, "title": "Option Two"}]',
          maxLines: 4,
          onChanged: (val) {
            final error = _validateJsonResponseData(val);
            widget.onTestDataErrorChanged(error);
            if (error == null) {
              try {
                if (val.trim().isEmpty) {
                  final updated = field.copyWith()..dropdowndata = null;
                  ref.read(journeyConfigProvider.notifier)
                      .updateFieldInStep(activeStepId, field.id, updated);
                } else {
                  final decoded = json.decode(val);
                  if (decoded is List) {
                    final updatedList = decoded.map((item) {
                      return item is Map ? Map<String, dynamic>.from(item) : item;
                    }).toList();
                    final updated = field.copyWith()..dropdowndata = updatedList;
                    ref.read(journeyConfigProvider.notifier)
                        .updateFieldInStep(activeStepId, field.id, updated);
                  } else if (decoded is Map) {
                    final updatedMap = Map<String, dynamic>.from(decoded);
                    final updated = field.copyWith()..dropdowndata = updatedMap;
                    ref.read(journeyConfigProvider.notifier)
                        .updateFieldInStep(activeStepId, field.id, updated);
                  }
                }
              } catch (_) {}
            }
          },
        ),
        if (widget.testDataError != null) ...[
          const SizedBox(height: 4),
          Text(widget.testDataError!, style: const TextStyle(fontFamily: 'Inter', color: Colors.redAccent, fontSize: 10)),
        ],
        const SizedBox(height: 10),
        Text(
          "Live Response Parsing Preview:",
          style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.bold, color: RevoTheme.textSecondary),
        ),
        const SizedBox(height: 6),
        _buildResponsePreview(field),
      ],
    );
  }
}
