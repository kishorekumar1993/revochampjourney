import '../../journey_builder/domain/entities/journey_models.dart';

enum JourneyAction { next, previous, submit, saveDraft, resume }

enum JourneyExecutionStatus {
  success,
  validationFailed,
  apiFailed,
  busy,
  notFound,
  noDraft,
}

class JourneyExecutionRequest {
  final JourneyAction action;
  final JourneyConfig config;
  final JourneyStep currentStep;
  final Map<String, dynamic> formValues;
  final List<String> stepHistory;
  final JourneyDraft? draftToResume;

  const JourneyExecutionRequest({
    required this.action,
    required this.config,
    required this.currentStep,
    required this.formValues,
    this.stepHistory = const [],
    this.draftToResume,
  });
}

class JourneyExecutionResult {
  final JourneyExecutionStatus status;
  final String? message;
  final Map<String, String> fieldErrors;
  final String? targetStepId;
  final List<String> stepHistory;
  final Map<String, dynamic> formValues;
  final bool journeyCompleted;
  final JourneyDraft? savedDraft;

  const JourneyExecutionResult({
    required this.status,
    this.message,
    this.fieldErrors = const {},
    this.targetStepId,
    this.stepHistory = const [],
    this.formValues = const {},
    this.journeyCompleted = false,
    this.savedDraft,
  });

  factory JourneyExecutionResult.busy() => const JourneyExecutionResult(
        status: JourneyExecutionStatus.busy,
        message: 'Action already in progress',
      );

  factory JourneyExecutionResult.validation({
    required Map<String, String> fieldErrors,
    String? message,
  }) =>
      JourneyExecutionResult(
        status: JourneyExecutionStatus.validationFailed,
        message: message ?? 'Please correct validation errors on this page.',
        fieldErrors: fieldErrors,
      );

  factory JourneyExecutionResult.apiFailure(String message) =>
      JourneyExecutionResult(
        status: JourneyExecutionStatus.apiFailed,
        message: message,
      );

  factory JourneyExecutionResult.success({
    String? targetStepId,
    List<String>? stepHistory,
    Map<String, dynamic>? formValues,
    bool journeyCompleted = false,
    JourneyDraft? savedDraft,
    String? message,
  }) =>
      JourneyExecutionResult(
        status: JourneyExecutionStatus.success,
        message: message,
        targetStepId: targetStepId,
        stepHistory: stepHistory ?? const [],
        formValues: formValues ?? const {},
        journeyCompleted: journeyCompleted,
        savedDraft: savedDraft,
      );

  bool get isSuccess => status == JourneyExecutionStatus.success;
}

class JourneyDraft {
  final String journeyName;
  final String journeyVersion;
  final String currentStepId;
  final Map<String, dynamic> formValues;
  final List<String> stepHistory;
  final DateTime savedAt;

  const JourneyDraft({
    required this.journeyName,
    required this.journeyVersion,
    required this.currentStepId,
    required this.formValues,
    required this.stepHistory,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
        'journeyName': journeyName,
        'journeyVersion': journeyVersion,
        'currentStepId': currentStepId,
        'formValues': formValues,
        'stepHistory': stepHistory,
        'savedAt': savedAt.toIso8601String(),
      };

  factory JourneyDraft.fromJson(Map<String, dynamic> json) => JourneyDraft(
        journeyName: json['journeyName']?.toString() ?? '',
        journeyVersion: json['journeyVersion']?.toString() ?? '1.0.0',
        currentStepId: json['currentStepId']?.toString() ?? '',
        formValues: Map<String, dynamic>.from(json['formValues'] as Map? ?? {}),
        stepHistory: (json['stepHistory'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        savedAt: DateTime.tryParse(json['savedAt']?.toString() ?? '') ??
            DateTime.now(),
      );
}
