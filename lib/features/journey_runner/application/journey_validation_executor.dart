import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../journey_builder/application/controllers/journey_validation_manager.dart';
import '../../journey_builder/domain/entities/journey_models.dart';

/// Runs sync + async validations defined in journey step JSON.
class JourneyValidationExecutor {
  JourneyValidationExecutor({
    http.Client? client,
    Duration timeout = const Duration(seconds: 15),
  })  : _client = client ?? http.Client(),
        _timeout = timeout;

  final http.Client _client;
  final Duration _timeout;

  Future<Map<String, String>> validateStep({
    required JourneyStep step,
    required Map<String, dynamic> formValues,
  }) async {
    final errors = <String, String>{};
    final flatFields = EngineHelper.flattenFields(step.fields);
    final fieldById = {for (final f in flatFields) f.id: f};

    for (final rule in step.validations) {
      if (!_shouldRunValidation(rule, formValues)) continue;

      final field = fieldById[rule.field];
      if (field == null) continue;
      if (!EngineHelper.isFieldVisible(field, formValues)) continue;

      final fieldVal = formValues[rule.field];
      final fieldText = fieldVal?.toString() ?? '';

      switch (rule.type) {
        case 'required':
          if (_isEmpty(fieldVal)) {
            errors[rule.field] = rule.message;
          }
          break;
        case 'regex':
          final pattern = rule.regexPattern ?? field.validationPattern;
          if (pattern != null &&
              pattern.isNotEmpty &&
              fieldText.isNotEmpty &&
              !RegExp(pattern).hasMatch(fieldText)) {
            errors[rule.field] = rule.message;
          }
          break;
        case 'dependency':
          if (rule.dependentField != null &&
              formValues[rule.dependentField]?.toString() ==
                  rule.dependentValue?.toString() &&
              _isEmpty(fieldVal)) {
            errors[rule.field] = rule.message;
          }
          break;
        case 'async':
          if (rule.validationUrl != null && rule.validationUrl!.isNotEmpty) {
            final asyncError = await _runAsyncValidation(
              rule,
              formValues,
            );
            if (asyncError != null) {
              errors[rule.field] = asyncError;
            }
          }
          break;
        default:
          break;
      }
    }

    // Field-level required flags not covered by explicit validations.
    for (final field in flatFields) {
      if (errors.containsKey(field.id)) continue;
      if (!field.required) continue;
      if (!EngineHelper.isFieldVisible(field, formValues)) continue;
      if (_isEmpty(formValues[field.id])) {
        errors[field.id] =
            field.errorMessage ?? '${field.label} is required';
      }
    }

    return errors;
  }

  bool _shouldRunValidation(
    StepValidation rule,
    Map<String, dynamic> formValues,
  ) {
    final condition = rule.condition;
    if (condition == null || condition.isEmpty) return true;

    final pseudo = StepCondition(
      type: 'visibleIf',
      field: condition['field']?.toString() ?? '',
      operator: condition['operator']?.toString() ?? 'equals',
      value: condition['value']?.toString() ?? '',
    );
    return EngineHelper.evaluateCondition(pseudo, formValues);
  }

  Future<String?> _runAsyncValidation(
    StepValidation rule,
    Map<String, dynamic> formValues,
  ) async {
    try {
      final uri = Uri.parse(
        _interpolate(rule.validationUrl!, formValues),
      );
      final response = await _client.get(uri).timeout(_timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return rule.message.isNotEmpty
            ? rule.message
            : 'Validation failed (${response.statusCode})';
      }

      final decoded = json.decode(response.body);
      if (decoded is Map) {
        final valid = decoded['valid'] ?? decoded['isValid'] ?? decoded['success'];
        if (valid == false) {
          return decoded['message']?.toString() ??
              rule.message.ifEmpty('Validation failed');
        }
      }
      return null;
    } catch (e) {
      return rule.message.isNotEmpty
          ? rule.message
          : 'Async validation error: $e';
    }
  }

  bool _isEmpty(dynamic value) {
    if (value == null) return true;
    if (value is String) return value.trim().isEmpty;
    if (value is List) return value.isEmpty;
    if (value is Map) return value.isEmpty;
    return false;
  }

  String _interpolate(String template, Map<String, dynamic> values) {
    return template.replaceAllMapped(RegExp(r'\{\{(\w+)\}\}'), (match) {
      final key = match.group(1)!;
      return Uri.encodeComponent(values[key]?.toString() ?? '');
    });
  }
}

extension _StringEmpty on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
