import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revojourneytryone/features/journey_builder/domain/entities/journey_models.dart';

// Centralized dynamic form state mapping provider (Step Values)
// Map<String, dynamic> supports strings, booleans, lists (repeater/grid rows), nested objects
class FormValuesNotifier extends StateNotifier<Map<String, dynamic>> {
  FormValuesNotifier() : super({});

  void updateValue(String fieldId, dynamic value) {
    state = Map<String, dynamic>.of(state)..[fieldId] = value;
  }

  void updateValueByPath(List<dynamic> path, dynamic value) {
    if (path.isEmpty) return;
    final newState = Map<String, dynamic>.from(state);
    _setNested(newState, path, value);
    state = newState;
  }

  void _setNested(
    Map<String, dynamic> current,
    List<dynamic> path,
    dynamic value,
  ) {
    if (path.length == 1) {
      current[path.first.toString()] = value;
      return;
    }

    final key = path.first.toString();
    final nextKey = path[1];

    if (nextKey is int) {
      if (!current.containsKey(key) || current[key] is! List) {
        current[key] = [];
      }
      final list = List<dynamic>.from(current[key]);
      while (list.length <= nextKey) {
        list.add(<String, dynamic>{});
      }
      if (path.length == 2) {
        list[nextKey] = value;
      } else {
        if (list[nextKey] is! Map) list[nextKey] = <String, dynamic>{};
        final nextMap = Map<String, dynamic>.from(list[nextKey]);
        _setNested(nextMap, path.sublist(2), value);
        list[nextKey] = nextMap;
      }
      current[key] = list;
    } else {
      if (!current.containsKey(key) || current[key] is! Map) {
        current[key] = <String, dynamic>{};
      }
      final nextMap = Map<String, dynamic>.from(current[key]);
      _setNested(nextMap, path.sublist(1), value);
      current[key] = nextMap;
    }
  }

  void clear() {
    state = {};
  }

  void resetWithDefaults(JourneyStep step) {
    mergeStepDefaults(step, replaceExisting: true);
  }

  /// Preserves journey-wide values; only fills missing keys from step defaults.
  void mergeStepDefaults(JourneyStep step, {bool replaceExisting = false}) {
    if (replaceExisting) {
      state = _defaultsForStep(step);
      return;
    }
    final merged = Map<String, dynamic>.from(state);
    for (final f in step.flattenedFields) {
      if (f.defaultValue != null && !merged.containsKey(f.id)) {
        merged[f.id] = f.defaultValue!;
      }
    }
    state = merged;
  }

  void restoreSession({
    required Map<String, dynamic> values,
    JourneyStep? step,
  }) {
    state = Map<String, dynamic>.from(values);
    if (step != null) {
      mergeStepDefaults(step);
    }
  }

  Map<String, dynamic> _defaultsForStep(JourneyStep step) {
    final defaults = <String, dynamic>{};
    for (final f in step.flattenedFields) {
      if (f.defaultValue != null) {
        defaults[f.id] = f.defaultValue!;
      }
    }
    return defaults;
  }
}

final formValuesProvider =
    StateNotifierProvider<FormValuesNotifier, Map<String, dynamic>>((ref) {
      return FormValuesNotifier();
    });
