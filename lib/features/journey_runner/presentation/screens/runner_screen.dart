import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:revojourneytryone/features/journey_runner/presentation/screens/stepper.dart';
import 'package:revojourneytryone/features/journey_runner/presentation/screens/views/accordin_view.dart';
import 'package:revojourneytryone/features/journey_runner/presentation/screens/views/carousel_view.dart';
import 'package:revojourneytryone/features/journey_runner/presentation/screens/views/master_detail.dart';
import 'package:revojourneytryone/features/journey_runner/presentation/screens/runner_screen/runner_theme.dart';
import 'package:revojourneytryone/features/journey_runner/presentation/screens/runner_screen/runner_state.dart';
import 'package:revojourneytryone/features/journey_runner/presentation/screens/runner_screen/widgets/runner_header.dart';
import 'package:revojourneytryone/features/journey_runner/presentation/screens/runner_screen/widgets/runner_form_content.dart';
import 'package:revojourneytryone/features/journey_builder/domain/entities/journey_models.dart';
import 'package:revojourneytryone/features/journey_builder/presentation/providers/journey_provider.dart';
import 'package:revojourneytryone/features/journey_runner/application/journey_draft_store.dart';
import 'package:revojourneytryone/features/journey_runner/application/journey_execution_engine.dart';
import 'package:revojourneytryone/features/journey_runner/domain/journey_execution_models.dart';
import 'package:revojourneytryone/features/journey_runner/presentation/screens/views/split_view.dart';
import 'package:revojourneytryone/features/journey_runner/presentation/screens/views/focus_view.dart';
import 'package:revojourneytryone/features/journey_runner/presentation/screens/views/timeline_view.dart';
import 'package:revojourneytryone/features/journey_runner/presentation/screens/views/tabbed_view.dart';
import 'package:revojourneytryone/features/journey_runner/presentation/screens/views/wizard_view.dart';
import 'package:revojourneytryone/features/journey_runner/presentation/screens/views/review_view.dart';
import 'package:revojourneytryone/features/journey_runner/presentation/screens/views/dashboard_view.dart';
import 'package:revojourneytryone/features/journey_runner/presentation/screens/views/chat_view.dart';
import 'package:revojourneytryone/features/journey_runner/presentation/screens/views/kanban_view.dart';
import 'package:revojourneytryone/features/journey_runner/presentation/screens/views/stepper_view.dart';
import 'runner_screen/runner_dialogs.dart';
import 'runner_screen/runner_mobile_shell.dart';

export 'runner_screen/runner_state.dart' show RunnerLayoutStyle;

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class JourneyRunnerScreen extends ConsumerStatefulWidget {
  const JourneyRunnerScreen({super.key, this.initialStepId});
  final String? initialStepId;

  @override
  ConsumerState<JourneyRunnerScreen> createState() =>
      _JourneyRunnerScreenState();
}

class _JourneyRunnerScreenState extends ConsumerState<JourneyRunnerScreen> {
  final _engine = JourneyExecutionEngine();
  String? _runnerStepId;
  List<String> _stepHistory = const [];
  bool _isExecuting = false;
  final _formKey = GlobalKey<FormState>();
  final Map<String, String> _errors = {};

  // ── lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  void _bootstrap() {
    final cfg = ref.read(journeyConfigProvider);
    if (cfg.steps.isEmpty) return;
    final draft = ref.read(journeyDraftStoreProvider)[cfg.journeyName];
    if (draft != null) {
      _offerResume(cfg, draft);
      return;
    }
    final step = widget.initialStepId != null
        ? cfg.steps.firstWhere(
            (s) => s.id == widget.initialStepId!,
            orElse: () => cfg.steps.first,
          )
        : cfg.steps.first;
    setState(() {
      _runnerStepId = step.id;
      _stepHistory = const [];
    });
    ref.read(formValuesProvider.notifier).mergeStepDefaults(step);
  }

  Future<void> _offerResume(JourneyConfig cfg, JourneyDraft draft) async {
    if (!mounted) return;
    final resume = await showOfferResumeDialog(context, cfg, draft);
    if (!mounted) return;
    if (resume == true) {
      await _runAction(
        JourneyAction.resume,
        cfg.steps.firstWhere(
          (s) => s.id == draft.currentStepId,
          orElse: () => cfg.steps.first,
        ),
        cfg,
        draftToResume: draft,
      );
      return;
    }
    ref.read(journeyDraftStoreProvider.notifier).clearDraft(cfg.journeyName);
    final first = cfg.steps.first;
    setState(() {
      _runnerStepId = first.id;
      _stepHistory = const [];
    });
    ref.read(formValuesProvider.notifier).mergeStepDefaults(first);
  }

  void _syncRoute(String stepId) {
    if (!mounted) return;
    final cur = GoRouterState.of(context).uri.queryParameters['step'];
    if (cur == stepId) return;
    context.go(
      Uri(path: '/runner', queryParameters: {'step': stepId}).toString(),
    );
  }

  Future<void> _runAction(
    JourneyAction action,
    JourneyStep currentStep,
    JourneyConfig cfg, {
    JourneyDraft? draftToResume,
  }) async {
    if (_isExecuting || _engine.isLocked) return;
    setState(() {
      _isExecuting = true;
      if (action != JourneyAction.resume) _errors.clear();
    });

    final values = ref.read(formValuesProvider);
    final result = await _engine.execute(
      JourneyExecutionRequest(
        action: action,
        config: cfg,
        currentStep: currentStep,
        formValues: values,
        stepHistory: _stepHistory,
        draftToResume: draftToResume,
      ),
    );
    if (!mounted) return;
    setState(() => _isExecuting = false);

    if (result.status == JourneyExecutionStatus.busy) return;
    if (result.status == JourneyExecutionStatus.validationFailed) {
      setState(() {
        _errors
          ..clear()
          ..addAll(result.fieldErrors);
      });
      _snack(result.message ?? 'Validation failed.', isError: true);
      return;
    }
    if (result.status == JourneyExecutionStatus.apiFailed) {
      _snack(result.message ?? 'API execution failed.', isError: true);
      return;
    }
    if (result.status == JourneyExecutionStatus.notFound ||
        result.status == JourneyExecutionStatus.noDraft) {
      if (result.message != null) _snack(result.message!);
      return;
    }
    if (result.savedDraft != null) {
      ref
          .read(journeyDraftStoreProvider.notifier)
          .saveDraft(result.savedDraft!);
      _snack(result.message ?? 'Draft saved.');
      return;
    }

    ref
        .read(formValuesProvider.notifier)
        .restoreSession(
          values: result.formValues,
          step: result.targetStepId != null
              ? cfg.steps.firstWhere(
                  (s) => s.id == result.targetStepId,
                  orElse: () => currentStep,
                )
              : null,
        );

    if (result.journeyCompleted) {
      ref.read(journeyDraftStoreProvider.notifier).clearDraft(cfg.journeyName);
      _recordRun(cfg, currentStep, result.formValues);
      _showCompletion();
      return;
    }
    if (result.targetStepId != null) {
      setState(() {
        _runnerStepId = result.targetStepId;
        _stepHistory = result.stepHistory;
      });
      _syncRoute(result.targetStepId!);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: isError ? RunnerTheme.error : RunnerTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _recordRun(
    JourneyConfig cfg,
    JourneyStep step,
    Map<String, dynamic> vals,
  ) {
    final runs = ref.read(journeyRunsProvider);
    ref.read(journeyRunsProvider.notifier).addRun({
      'id': 'RUN-${1050 + runs.length}',
      'journeyName': cfg.journeyName,
      'user':
          vals['email']?.toString() ??
          vals['mobile']?.toString() ??
          'anonymous@revo.com',
      'status': 'Completed',
      'currentStep': step.title,
      'progress': 1.0,
      'stepsCount': '${cfg.steps.length}/${cfg.steps.length}',
      'started': 'Just now',
      'data': Map<String, dynamic>.from(vals),
    });
  }

  void _showCompletion() {
    showCompletionDialog(
      context,
      onBackToDashboard: () {
        context.pop();
      },
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final cfg = ref.watch(journeyConfigProvider);
    if (cfg.steps.isEmpty) {
      return Scaffold(
        backgroundColor: RunnerTheme.bg,
        body: Center(
          child: Text(
            'No steps defined.',
            style: GoogleFonts.poppins(color: RunnerTheme.textMid),
          ),
        ),
      );
    }

    final activeId = _runnerStepId ?? cfg.steps.first.id;
    final activeIdx = cfg.steps.indexWhere((s) => s.id == activeId);
    final activeStep = activeIdx != -1 ? cfg.steps[activeIdx] : cfg.steps.first;
    final formValues = ref.watch(formValuesProvider);
    final showSubmit = _engine.shouldShowSubmit(activeStep, formValues);

    final screenW = MediaQuery.of(context).size.width;
    final isMobile = screenW < RunnerTheme.mobileBreak;
    final layoutStyle = ref.watch(runnerLayoutStyleProvider);

    return Scaffold(
      backgroundColor: RunnerTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            RunnerHeader(
              cfg: cfg,
              layoutStyle: layoutStyle,
              onStyleChanged: (style) {
                ref.read(runnerLayoutStyleProvider.notifier).state = style;
              },
              onBackPressed: () => context.pop(),
              onClosePressed: () => context.pop(),
            ),

            // Top Stepper Timeline (Only shown in Split View on desktop)
            if (layoutStyle == RunnerLayoutStyle.split && !isMobile)
              JourneyTimeline(
                steps: cfg.steps,
                activeIndex: activeIdx,
                onStepTap: (i) {
                  if (i <= activeIdx) {
                    _runAction(JourneyAction.previous, cfg.steps[i], cfg);
                  }
                },
              ),

            // Main Dynamic Layout View Shell
            Expanded(
              child: isMobile
                  ? _buildMobileLayout(cfg, activeStep, activeIdx, formValues, showSubmit)
                  : _buildLayoutShell(
                      cfg,
                      activeStep,
                      activeIdx,
                      formValues,
                      showSubmit,
                      layoutStyle,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayoutShell(
    JourneyConfig cfg,
    JourneyStep activeStep,
    int activeIdx,
    Map<String, dynamic> formValues,
    bool showSubmit,
    RunnerLayoutStyle layoutStyle,
  ) {
    Widget buildFormContent(BuildContext ctx, {bool isMobile = false}) {
      return RunnerFormContent(
        cfg: cfg,
        activeStep: activeStep,
        activeIdx: activeIdx,
        formValues: formValues,
        errors: _errors,
        showSubmit: showSubmit,
        isMobile: isMobile,
        isExecuting: _isExecuting,
        stepHistory: _stepHistory,
        formKey: _formKey,
        runAction: _runAction,
        showSnack: _snack,
      );
    }

    Widget buildBottomBar() {
      return Container(
        decoration: const BoxDecoration(
          color: RunnerTheme.white,
          border: Border(top: BorderSide(color: RunnerTheme.border)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 13,
              color: RunnerTheme.textLight,
            ),
            const SizedBox(width: 6),
            Text(
              'You can save your progress and continue later',
              style: GoogleFonts.poppins(fontSize: 11, color: RunnerTheme.textMid),
            ),
          ],
        ),
      );
    }

    switch (layoutStyle) {
      case RunnerLayoutStyle.split:
        return SplitRunnerView(
          cfg: cfg,
          activeStep: activeStep,
          activeIdx: activeIdx,
          formContentBuilder: buildFormContent,
          bottomBarBuilder: buildBottomBar,
        );
      case RunnerLayoutStyle.focus:
        return FocusRunnerView(
          cfg: cfg,
          activeStep: activeStep,
          activeIdx: activeIdx,
          formContentBuilder: buildFormContent,
          bottomBarBuilder: buildBottomBar,
        );
      case RunnerLayoutStyle.timeline:
        return TimelineRunnerView(
          cfg: cfg,
          activeStep: activeStep,
          activeIdx: activeIdx,
          formValues: formValues,
          formContentBuilder: buildFormContent,
          bottomBarBuilder: buildBottomBar,
          onStepTap: (idx) {
            if (idx <= activeIdx) {
              _runAction(JourneyAction.previous, cfg.steps[idx], cfg);
            }
          },
        );
      case RunnerLayoutStyle.tabbed:
        return TabbedRunnerView(
          cfg: cfg,
          activeStep: activeStep,
          activeIdx: activeIdx,
          formValues: formValues,
          formContentBuilder: buildFormContent,
          bottomBarBuilder: buildBottomBar,
          onStepTap: (idx) {
            if (idx <= activeIdx) {
              _runAction(JourneyAction.previous, cfg.steps[idx], cfg);
            }
          },
        );
      case RunnerLayoutStyle.curasole:
        return CarouselRunnerView(
          cfg: cfg,
          activeStep: activeStep,
          activeIdx: activeIdx,
          formContentBuilder: buildFormContent,
          bottomBarBuilder: buildBottomBar,
          onStepTap: (idx) {
            if (idx <= activeIdx) {
              _runAction(JourneyAction.previous, cfg.steps[idx], cfg);
            }
          },
        );
      case RunnerLayoutStyle.masterdetail:
        return MasterDetailRunnerView(
          cfg: cfg,
          activeStep: activeStep,
          activeIdx: activeIdx,
          formContentBuilder: buildFormContent,
          bottomBarBuilder: buildBottomBar,
          onStepTap: (idx) {
            if (idx <= activeIdx) {
              _runAction(JourneyAction.previous, cfg.steps[idx], cfg);
            }
          },
        );
      case RunnerLayoutStyle.accordion:
        return AccordionRunnerView(
          cfg: cfg,
          activeStep: activeStep,
          activeIdx: activeIdx,
          formContentBuilder: buildFormContent,
          bottomBarBuilder: buildBottomBar,
          onStepTap: (idx) {
            _runAction(JourneyAction.previous, cfg.steps[idx], cfg);
          },
        );
      case RunnerLayoutStyle.wizard:
        return WizardRunnerView(
          cfg: cfg,
          activeStep: activeStep,
          activeIdx: activeIdx,
          formContentBuilder: buildFormContent,
          bottomBarBuilder: buildBottomBar,
          onStepTap: (idx) {
            if (idx <= activeIdx) {
              _runAction(JourneyAction.previous, cfg.steps[idx], cfg);
            }
          },
        );
      case RunnerLayoutStyle.review:
        return ReviewRunnerView(
          cfg: cfg,
          activeStep: activeStep,
          activeIdx: activeIdx,
          formValues: formValues,
          formContentBuilder: buildFormContent,
          bottomBarBuilder: buildBottomBar,
          onStepTap: (idx) {
            if (idx <= activeIdx) {
              _runAction(JourneyAction.previous, cfg.steps[idx], cfg);
            }
          },
        );
      case RunnerLayoutStyle.dashboard:
        return DashboardRunnerView(
          cfg: cfg,
          activeStep: activeStep,
          activeIdx: activeIdx,
          formContentBuilder: buildFormContent,
          bottomBarBuilder: buildBottomBar,
          onStepTap: (idx) {
            if (idx <= activeIdx) {
              _runAction(JourneyAction.previous, cfg.steps[idx], cfg);
            }
          },
        );
      case RunnerLayoutStyle.chat:
        return ChatRunnerView(
          cfg: cfg,
          activeStep: activeStep,
          activeIdx: activeIdx,
          formValues: formValues,
          formContentBuilder: buildFormContent,
          bottomBarBuilder: buildBottomBar,
          onStepTap: (idx) {
            if (idx <= activeIdx) {
              _runAction(JourneyAction.previous, cfg.steps[idx], cfg);
            }
          },
        );
      case RunnerLayoutStyle.kanban:
        return KanbanRunnerView(
          cfg: cfg,
          activeStep: activeStep,
          activeIdx: activeIdx,
          formContentBuilder: buildFormContent,
          bottomBarBuilder: buildBottomBar,
          onStepTap: (idx) {
            if (idx <= activeIdx) {
              _runAction(JourneyAction.previous, cfg.steps[idx], cfg);
            }
          },
        );
      case RunnerLayoutStyle.stepper:
        return StepperRunnerView(
          cfg: cfg,
          activeStep: activeStep,
          activeIdx: activeIdx,
          formContentBuilder: buildFormContent,
          bottomBarBuilder: buildBottomBar,
          onStepTap: (idx) {
            if (idx <= activeIdx) {
              _runAction(JourneyAction.previous, cfg.steps[idx], cfg);
            }
          },
        );
      case RunnerLayoutStyle.form:
        return _buildMobileLayout(cfg, activeStep, activeIdx, formValues, showSubmit);
    }
  }

  Widget _buildMobileLayout(
    JourneyConfig cfg,
    JourneyStep activeStep,
    int activeIdx,
    Map<String, dynamic> formValues,
    bool showSubmit,
  ) {
    return RunnerMobileShell(
      cfg: cfg,
      activeStep: activeStep,
      activeIdx: activeIdx,
      formValues: formValues,
      showSubmit: showSubmit,
      errors: _errors,
      isExecuting: _isExecuting,
      stepHistory: _stepHistory,
      formKey: _formKey,
      runAction: _runAction,
      showSnack: _snack,
    );
  }

}
