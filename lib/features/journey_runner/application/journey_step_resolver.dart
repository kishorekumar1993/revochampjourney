import '../../journey_builder/application/controllers/journey_controller.dart';
import '../../journey_builder/application/controllers/journey_validation_manager.dart';
import '../../journey_builder/domain/entities/journey_models.dart';

/// Resolves step transitions from journey JSON (`nextStep`, `nextStepIf`, history).
class JourneyStepResolver {
  JourneyStepResolver({Map<String, JourneyStep>? stepById})
      : _stepById = stepById;

  final Map<String, JourneyStep>? _stepById;

  Map<String, JourneyStep> buildIndex(List<JourneyStep> steps) {
    return {for (final step in steps) step.id: step};
  }

  JourneyStep? findStep(JourneyConfig config, String stepId) {
    final index = _stepById ?? buildIndex(config.steps);
    return index[stepId];
  }

  /// Resolves next step using `nextStepIf` conditions first, then `nextStep`.
  String? resolveNextStepId(
    JourneyStep step,
    Map<String, dynamic> formValues,
  ) {
    String? nextId = step.nextStep;

    for (final cond in step.conditions) {
      if (cond.type != 'nextStepIf') continue;
      if (cond.targetStep == null || cond.targetStep!.isEmpty) continue;
      if (EngineHelper.evaluateCondition(cond, formValues)) {
        nextId = cond.targetStep;
      }
    }

    if (nextId != null && nextId.isEmpty) return null;
    return nextId;
  }

  bool isTerminalStep(JourneyStep step, Map<String, dynamic> formValues) {
    return resolveNextStepId(step, formValues) == null;
  }

  String? resolvePreviousStepId(List<String> stepHistory) {
    if (stepHistory.isEmpty) return null;
    return stepHistory.last;
  }

  List<String> pushHistory(List<String> history, String currentStepId) {
    if (history.isNotEmpty && history.last == currentStepId) return history;
    return [...history, currentStepId];
  }

  List<String> popHistory(List<String> history) {
    if (history.isEmpty) return history;
    return history.sublist(0, history.length - 1);
  }

  double progressForStep(JourneyConfig config, String stepId) {
    if (config.steps.isEmpty) return 0;
    final index = config.steps.indexWhere((s) => s.id == stepId);
    if (index == -1) return 0;
    return (index + 1) / config.steps.length;
  }
}
