import '../../journey_builder/domain/entities/journey_models.dart';
import '../domain/journey_execution_models.dart';
import 'journey_runtime_api_executor.dart';
import 'journey_step_resolver.dart';
import 'journey_validation_executor.dart';

/// Central journey runtime pipeline:
/// validate → API → resolve step → state transition.
class JourneyExecutionEngine {
  JourneyExecutionEngine({
    JourneyValidationExecutor? validationExecutor,
    JourneyRuntimeApiExecutor? apiExecutor,
    JourneyStepResolver? stepResolver,
  })  : _validationExecutor =
            validationExecutor ?? JourneyValidationExecutor(),
        _apiExecutor = apiExecutor ?? JourneyRuntimeApiExecutor(),
        _stepResolver = stepResolver ?? JourneyStepResolver();

  final JourneyValidationExecutor _validationExecutor;
  final JourneyRuntimeApiExecutor _apiExecutor;
  final JourneyStepResolver _stepResolver;

  bool _locked = false;

  bool get isLocked => _locked;

  Future<JourneyExecutionResult> execute(
    JourneyExecutionRequest request,
  ) async {
    if (_locked) return JourneyExecutionResult.busy();
    _locked = true;

    try {
      switch (request.action) {
        case JourneyAction.next:
        case JourneyAction.submit:
          return await _executeForward(request);
        case JourneyAction.previous:
          return _executePrevious(request);
        case JourneyAction.saveDraft:
          return _executeSaveDraft(request);
        case JourneyAction.resume:
          return _executeResume(request);
      }
    } on JourneyApiFailure catch (e) {
      return JourneyExecutionResult.apiFailure(e.message);
    } catch (e) {
      return JourneyExecutionResult.apiFailure(e.toString());
    } finally {
      _locked = false;
    }
  }

  Future<JourneyExecutionResult> _executeForward(
    JourneyExecutionRequest request,
  ) async {
    final step = request.currentStep;
    final values = Map<String, dynamic>.from(request.formValues);

    final fieldErrors = await _validationExecutor.validateStep(
      step: step,
      formValues: values,
    );
    if (fieldErrors.isNotEmpty) {
      return JourneyExecutionResult.validation(fieldErrors: fieldErrors);
    }

    final trigger =
        request.action == JourneyAction.submit ? 'submit' : 'next';

    await _apiExecutor.executeStepApis(
      step: step,
      formValues: values,
      trigger: trigger,
    );

    final nextStepId = _stepResolver.resolveNextStepId(step, values);

    if (nextStepId == null ||
        request.action == JourneyAction.submit ||
        _stepResolver.isTerminalStep(step, values)) {
      return JourneyExecutionResult.success(
        formValues: values,
        journeyCompleted: true,
        message: 'Journey completed successfully.',
      );
    }

    final nextStep = _stepResolver.findStep(request.config, nextStepId);
    if (nextStep == null) {
      return JourneyExecutionResult(
        status: JourneyExecutionStatus.notFound,
        message: "Next step '$nextStepId' was not found in journey config.",
        formValues: values,
      );
    }

    final history = _stepResolver.pushHistory(
      request.stepHistory,
      step.id,
    );

    return JourneyExecutionResult.success(
      targetStepId: nextStepId,
      stepHistory: history,
      formValues: values,
      journeyCompleted: false,
    );
  }

  JourneyExecutionResult _executePrevious(
    JourneyExecutionRequest request,
  ) {
    final previousId =
        _stepResolver.resolvePreviousStepId(request.stepHistory);
    if (previousId == null) {
      return JourneyExecutionResult(
        status: JourneyExecutionStatus.notFound,
        message: 'No previous step in history.',
        formValues: request.formValues,
        stepHistory: request.stepHistory,
      );
    }

    final previousStep = _stepResolver.findStep(request.config, previousId);
    if (previousStep == null) {
      return JourneyExecutionResult(
        status: JourneyExecutionStatus.notFound,
        message: "Previous step '$previousId' was not found.",
        formValues: request.formValues,
        stepHistory: request.stepHistory,
      );
    }

    return JourneyExecutionResult.success(
      targetStepId: previousId,
      stepHistory: _stepResolver.popHistory(request.stepHistory),
      formValues: request.formValues,
    );
  }

  JourneyExecutionResult _executeSaveDraft(
    JourneyExecutionRequest request,
  ) {
    final draft = JourneyDraft(
      journeyName: request.config.journeyName,
      journeyVersion: request.config.version,
      currentStepId: request.currentStep.id,
      formValues: Map<String, dynamic>.from(request.formValues),
      stepHistory: List<String>.from(request.stepHistory),
      savedAt: DateTime.now(),
    );

    return JourneyExecutionResult.success(
      targetStepId: request.currentStep.id,
      stepHistory: request.stepHistory,
      formValues: request.formValues,
      savedDraft: draft,
      message: 'Draft saved.',
    );
  }

  JourneyExecutionResult _executeResume(
    JourneyExecutionRequest request,
  ) {
    final draft = request.draftToResume;
    if (draft == null) {
      return const JourneyExecutionResult(
        status: JourneyExecutionStatus.noDraft,
        message: 'No draft available to resume.',
      );
    }

    if (draft.journeyName != request.config.journeyName) {
      return const JourneyExecutionResult(
        status: JourneyExecutionStatus.noDraft,
        message: 'Draft belongs to a different journey.',
      );
    }

    final step = _stepResolver.findStep(request.config, draft.currentStepId);
    if (step == null) {
      return JourneyExecutionResult(
        status: JourneyExecutionStatus.notFound,
        message: "Draft step '${draft.currentStepId}' no longer exists.",
      );
    }

    return JourneyExecutionResult.success(
      targetStepId: draft.currentStepId,
      stepHistory: List<String>.from(draft.stepHistory),
      formValues: Map<String, dynamic>.from(draft.formValues),
      message: 'Draft resumed.',
    );
  }

  bool shouldShowSubmit(JourneyStep step, Map<String, dynamic> values) {
    return _stepResolver.isTerminalStep(step, values);
  }
}
