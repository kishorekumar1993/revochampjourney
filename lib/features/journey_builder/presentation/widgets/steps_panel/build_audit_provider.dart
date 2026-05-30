import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revojourneytryone/features/journey_builder/application/controllers/journey_controller.dart';

class BuildAuditResult {
  final List<String> errors;
  final List<String> warnings;

  const BuildAuditResult({
    required this.errors,
    required this.warnings,
  });
}

/// Memoized provider that recalculates the audit ONLY when journeyConfigProvider changes.
final buildAuditProvider = Provider.autoDispose<BuildAuditResult>((ref) {
  final config = ref.watch(journeyConfigProvider);
  final List<String> buildErrors = [];
  final List<String> buildWarnings = [];
  final allFieldIds = <String>{};
  final duplicatedFieldIds = <String>{};

  for (final s in config.steps) {
    if (s.fields.isEmpty) {
      buildWarnings.add("Step '${s.title}' has no fields on the canvas.");
    }
    for (final f in s.fields) {
      if (allFieldIds.contains(f.id)) {
        duplicatedFieldIds.add(f.id);
      } else {
        allFieldIds.add(f.id);
      }
      if (f.label.trim().isEmpty) {
        buildWarnings.add("Field '${f.id}' in Step '${s.title}' has an empty label.");
      }
      if ((f.type == 'dropdown' || f.type == 'radio' || f.type == 'multi_select') &&
          f.useStaticOptions &&
          (f.staticOptions == null || f.staticOptions!.isEmpty)) {
        buildWarnings.add("Dropdown/Radio field '${f.id}' has static options enabled but none configured.");
      }
      if (f.type == 'api_dropdown' && (f.dropdownApiUrl == null || f.dropdownApiUrl!.isEmpty)) {
        buildErrors.add("API Dropdown '${f.id}' is missing its Endpoint URL.");
      }
    }

    // Check Step Conditions
    for (final cond in s.conditions) {
      if (cond.field.isNotEmpty && !allFieldIds.contains(cond.field)) {
        buildErrors.add("Step '${s.title}' condition references non-existent field ID '${cond.field}'.");
      }
      if (cond.type == 'nextStepIf' && (cond.targetStep == null || !config.steps.any((step) => step.id == cond.targetStep))) {
        buildErrors.add("Step '${s.title}' branch target step '${cond.targetStep}' does not exist.");
      }
    }

    // Check Step Validations
    for (final val in s.validations) {
      if (val.field.isNotEmpty && !s.fields.any((f) => f.id == val.field)) {
        buildErrors.add("Step '${s.title}' validation references non-existent field ID '${val.field}'.");
      }
      if (val.type == 'dependency' && val.dependentField != null && !s.fields.any((f) => f.id == val.dependentField)) {
        buildErrors.add("Step '${s.title}' dependency validation references non-existent dependent field '${val.dependentField}'.");
      }
    }

    // Check Step APIs
    for (final api in s.apiCalls) {
      if (api.url.trim().isEmpty) {
        buildErrors.add("Step '${s.title}' has an API action with an empty Endpoint URL.");
      }
    }
  }
  for (final dup in duplicatedFieldIds) {
    buildErrors.add("Duplicate field ID '$dup' found across steps.");
  }

  for (int i = 0; i < config.steps.length; i++) {
    final step = config.steps[i];
    if (step.nextStep != null && step.nextStep!.isNotEmpty) {
      if (!config.steps.any((s) => s.id == step.nextStep)) {
        buildErrors.add("Step '${step.title}' next transition step '${step.nextStep}' does not exist.");
      }
    }
    if (i < config.steps.length - 1) {
      final next = step.nextStep;
      final hasBranch = step.conditions.any((c) => c.type == 'nextStepIf');
      if ((next == null || next.trim().isEmpty) && !hasBranch) {
        buildWarnings.add("Step '${step.title}' has no transition link to follow next.");
      }
    }
  }

  return BuildAuditResult(errors: buildErrors, warnings: buildWarnings);
});
