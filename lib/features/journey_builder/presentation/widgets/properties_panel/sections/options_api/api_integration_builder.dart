import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/features/journey_builder/domain/entities/journey_models.dart';
import 'package:revojourneytryone/features/journey_builder/application/controllers/journey_controller.dart';
import '../../property_fields.dart';

class ApiIntegrationBuilder extends ConsumerStatefulWidget {
  final JourneyField field;
  final String activeStepId;
  final int apiTabIndex;
  final String? headersError;
  final ValueChanged<String?> onHeadersErrorChanged;

  const ApiIntegrationBuilder({
    super.key,
    required this.field,
    required this.activeStepId,
    required this.apiTabIndex,
    required this.headersError,
    required this.onHeadersErrorChanged,
  });

  @override
  ConsumerState<ApiIntegrationBuilder> createState() => _ApiIntegrationBuilderState();
}

class _ApiIntegrationBuilderState extends ConsumerState<ApiIntegrationBuilder> {
  String? _validateJsonMap(String val) {
    if (val.trim().isEmpty) return null;
    try {
      final decoded = json.decode(val);
      if (decoded is! Map) return "Must be a valid JSON Object (e.g. {\"key\": \"value\"})";
      return null;
    } catch (e) {
      return "Invalid JSON syntax: ${e.toString()}";
    }
  }

  Widget _buildMethodSelector(JourneyField field, String activeStepId) {
    final methods = ["GET", "POST", "PUT", "DELETE"];
    final currentMethod = field.dropdownApiMethod ?? "GET";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("API HTTP Method", style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: RevoTheme.textSecondary)),
        const SizedBox(height: 4),
        Row(
          children: methods.map((method) {
            final isSelected = currentMethod.toUpperCase() == method;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: InkWell(
                  onTap: () {
                    final updated = field.copyWith()..dropdownApiMethod = method;
                    ref.read(journeyConfigProvider.notifier)
                        .updateFieldInStep(activeStepId, field.id, updated);
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? RevoTheme.primary.withValues(alpha: 0.15) : RevoTheme.background,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected ? RevoTheme.primaryLight : RevoTheme.cardBorder,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        method,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? RevoTheme.primaryLight : RevoTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final field = widget.field;
    final activeStepId = widget.activeStepId;

    if (widget.apiTabIndex == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PropertyTextField(
            label: "API URL Path",
            initialValue: field.dropdownApiUrl ?? '',
            hint: "https://api.example.com/dropdown-data",
            onChanged: (val) {
              final updated = field.copyWith()..dropdownApiUrl = val.trim().isEmpty ? null : val.trim();
              ref.read(journeyConfigProvider.notifier)
                  .updateFieldInStep(activeStepId, field.id, updated);
            },
          ),
          const SizedBox(height: 10),
          _buildMethodSelector(field, activeStepId),
          const SizedBox(height: 10),
          PropertyTextField(
            label: "URL / Query Parameter Key",
            initialValue: field.apiParam ?? '',
            hint: "e.g. tenantId or searchKey",
            onChanged: (val) {
              final updated = field.copyWith()..apiParam = val.trim().isEmpty ? null : val.trim();
              ref.read(journeyConfigProvider.notifier)
                  .updateFieldInStep(activeStepId, field.id, updated);
            },
          ),
        ],
      );
    } else if (widget.apiTabIndex == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PropertyTextField(
            label: "API Headers (JSON Map)",
            initialValue: field.dropdownApiHeaders != null ? json.encode(field.dropdownApiHeaders) : '',
            hint: '{"Authorization": "Bearer token", "Accept": "application/json"}',
            maxLines: 3,
            onChanged: (val) {
              final error = _validateJsonMap(val);
              widget.onHeadersErrorChanged(error);
              if (error == null) {
                try {
                  if (val.trim().isEmpty) {
                    final updated = field.copyWith()..dropdownApiHeaders = null;
                    ref.read(journeyConfigProvider.notifier)
                        .updateFieldInStep(activeStepId, field.id, updated);
                  } else {
                    final decoded = json.decode(val);
                    if (decoded is Map) {
                      final updatedMap = Map<String, dynamic>.from(decoded);
                      final updated = field.copyWith()..dropdownApiHeaders = updatedMap;
                      ref.read(journeyConfigProvider.notifier)
                          .updateFieldInStep(activeStepId, field.id, updated);
                    }
                  }
                } catch (_) {}
              }
            },
          ),
          if (widget.headersError != null) ...[
            const SizedBox(height: 4),
            Text(widget.headersError!, style: const TextStyle(fontFamily: 'Inter', color: Colors.redAccent, fontSize: 10)),
          ],
          const SizedBox(height: 10),
          PropertyTextField(
            label: "Request Body (JSON String)",
            initialValue: field.dropdownApiBody ?? '',
            hint: '{"status": "active", "filter": "users"}',
            maxLines: 3,
            onChanged: (val) {
              final updated = field.copyWith()..dropdownApiBody = val.trim().isEmpty ? null : val.trim();
              ref.read(journeyConfigProvider.notifier)
                  .updateFieldInStep(activeStepId, field.id, updated);
            },
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}
