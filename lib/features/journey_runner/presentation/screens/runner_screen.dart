import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:revojourneytryone/features/journey_runner/presentation/screens/stepper.dart';
import 'package:revojourneytryone/features/journey_runner/presentation/screens/views/accordin_view.dart';
import 'package:revojourneytryone/features/journey_runner/presentation/screens/views/carousel_view.dart';
import 'package:revojourneytryone/features/journey_runner/presentation/screens/views/master_detail.dart';
import 'package:revojourneytryone/features/journey_runner/presentation/screens/views/tiled_runner_view.dart';
import '../../../journey_builder/data/models.dart';
import '../../../journey_builder/presentation/providers/journey_provider.dart';
import '../../application/journey_draft_store.dart';
import '../../application/journey_execution_engine.dart';
import '../../domain/journey_execution_models.dart';
import 'advanced_formula_field_widget.dart';
import 'views/split_view.dart';
import 'views/focus_view.dart';
import 'views/timeline_view.dart';
import 'views/tabbed_view.dart';

enum RunnerLayoutStyle {
  split,
  focus,
  timeline,
  tabbed,
  curasole,
  masterdetail,
  accordion,
  form,
}

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────
class _IT {
  static const brand = Color(0xFF5B4FCF);
  static const brandLight = Color(0xFF7C72E0);
  static const brandSurface = Color(0xFFEEECFD);
  static const bg = Color(0xFFF0F0FF);
  static const white = Color(0xFFFFFFFF);
  static const textDark = Color(0xFF1A1A2E);
  static const textMid = Color(0xFF6B7280);
  static const textLight = Color(0xFFB0B4C8);
  static const border = Color(0xFFE4E6F0);
  static const error = Color(0xFFEF4444);
  static const success = Color(0xFF22C55E);
  static const inputBg = Color(0xFFFAFAFF);
  static const leftPanelBg = Color(0xFFF7F5FF);
  static const dividerColor = Color(0xFFF0F0FF);

  // breakpoint: below this width → mobile layout (no left panel, no timeline)
  static const double mobileBreak = 640;
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED INPUT DECORATION
// ─────────────────────────────────────────────────────────────────────────────
InputDecoration _fd({
  required String label,
  String? hint,
  Widget? prefix,
  Widget? suffix,
  String? error,
  bool dense = false,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    hintStyle: GoogleFonts.poppins(fontSize: 13, color: _IT.textLight),
    labelStyle: GoogleFonts.poppins(
      fontSize: 12,
      color: _IT.textMid,
      fontWeight: FontWeight.w500,
    ),
    floatingLabelStyle: GoogleFonts.poppins(
      fontSize: 12,
      color: _IT.brand,
      fontWeight: FontWeight.w600,
    ),
    errorText: error,
    errorStyle: GoogleFonts.poppins(fontSize: 11, color: _IT.error),
    prefixIcon: prefix,
    suffixIcon: suffix,
    filled: true,
    fillColor: _IT.inputBg,
    isDense: dense,
    contentPadding: dense
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _IT.border, width: 1.2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _IT.brand, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _IT.error, width: 1.2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _IT.error, width: 1.5),
    ),
  );
}

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
  List<String> _stepHistory = [];
  bool _isExecuting = false;
  final _formKey = GlobalKey<FormState>();
  final Map<String, String> _errors = {};
  RunnerLayoutStyle _layoutStyle = RunnerLayoutStyle.split;
  final Map<String, List<Map<String, dynamic>>> _gridRows = {};
  final Map<String, Set<int>> _gridSelections = {};
  final Map<String, List<Map<String, dynamic>>> _repeaterRows = {};
  final Map<String, String> _gridSearch = {};
  final Map<String, String> _gridSortField = {};
  final Map<String, bool> _gridSortAsc = {};
  final Set<String> _gridApiLoaded = {};
  final Set<String> _gridApiLoading = {};
  final Map<String, String> _gridApiErrors = {};

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
      _stepHistory = [];
    });
    ref.read(formValuesProvider.notifier).mergeStepDefaults(step);
  }

  Future<void> _offerResume(JourneyConfig cfg, JourneyDraft draft) async {
    if (!mounted) return;
    final resume = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _IT.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Resume Journey?',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: _IT.textDark,
          ),
        ),
        content: Text(
          'A saved draft was found for "${cfg.journeyName}" (step: ${draft.currentStepId}).',
          style: GoogleFonts.poppins(fontSize: 13, color: _IT.textMid),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Start Fresh',
              style: GoogleFonts.poppins(color: _IT.textMid),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _IT.brand,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Resume', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
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
      _stepHistory = [];
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
        backgroundColor: isError ? _IT.error : _IT.success,
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _IT.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _IT.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: _IT.success,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Journey Completed!',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: _IT.textDark,
                fontSize: 17,
              ),
            ),
          ],
        ),
        content: Text(
          'All steps have been completed and validated successfully.',
          style: GoogleFonts.poppins(fontSize: 13, color: _IT.textMid),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _IT.brand,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
            },
            child: Text(
              'Back to Dashboard',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final cfg = ref.watch(journeyConfigProvider);
    if (cfg.steps.isEmpty) {
      return Scaffold(
        backgroundColor: _IT.bg,
        body: Center(
          child: Text(
            'No steps defined.',
            style: GoogleFonts.poppins(color: _IT.textMid),
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
    final isMobile = screenW < _IT.mobileBreak;

    return Scaffold(
      backgroundColor: _IT.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, cfg),

            // Top Stepper Timeline (Only shown in Split View on desktop)
            if (_layoutStyle == RunnerLayoutStyle.split && !isMobile)
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
              child: _buildLayoutShell(cfg, activeStep, activeIdx, formValues, showSubmit, isMobile),
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
    bool isMobile,
  ) {
    switch (_layoutStyle) {
      case RunnerLayoutStyle.split:
        return SplitRunnerView(
          cfg: cfg,
          activeStep: activeStep,
          activeIdx: activeIdx,
          formContentBuilder: (ctx, {bool isMobile = false}) => _buildFormContent(
            cfg,
            activeStep,
            activeIdx,
            formValues,
            showSubmit,
            isMobile: isMobile,
          ),
          bottomBarBuilder: () => _buildBottomBar(cfg, activeStep),
        );
      case RunnerLayoutStyle.focus:
        return FocusRunnerView(
          cfg: cfg,
          activeStep: activeStep,
          activeIdx: activeIdx,
          formContentBuilder: (ctx, {bool isMobile = false}) => _buildFormContent(
            cfg,
            activeStep,
            activeIdx,
            formValues,
            showSubmit,
            isMobile: isMobile,
          ),
          bottomBarBuilder: () => _buildBottomBar(cfg, activeStep),
        );
      case RunnerLayoutStyle.timeline:
        return TimelineRunnerView(
          cfg: cfg,
          activeStep: activeStep,
          activeIdx: activeIdx,
          formValues: formValues,
          formContentBuilder: (ctx, {bool isMobile = false}) => _buildFormContent(
            cfg,
            activeStep,
            activeIdx,
            formValues,
            showSubmit,
            isMobile: isMobile,
          ),
          bottomBarBuilder: () => _buildBottomBar(cfg, activeStep),
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
          formContentBuilder: (ctx, {bool isMobile = false}) => _buildFormContent(
            cfg,
            activeStep,
            activeIdx,
            formValues,
            showSubmit,
            isMobile: isMobile,
          ),
          bottomBarBuilder: () => _buildBottomBar(cfg, activeStep),
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
          formContentBuilder: (ctx, {bool isMobile = false}) => _buildFormContent(
            cfg,
            activeStep,
            activeIdx,
            formValues,
            showSubmit,
            isMobile: isMobile,
          ),
          bottomBarBuilder: () => _buildBottomBar(cfg, activeStep),
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
          formContentBuilder: (ctx, {bool isMobile = false}) => _buildFormContent(
            cfg,
            activeStep,
            activeIdx,
            formValues,
            showSubmit,
            isMobile: isMobile,
          ),
          bottomBarBuilder: () => _buildBottomBar(cfg, activeStep),
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
          formContentBuilder: (ctx, {bool isMobile = false}) => _buildFormContent(
            cfg,
            activeStep,
            activeIdx,
            formValues,
            showSubmit,
            isMobile: isMobile,
          ),
          bottomBarBuilder: () => _buildBottomBar(cfg, activeStep),
          onStepTap: (idx) {
              _runAction(JourneyAction.previous, cfg.steps[idx], cfg);
          },
        );
      case RunnerLayoutStyle.form:
        return _buildMobileLayout(cfg, activeStep, activeIdx, formValues, showSubmit);
         }
}

  // ── HEADER ────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, JourneyConfig cfg) {
    return Container(
      height: 60,
      color: _IT.white,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _iconBtn(Icons.arrow_back_rounded, () => context.pop()),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              cfg.journeyName,
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: _IT.textDark,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _buildStyleSwitcher(),
          const SizedBox(width: 12),
          _iconBtn(
            Icons.close_rounded,
            () => context.pop(),
            color: _IT.textMid,
          ),
        ],
      ),
    );
  }

  Widget _buildStyleSwitcher() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: _IT.bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _styleIconBtn(RunnerLayoutStyle.split, Icons.splitscreen_rounded, 'Split View'),
          _styleIconBtn(RunnerLayoutStyle.focus, Icons.center_focus_strong_rounded, 'Focus View'),
          _styleIconBtn(RunnerLayoutStyle.timeline, Icons.route_rounded, 'Timeline View'),
          _styleIconBtn(RunnerLayoutStyle.tabbed, Icons.view_sidebar_rounded, 'Tabbed View'),
          _styleIconBtn(RunnerLayoutStyle.curasole, Icons.view_carousel_rounded, 'Carousel  View'),
          _styleIconBtn(RunnerLayoutStyle.masterdetail, Icons.view_carousel_rounded, 'Master-Detail View'),
          _styleIconBtn(RunnerLayoutStyle.accordion, Icons.view_agenda_rounded, 'Accordion View'),
          _styleIconBtn(RunnerLayoutStyle.form, Icons.mobile_friendly_rounded, 'Mobile Form View'),
        ],
      ),
    );
  }

  Widget _styleIconBtn(RunnerLayoutStyle style, IconData icon, String tooltip) {
    final active = _layoutStyle == style;
    return Tooltip(
      message: tooltip,
      textStyle: GoogleFonts.poppins(fontSize: 11, color: Colors.white),
      decoration: BoxDecoration(
        color: _IT.textDark,
        borderRadius: BorderRadius.circular(6),
      ),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _layoutStyle = style;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: active ? _IT.brand : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: active ? Colors.white : _IT.textMid,
          ),
        ),
      ),
    );
  }

  Widget _iconBtn(
    IconData icon,
    VoidCallback onTap, {
    Color color = _IT.textDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _IT.bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  // ── MOBILE LAYOUT: just the form, full width, scrollable ─────────────────
  Widget _buildMobileLayout(
    JourneyConfig cfg,
    JourneyStep activeStep,
    int activeIdx,
    Map<String, dynamic> formValues,
    bool showSubmit,
  ) {
    return Column(
      children: [
        // Compact mobile step indicator (replaces timeline)
        _buildMobileStepBadge(cfg, activeIdx),
        // Scrollable form
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _buildFormContent(
              cfg,
              activeStep,
              activeIdx,
              formValues,
              showSubmit,
              isMobile: true,
            ),
          ),
        ),
      ],
    );
  }

  // Slim top badge shown on mobile instead of the full timeline
  Widget _buildMobileStepBadge(JourneyConfig cfg, int activeIdx) {
    final step = cfg.steps[activeIdx];
    return Container(
      color: _IT.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: _IT.brand, shape: BoxShape.circle),
            child: Center(
              child: Text(
                '${activeIdx + 1}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _IT.textDark,
                  ),
                ),
                Text(
                  'Step ${activeIdx + 1} of ${cfg.steps.length}',
                  style: GoogleFonts.poppins(fontSize: 11, color: _IT.textMid),
                ),
              ],
            ),
          ),
          // mini progress pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: _IT.brandSurface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${activeIdx + 1}/${cfg.steps.length}',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _IT.brand,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── DESKTOP LAYOUT: left panel + right scrollable form ───────────────────
  Widget _buildDesktopLayout(
    JourneyConfig cfg,
    JourneyStep activeStep,
    int activeIdx,
    Map<String, dynamic> formValues,
    bool showSubmit,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1060),
          child: Container(
            decoration: BoxDecoration(
              color: _IT.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _IT.brand.withValues(alpha: 0.07),
                  blurRadius: 40,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            // ── KEY FIX: card is fixed height, not wrapping content ──────
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // LEFT PANEL — fixed width, does NOT scroll
                    SizedBox(
                      width: 270,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          bottomLeft: Radius.circular(24),
                        ),
                        child: _buildLeftPanel(
                          activeStep,
                          activeIdx,
                          cfg.steps.length,
                        ),
                      ),
                    ),
                    // vertical divider
                    Container(width: 1, color: _IT.border),
                    // RIGHT PANEL — scrollable independently
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(32),
                          child: _buildFormContent(
                            cfg,
                            activeStep,
                            activeIdx,
                            formValues,
                            showSubmit,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ── LEFT PANEL (desktop only) ─────────────────────────────────────────────
  Widget _buildLeftPanel(JourneyStep step, int activeIdx, int total) {
    return Container(
      color: _IT.leftPanelBg,
      padding: const EdgeInsets.all(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _IT.brand,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _IT.brand.withValues(alpha: 0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              _stepIconForTitle(step.title),
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            step.title,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _IT.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            step.description,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: _IT.textMid,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          // illustration
          Expanded(child: Center(child: _buildIllustration(step.title))),
          const SizedBox(height: 20),
          // step mini-list (only show nearby steps)
          _buildMiniStepList(activeIdx, total),
          const SizedBox(height: 16),
          // security badge
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _IT.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _IT.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _IT.brandSurface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    color: _IT.brand,
                    size: 15,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your info is safe with us',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _IT.textDark,
                        ),
                      ),
                      Text(
                        'Bank-level encryption used.',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: _IT.textMid,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Small step dots shown at the bottom of the left panel
  Widget _buildMiniStepList(int activeIdx, int total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total > 7 ? 7 : total, (i) {
        final idx = total > 7 ? (activeIdx - 3 + i).clamp(0, total - 1) : i;
        final isActive = idx == activeIdx;
        final isDone = idx < activeIdx;
        return Container(
          width: isActive ? 22 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: isActive
                ? _IT.brand
                : isDone
                ? _IT.brand.withValues(alpha: 0.3)
                : _IT.border,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildIllustration(String title) {
    final icon = _stepIconForTitle(title);
    return SizedBox(
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: _IT.brand.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: _IT.brand.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: _IT.brandSurface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _IT.brand.withValues(alpha: 0.13),
                  blurRadius: 18,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(icon, color: _IT.brand, size: 32),
          ),
        ],
      ),
    );
  }

  IconData _stepIconForTitle(String title) {
    final t = title.toLowerCase();
    if (t.contains('personal')) return Icons.person_outline_rounded;
    if (t.contains('vehicle')) return Icons.directions_car_outlined;
    if (t.contains('nominee')) return Icons.supervisor_account_outlined;
    if (t.contains('document')) return Icons.upload_file_outlined;
    if (t.contains('review') || t.contains('confirm')) {
      return Icons.fact_check_outlined;
    }
    if (t.contains('payment')) return Icons.credit_card_outlined;
    if (t.contains('success')) return Icons.verified_outlined;
    return Icons.article_outlined;
  }

  // ── FORM CONTENT (shared by both layouts) ─────────────────────────────────
  Widget _buildFormContent(
    JourneyConfig cfg,
    JourneyStep activeStep,
    int activeIdx,
    Map<String, dynamic> formValues,
    bool showSubmit, {
    bool isMobile = false,
  }) {
    return Form(
      key: _formKey,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.03, 0),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        ),
        child: Column(
          key: ValueKey(activeStep.id),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              activeStep.title,
              style: GoogleFonts.poppins(
                fontSize: isMobile ? 17 : 20,
                fontWeight: FontWeight.bold,
                color: _IT.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              activeStep.description,
              style: GoogleFonts.poppins(fontSize: 12, color: _IT.textMid),
            ),
            const SizedBox(height: 18),
            Divider(color: _IT.dividerColor, height: 1),
            const SizedBox(height: 18),
            ..._buildFields(activeStep.fields, formValues),
            const SizedBox(height: 24),
            _buildActions(cfg, activeStep, showSubmit, isMobile: isMobile),
          ],
        ),
      ),
    );
  }

  // ── ACTION BUTTONS ────────────────────────────────────────────────────────
  Widget _buildActions(
    JourneyConfig cfg,
    JourneyStep step,
    bool showSubmit, {
    bool isMobile = false,
  }) {
    final canGoBack = _stepHistory.isNotEmpty;
    return isMobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: _isExecuting
                    ? null
                    : () => _runAction(
                        showSubmit ? JourneyAction.submit : JourneyAction.next,
                        step,
                        cfg,
                      ),
                icon: _isExecuting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        showSubmit
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded,
                        size: 18,
                      ),
                label: Text(
                  showSubmit ? 'Submit' : 'Save & Continue',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _IT.brand,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (canGoBack) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isExecuting
                            ? null
                            : () =>
                                  _runAction(JourneyAction.previous, step, cfg),
                        icon: const Icon(Icons.arrow_back_rounded, size: 15),
                        label: Text(
                          'Back',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _IT.brand,
                          side: const BorderSide(color: _IT.border),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isExecuting
                          ? null
                          : () =>
                                _runAction(JourneyAction.saveDraft, step, cfg),
                      icon: const Icon(Icons.bookmark_border_rounded, size: 15),
                      label: Text(
                        'Save Draft',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _IT.textMid,
                        side: const BorderSide(color: _IT.border),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (canGoBack) ...[
                _outlinedBtn(
                  Icons.arrow_back_rounded,
                  'Back',
                  () => _runAction(JourneyAction.previous, step, cfg),
                  color: _IT.brand,
                ),
                const SizedBox(width: 10),
              ],
              _outlinedBtn(
                Icons.bookmark_border_rounded,
                'Save Draft',
                () => _runAction(JourneyAction.saveDraft, step, cfg),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _isExecuting
                    ? null
                    : () => _runAction(
                        showSubmit ? JourneyAction.submit : JourneyAction.next,
                        step,
                        cfg,
                      ),
                icon: _isExecuting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        showSubmit
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded,
                        size: 18,
                      ),
                label: Text(
                  showSubmit ? 'Submit' : 'Save & Continue',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _IT.brand,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _IT.brand.withValues(alpha: 0.45),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          );
  }

  Widget _outlinedBtn(
    IconData icon,
    String label,
    VoidCallback? onTap, {
    Color color = const Color(0xFF6B7280),
  }) {
    return OutlinedButton.icon(
      onPressed: _isExecuting ? null : onTap,
      icon: Icon(icon, size: 15),
      label: Text(
        label,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: const BorderSide(color: _IT.border),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── BOTTOM BAR ────────────────────────────────────────────────────────────
  Widget _buildBottomBar(JourneyConfig cfg, JourneyStep step) {
    return Container(
      decoration: BoxDecoration(
        color: _IT.white,
        border: Border(top: BorderSide(color: _IT.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            size: 13,
            color: _IT.textLight,
          ),
          const SizedBox(width: 6),
          Text(
            'You can save your progress and continue later',
            style: GoogleFonts.poppins(fontSize: 11, color: _IT.textMid),
          ),
        ],
      ),
    );
  }

  // ─── FIELD BUILDERS ───────────────────────────────────────────────────────
  List<Widget> _buildFields(
    List<JourneyField> fields,
    Map<String, dynamic> values,
  ) {
    return fields.map((f) {
      if (!EngineHelper.isFieldVisible(f, values)) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _buildField(f, values),
      );
    }).toList();
  }

  Widget _buildField(JourneyField field, Map<String, dynamic> values) {
    final hasErr = _errors.containsKey(field.id);
    final errMsg = _errors[field.id];

    switch (field.type.toLowerCase()) {
      case 'divider':
        return Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                field.label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _IT.brand,
                ),
              ),
              const SizedBox(height: 6),
              const Divider(color: _IT.dividerColor, height: 1),
            ],
          ),
        );

      case 'dropdown':
        final opts = field.getResolvedOptions();
        final disp = opts.isEmpty ? ["Select"] : opts;
        final cur = values[field.id]?.toString();
        return DropdownButtonFormField<String>(
          value: disp.contains(cur) ? cur : null,
          decoration: _fd(
            label: field.label,
            hint: field.placeholder ?? field.hintText,
            error: hasErr ? errMsg : null,
          ),
          style: GoogleFonts.poppins(fontSize: 13, color: _IT.textDark),
          dropdownColor: _IT.white,
          borderRadius: BorderRadius.circular(14),
          items: disp
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: (v) {
            if (v != null) {
              ref.read(formValuesProvider.notifier).updateValue(field.id, v);
            }
          },
        );

      case 'api_dropdown':
        return ApiDropdownWidget(
          field: field,
          initialValue: values[field.id]?.toString(),
          onChanged: (v) =>
              ref.read(formValuesProvider.notifier).updateValue(field.id, v),
          errorText: hasErr ? errMsg : null,
        );

      case 'radio':
        final opts = field.getResolvedOptions();
        final cur = values[field.id]?.toString();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              field.label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _IT.textMid,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: opts.map((opt) {
                final sel = cur == opt;
                return GestureDetector(
                  onTap: () => ref
                      .read(formValuesProvider.notifier)
                      .updateValue(field.id, opt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: sel ? _IT.brand : _IT.white,
                      border: Border.all(color: sel ? _IT.brand : _IT.border),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          size: 14,
                          color: sel ? Colors.white : _IT.textMid,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          opt,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: sel ? Colors.white : _IT.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            if (hasErr) ...[
              const SizedBox(height: 6),
              Text(
                errMsg!,
                style: GoogleFonts.poppins(fontSize: 11, color: _IT.error),
              ),
            ],
          ],
        );

      case 'checkbox':
        final cur = values[field.id]?.toString() == 'true';
        return Container(
          decoration: BoxDecoration(
            color: _IT.inputBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _IT.border),
          ),
          child: CheckboxListTile(
            title: Text(
              field.label,
              style: GoogleFonts.poppins(fontSize: 13, color: _IT.textDark),
            ),
            value: cur,
            activeColor: _IT.brand,
            checkColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onChanged: (v) => ref
                .read(formValuesProvider.notifier)
                .updateValue(field.id, (v ?? false).toString()),
            subtitle: hasErr
                ? Text(
                    errMsg!,
                    style: GoogleFonts.poppins(fontSize: 11, color: _IT.error),
                  )
                : null,
          ),
        );

      case 'switch':
        final cur = values[field.id]?.toString() == 'true';
        return Container(
          decoration: BoxDecoration(
            color: _IT.inputBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _IT.border),
          ),
          child: SwitchListTile(
            title: Text(
              field.label,
              style: GoogleFonts.poppins(fontSize: 13, color: _IT.textDark),
            ),
            value: cur,
            activeColor: _IT.brand,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            onChanged: (v) => ref
                .read(formValuesProvider.notifier)
                .updateValue(field.id, v.toString()),
            subtitle: hasErr
                ? Text(
                    errMsg!,
                    style: GoogleFonts.poppins(fontSize: 11, color: _IT.error),
                  )
                : null,
          ),
        );

      case 'date':
      case 'time':
      case 'datetime':
        final cur = values[field.id]?.toString() ?? '';
        return TextField(
          controller: TextEditingController(text: cur),
          readOnly: true,
          style: GoogleFonts.poppins(fontSize: 13, color: _IT.textDark),
          decoration: _fd(
            label: field.label,
            hint: field.type == 'time' ? 'HH : MM' : 'DD / MM / YYYY',
            prefix: Icon(
              Icons.calendar_today_outlined,
              color: _IT.brand,
              size: 17,
            ),
            error: hasErr ? errMsg : null,
          ),
          onTap: () async {
            if (field.type == 'time') {
              final p = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
                builder: (c, ch) => Theme(data: _pickerTheme(), child: ch!),
              );
              if (p != null && context.mounted) {
                ref
                    .read(formValuesProvider.notifier)
                    .updateValue(field.id, p.format(context));
              }
              return;
            }
            final p = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
              builder: (c, ch) => Theme(data: _pickerTheme(), child: ch!),
            );
            if (p != null) {
              ref
                  .read(formValuesProvider.notifier)
                  .updateValue(
                    field.id,
                    "${p.day.toString().padLeft(2, '0')}/${p.month.toString().padLeft(2, '0')}/${p.year}",
                  );
            }
          },
        );

      case 'number':
        return TextField(
          keyboardType: TextInputType.number,
          style: GoogleFonts.poppins(fontSize: 13, color: _IT.textDark),
          onChanged: (v) =>
              ref.read(formValuesProvider.notifier).updateValue(field.id, v),
          decoration: _fd(
            label: field.label,
            hint: field.placeholder,
            error: hasErr ? errMsg : null,
          ),
        );

      case 'email':
        return TextField(
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.poppins(fontSize: 13, color: _IT.textDark),
          onChanged: (v) =>
              ref.read(formValuesProvider.notifier).updateValue(field.id, v),
          decoration: _fd(
            label: field.label,
            hint: field.placeholder ?? 'Enter email address',
            prefix: const Icon(
              Icons.mail_outline_rounded,
              color: _IT.brand,
              size: 17,
            ),
            error: hasErr ? errMsg : null,
          ),
        );

      case 'phone':
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _IT.inputBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _IT.border, width: 1.2),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("🇮🇳", style: TextStyle(fontSize: 17)),
                  const SizedBox(width: 4),
                  Text(
                    "+91",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: _IT.textDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 15,
                    color: _IT.textMid,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                keyboardType: TextInputType.phone,
                style: GoogleFonts.poppins(fontSize: 13, color: _IT.textDark),
                onChanged: (v) => ref
                    .read(formValuesProvider.notifier)
                    .updateValue(field.id, v),
                decoration: _fd(
                  label: field.label,
                  hint: field.placeholder ?? 'Enter mobile number',
                  error: hasErr ? errMsg : null,
                ),
              ),
            ),
          ],
        );

      case 'textarea':
        return TextField(
          maxLines: 4,
          style: GoogleFonts.poppins(fontSize: 13, color: _IT.textDark),
          onChanged: (v) =>
              ref.read(formValuesProvider.notifier).updateValue(field.id, v),
          decoration: _fd(
            label: field.label,
            hint: field.placeholder,
            error: hasErr ? errMsg : null,
          ).copyWith(alignLabelWithHint: true),
        );

      case 'otp':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              field.label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _IT.textMid,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                6,
                (idx) => SizedBox(
                  width: 44,
                  child: TextField(
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _IT.textDark,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: _IT.inputBg,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _IT.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: _IT.brand,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (v) {
                      if (v.isNotEmpty && idx < 5) {
                        FocusScope.of(context).nextFocus();
                      }
                      ref
                          .read(formValuesProvider.notifier)
                          .updateValue(field.id, "123456");
                    },
                  ),
                ),
              ),
            ),
            if (hasErr) ...[
              const SizedBox(height: 6),
              Text(
                errMsg!,
                style: GoogleFonts.poppins(fontSize: 11, color: _IT.error),
              ),
            ],
          ],
        );

      case 'image':
        return _buildUpload(field, values, hasErr, errMsg, isImage: true);
      case 'file':
        return _buildUpload(field, values, hasErr, errMsg);

      case 'table_grid':
        return _buildGrid(field);
      case 'repeater':
        return _buildRepeater(field);
      case 'timeline':
        return _buildTimeline(field);
      case 'section':
        return _buildNested(field, values, Icons.view_agenda_outlined);
      case 'card':
        return _buildNested(field, values, Icons.crop_square_rounded);
      case 'tabs':
        return _buildTabs(field, values);
      case 'accordion':
        return _buildNested(field, values, Icons.unfold_more_rounded);
      case 'row':
        return _buildNestedRow(field, values);
      case 'formula':
        return FormulaFieldWidget(
          label: field.label,
          formula: field.formula!,
          formValues: values,
        );

      default:
        return TextField(
          style: GoogleFonts.poppins(fontSize: 13, color: _IT.textDark),
          onChanged: (v) =>
              ref.read(formValuesProvider.notifier).updateValue(field.id, v),
          decoration: _fd(
            label: field.label,
            hint: field.placeholder,
            error: hasErr ? errMsg : null,
          ),
        );
    }
  }

  ThemeData _pickerTheme() => ThemeData(
    colorScheme: const ColorScheme.light(
      primary: _IT.brand,
      onPrimary: Colors.white,
      surface: _IT.white,
      onSurface: _IT.textDark,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: _IT.brand),
    ),
  );

  Widget _buildUpload(
    JourneyField field,
    Map<String, dynamic> values,
    bool hasErr,
    String? errMsg, {
    bool isImage = false,
  }) {
    final cur = values[field.id]?.toString() ?? '';
    return GestureDetector(
      onTap: () => ref
          .read(formValuesProvider.notifier)
          .updateValue(
            field.id,
            isImage ? "image_uploaded.png" : "document_uploaded.pdf",
          ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: _IT.inputBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: hasErr ? _IT.error : _IT.border),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _IT.brandSurface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isImage ? Icons.image_outlined : Icons.cloud_upload_outlined,
                color: _IT.brand,
                size: 22,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              cur.isNotEmpty
                  ? cur
                  : (isImage
                        ? 'Click to upload image'
                        : 'Drag & Drop or click to upload'),
              style: GoogleFonts.poppins(fontSize: 12, color: _IT.textMid),
            ),
            const SizedBox(height: 3),
            Text(
              'PNG, JPG, PDF up to 10MB',
              style: GoogleFonts.poppins(fontSize: 11, color: _IT.textLight),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => ref
                  .read(formValuesProvider.notifier)
                  .updateValue(
                    field.id,
                    isImage ? "image_uploaded.png" : "document_uploaded.pdf",
                  ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _IT.brand,
                side: const BorderSide(color: _IT.brand),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 9,
                ),
              ),
              child: Text(
                isImage ? 'Select Image' : 'Select File',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (hasErr) ...[
              const SizedBox(height: 8),
              Text(
                errMsg!,
                style: GoogleFonts.poppins(fontSize: 11, color: _IT.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── GRID ─────────────────────────────────────────────────────────────────
  Map<String, dynamic> _compConfig(JourneyField f) {
    final c = Map<String, dynamic>.from(f.componentConfig ?? {});
    if (f.type == 'table_grid') {
      return {
        'columns': [
          {
            'label': '#',
            'fieldId': 'rowIndex',
            'type': 'number',
            'required': false,
          },
          {
            'label': 'Name',
            'fieldId': 'name',
            'type': 'text',
            'required': true,
          },
          {
            'label': 'Age',
            'fieldId': 'age',
            'type': 'number',
            'required': false,
          },
        ],
        'rowActions': ['edit', 'delete'],
        'allowAddRow': true,
        'allowDeleteRow': true,
        'inlineEdit': true,
        'bulkSelection': true,
        'exportCsv': true,
        'search': true,
        'sorting': true,
        'dataSource': 'manual',
        'gridApiUrl': '',
        'gridApiMethod': 'GET',
        'gridApiHeaders': {},
        'gridApiBody': '',
        'gridApiListKey': 'data',
        'apiPagination': false,
        'dynamicRowValidation': true,
        'pagination': true,
        'rowsPerPage': 10,
        'minRows': 0,
        'maxRows': 10,
        ...c,
      };
    }
    return c;
  }

  List<Map<String, dynamic>> _cfgList(
    JourneyField f,
    String key,
    List<Map<String, dynamic>> fallback,
  ) {
    final v = _compConfig(f)[key];
    if (v is List) {
      final p = v
          .map(
            (i) =>
                i is Map ? Map<String, dynamic>.from(i) : <String, dynamic>{},
          )
          .where((i) => i.isNotEmpty)
          .toList();
      if (p.isNotEmpty) return p;
    }
    return fallback;
  }

  Widget _buildGrid(JourneyField field) {
    final cfg = _compConfig(field);
    final cols = _cfgList(
      field,
      'columns',
      field.nestedFields != null && field.nestedFields!.isNotEmpty
          ? field.nestedFields!
                .map(
                  (n) => {
                    'label': n.label,
                    'fieldId': n.id,
                    'type': n.type,
                    'required': n.required,
                  },
                )
                .toList()
          : [
              {'label': '#'},
              {'label': 'Name', 'fieldId': 'name', 'required': true},
              {'label': 'Age', 'fieldId': 'age'},
            ],
    );
    final allowAdd = cfg['allowAddRow'] != false;
    final allowDel = cfg['allowDeleteRow'] != false;
    final inline = cfg['inlineEdit'] != false;
    final bulk = cfg['bulkSelection'] != false;
    final expCsv = cfg['exportCsv'] != false;
    final srch = cfg['search'] != false;
    final srtg = cfg['sorting'] != false;
    final valid = cfg['dynamicRowValidation'] != false;
    final src = cfg['dataSource']?.toString() ?? 'manual';
    final paged = cfg['pagination'] != false;
    final actions = cfg['rowActions'] is List
        ? List<String>.from(
            (cfg['rowActions'] as List).map((i) => i.toString()),
          )
        : <String>['edit', 'delete'];
    final rpp = int.tryParse(cfg['rowsPerPage']?.toString() ?? '') ?? 10;
    final maxR = int.tryParse(cfg['maxRows']?.toString() ?? '') ?? 10;
    final rows = _ensureGridRows(field, cols, cfg);
    if (src == 'api' &&
        !_gridApiLoaded.contains(field.id) &&
        !_gridApiLoading.contains(field.id)) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _loadGridApi(field, cols, cfg),
      );
    }
    final srchTxt = _gridSearch[field.id] ?? '';
    final srtFld = _gridSortField[field.id];
    final srtAsc = _gridSortAsc[field.id] ?? true;
    final sel = _gridSelections.putIfAbsent(field.id, () => <int>{});
    var vis = rows.asMap().entries.where((e) {
      if (srchTxt.trim().isEmpty) return true;
      final q = srchTxt.toLowerCase();
      return e.value.values.any((v) => v.toString().toLowerCase().contains(q));
    }).toList();
    if (srtFld != null) {
      vis.sort((a, b) {
        final l = a.value[srtFld]?.toString() ?? '';
        final r = b.value[srtFld]?.toString() ?? '';
        return srtAsc ? l.compareTo(r) : r.compareTo(l);
      });
    }
    final pgd = paged ? vis.take(rpp).toList() : vis;
    final srtIdx = srtFld == null
        ? -1
        : cols.indexWhere((c) => _colId(c) == srtFld);

    return Container(
      decoration: BoxDecoration(
        color: _IT.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _IT.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: _IT.inputBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
              border: Border(bottom: BorderSide(color: _IT.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    field.label,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _IT.textDark,
                    ),
                  ),
                ),
                if (src == 'api')
                  IconButton(
                    tooltip: "Reload",
                    onPressed: _gridApiLoading.contains(field.id)
                        ? null
                        : () => _loadGridApi(field, cols, cfg, force: true),
                    icon: _gridApiLoading.contains(field.id)
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _IT.brand,
                            ),
                          )
                        : const Icon(
                            Icons.refresh_rounded,
                            size: 17,
                            color: _IT.textMid,
                          ),
                  ),
                if (expCsv)
                  IconButton(
                    tooltip: "CSV",
                    onPressed: () => _exportCsv(field, cols, rows),
                    icon: const Icon(
                      Icons.download_rounded,
                      size: 17,
                      color: _IT.textMid,
                    ),
                  ),
                if (allowAdd)
                  ElevatedButton.icon(
                    onPressed: rows.length >= maxR
                        ? null
                        : () => _addRow(field, cols),
                    icon: const Icon(Icons.add_rounded, size: 13),
                    label: Text(
                      "Add Row",
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _IT.brand,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_gridApiErrors[field.id] != null)
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                _gridApiErrors[field.id]!,
                style: GoogleFonts.poppins(fontSize: 11, color: _IT.error),
              ),
            ),
          if (srch)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: TextField(
                decoration: _fd(
                  label: '',
                  hint: 'Search rows...',
                  prefix: const Icon(
                    Icons.search_rounded,
                    size: 15,
                    color: _IT.textMid,
                  ),
                  dense: true,
                ),
                style: GoogleFonts.poppins(fontSize: 12),
                onChanged: (v) => setState(() => _gridSearch[field.id] = v),
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(14),
            child: DataTable(
              showCheckboxColumn: bulk,
              headingRowColor: WidgetStatePropertyAll(_IT.inputBg),
              headingTextStyle: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _IT.textMid,
              ),
              dataTextStyle: GoogleFonts.poppins(
                fontSize: 12,
                color: _IT.textDark,
              ),
              dataRowMinHeight: 46,
              dataRowMaxHeight: 60,
              sortColumnIndex: srtIdx < 0 ? null : srtIdx,
              sortAscending: srtAsc,
              columns: [
                ...cols.map(
                  (c) => DataColumn(
                    label: Text(c['label']?.toString() ?? 'Col'),
                    onSort: srtg
                        ? (_, asc) => setState(() {
                            _gridSortField[field.id] = _colId(c);
                            _gridSortAsc[field.id] = asc;
                          })
                        : null,
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Action",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
              rows: pgd
                  .map(
                    (e) => DataRow(
                      selected: sel.contains(e.key),
                      onSelectChanged: bulk
                          ? (c) => setState(() {
                              c == true ? sel.add(e.key) : sel.remove(e.key);
                            })
                          : null,
                      cells: [
                        ...cols.map(
                          (c) => DataCell(
                            _gridCell(field, c, e.value, e.key, inline, valid),
                          ),
                        ),
                        DataCell(
                          _gridActions(
                            field,
                            cols,
                            e.key,
                            e.value,
                            actions,
                            allowDel,
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
          if (paged)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Text(
                "${pgd.length} of ${vis.length} row(s)",
                style: GoogleFonts.poppins(fontSize: 10, color: _IT.textLight),
              ),
            ),
        ],
      ),
    );
  }

  Widget _gridActions(
    JourneyField f,
    List<Map<String, dynamic>> cols,
    int ri,
    Map<String, dynamic> row,
    List<String> acts,
    bool allowDel,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: acts.map((a) {
        switch (a.toLowerCase()) {
          case 'delete':
            return allowDel
                ? IconButton(
                    onPressed: () => _delRow(f, ri),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: Colors.redAccent,
                    ),
                  )
                : const SizedBox.shrink();
          case 'duplicate':
            return IconButton(
              onPressed: () => _dupRow(f, cols, row),
              icon: const Icon(
                Icons.copy_rounded,
                size: 14,
                color: _IT.textMid,
              ),
            );
          case 'edit':
            return const Icon(Icons.edit_outlined, size: 14, color: _IT.brand);
          default:
            return const SizedBox.shrink();
        }
      }).toList(),
    );
  }

  List<Map<String, dynamic>> _ensureGridRows(
    JourneyField f,
    List<Map<String, dynamic>> cols,
    Map<String, dynamic> cfg,
  ) {
    return _gridRows.putIfAbsent(f.id, () {
      final min = int.tryParse(cfg['minRows']?.toString() ?? '') ?? 0;
      if ((cfg['dataSource']?.toString() ?? 'manual') == 'api') {
        return <Map<String, dynamic>>[];
      }
      return List.generate(min > 0 ? min : 1, (_) => _emptyRow(cols));
    });
  }

  Future<void> _loadGridApi(
    JourneyField f,
    List<Map<String, dynamic>> cols,
    Map<String, dynamic> cfg, {
    bool force = false,
  }) async {
    if (!force && _gridApiLoading.contains(f.id)) return;
    final url = cfg['gridApiUrl']?.toString().trim() ?? '';
    if (url.isEmpty) {
      setState(() {
        _gridApiLoaded.add(f.id);
        _gridApiErrors[f.id] = 'Grid API URL required.';
      });
      return;
    }
    setState(() {
      _gridApiLoading.add(f.id);
      _gridApiErrors.remove(f.id);
    });
    try {
      final uri = Uri.parse(url);
      final hdrs = _parseHeaders(cfg['gridApiHeaders']);
      final body = cfg['gridApiBody']?.toString().trim();
      final method = (cfg['gridApiMethod']?.toString() ?? 'GET').toUpperCase();
      http.Response res;
      if (method == 'POST') {
        res = await http.post(
          uri,
          headers: hdrs,
          body: body?.isEmpty == true ? null : body,
        );
      } else {
        res = await http.get(uri, headers: hdrs);
      }
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('API ${res.statusCode}');
      }
      final dec = json.decode(res.body);
      final lk = cfg['gridApiListKey']?.toString() ?? '';
      final rows = _normApiRows(dec, lk, cols);
      setState(() {
        _gridRows[f.id] = rows;
        _gridSelections[f.id]?.clear();
        _gridApiLoaded.add(f.id);
        _gridApiLoading.remove(f.id);
      });
      _syncGrid(f);
    } catch (e) {
      setState(() {
        _gridApiLoaded.add(f.id);
        _gridApiLoading.remove(f.id);
        _gridApiErrors[f.id] = e.toString();
      });
    }
  }

  Map<String, String> _parseHeaders(dynamic raw) {
    final h = <String, String>{};
    if (raw is Map) {
      raw.forEach((k, v) => h[k.toString()] = v.toString());
    } else if (raw is String && raw.trim().isNotEmpty) {
      try {
        final d = json.decode(raw);
        if (d is Map) d.forEach((k, v) => h[k.toString()] = v.toString());
      } catch (_) {}
    }
    return h;
  }

  List<Map<String, dynamic>> _normApiRows(
    dynamic dec,
    String lk,
    List<Map<String, dynamic>> cols,
  ) {
    dynamic src = dec;
    if (dec is Map && lk.isNotEmpty) {
      src = _jsonPath(dec, lk) ?? dec[lk];
    }
    if (src is! List && dec is Map) {
      for (final k in ['data', 'items', 'results', 'rows']) {
        if (dec[k] is List) {
          src = dec[k];
          break;
        }
      }
    }
    if (src is! List) return [];
    return src.map<Map<String, dynamic>>((i) {
      if (i is Map) return Map<String, dynamic>.from(i);
      final r = _emptyRow(cols);
      if (cols.isNotEmpty) r[_colId(cols.first)] = i.toString();
      return r;
    }).toList();
  }

  dynamic _jsonPath(dynamic src, String path) {
    dynamic c = src;
    for (final p in path.split('.')) {
      if (c is Map) {
        c = c[p];
      } else {
        return null;
      }
    }
    return c;
  }

  Map<String, dynamic> _emptyRow(List<Map<String, dynamic>> cols) => {
    for (final c in cols) _colId(c): '',
  };
  String _colId(Map<String, dynamic> c) =>
      (c['fieldId'] ?? c['key'] ?? c['label'] ?? 'col').toString();

  Widget _gridCell(
    JourneyField f,
    Map<String, dynamic> col,
    Map<String, dynamic> row,
    int ri,
    bool inline,
    bool valid,
  ) {
    final fid = _colId(col);
    final val = row[fid]?.toString() ?? '';
    final req = col['required'] == true;
    final err = valid && req && val.trim().isEmpty;
    if (!inline) {
      return Text(
        val.isEmpty ? '-' : val,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: err ? _IT.error : _IT.textMid,
        ),
      );
    }
    return SizedBox(
      width: 130,
      child: TextFormField(
        initialValue: val,
        decoration: InputDecoration(
          isDense: true,
          hintText: col['label']?.toString(),
          errorText: err ? "Required" : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
          filled: true,
          fillColor: _IT.inputBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _IT.border),
          ),
        ),
        keyboardType: col['type'] == 'number'
            ? TextInputType.number
            : TextInputType.text,
        style: GoogleFonts.poppins(fontSize: 11, color: _IT.textDark),
        onChanged: (v) => _updCell(f, ri, fid, v),
      ),
    );
  }

  void _addRow(JourneyField f, List<Map<String, dynamic>> cols) => setState(() {
    _gridRows.putIfAbsent(f.id, () => []).add(_emptyRow(cols));
    _syncGrid(f);
  });
  void _delRow(JourneyField f, int ri) => setState(() {
    final r = _gridRows[f.id];
    if (r != null && ri >= 0 && ri < r.length) {
      r.removeAt(ri);
      _gridSelections[f.id]?.remove(ri);
      _syncGrid(f);
    }
  });
  void _dupRow(
    JourneyField f,
    List<Map<String, dynamic>> cols,
    Map<String, dynamic> row,
  ) => setState(() {
    _gridRows.putIfAbsent(f.id, () => []).add({..._emptyRow(cols), ...row});
    _syncGrid(f);
  });
  void _updCell(JourneyField f, int ri, String fid, String v) => setState(() {
    final r = _gridRows[f.id];
    if (r != null && ri >= 0 && ri < r.length) {
      r[ri][fid] = v;
      _syncGrid(f);
    }
  });
  void _syncGrid(JourneyField f) => ref
      .read(formValuesProvider.notifier)
      .updateValue(f.id, jsonEncode(_gridRows[f.id] ?? []));

  void _exportCsv(
    JourneyField f,
    List<Map<String, dynamic>> cols,
    List<Map<String, dynamic>> rows,
  ) {
    final hdrs = cols.map((c) => c['label']?.toString() ?? _colId(c)).toList();
    final keys = cols.map(_colId).toList();
    final csv = [
      hdrs.map(_esc).join(','),
      ...rows.map(
        (r) => keys.map((k) => _esc(r[k]?.toString() ?? '')).join(','),
      ),
    ].join('\n');
    Clipboard.setData(ClipboardData(text: csv));
    _snack('CSV copied to clipboard');
  }

  String _esc(String v) {
    final e = v.replaceAll('"', '""');
    return v.contains(',') || v.contains('"') || v.contains('\n') ? '"$e"' : e;
  }

  // ─── REPEATER ─────────────────────────────────────────────────────────────
  Widget _buildRepeater(JourneyField field) {
    final cfg = _compConfig(field);
    final nf = field.nestedFields ?? <JourneyField>[];
    final allowAdd = cfg['allowAdd'] != false;
    final allowRem = cfg['allowRemove'] != false;
    final itemLabel = cfg['itemLabel']?.toString() ?? 'Item';
    final addLabel = cfg['addButtonLabel']?.toString() ?? 'Add $itemLabel';
    final maxR = int.tryParse(cfg['maxRows']?.toString() ?? '') ?? 20;
    final rows = _repeaterRows.putIfAbsent(field.id, () => [_emptyRepRow(nf)]);

    return Container(
      decoration: BoxDecoration(
        color: _IT.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _IT.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: _IT.inputBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
              border: Border(bottom: BorderSide(color: _IT.border)),
            ),
            child: Text(
              field.label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _IT.textDark,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                ...rows.asMap().entries.map(
                  (e) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _IT.inputBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _IT.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '$itemLabel ${e.key + 1}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _IT.textDark,
                                ),
                              ),
                            ),
                            if (allowRem && rows.length > 1)
                              GestureDetector(
                                onTap: () => setState(() {
                                  _repeaterRows[field.id]!.removeAt(e.key);
                                  _syncRep(field);
                                }),
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: _IT.error.withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 13,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (nf.isNotEmpty)
                          ...nf.map(
                            (n) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _repCell(field, e.key, n, e.value),
                            ),
                          )
                        else
                          Text(
                            'No fields configured.',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: _IT.textLight,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (allowAdd && rows.length < maxR)
                  OutlinedButton.icon(
                    onPressed: () => setState(() {
                      _repeaterRows[field.id]!.add(_emptyRepRow(nf));
                      _syncRep(field);
                    }),
                    icon: const Icon(Icons.add_rounded, size: 13),
                    label: Text(
                      addLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _IT.brand,
                      side: const BorderSide(color: _IT.brand),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _emptyRepRow(List<JourneyField> fields) => {
    for (final f in fields) f.id: f.defaultValue ?? '',
  };
  void _syncRep(JourneyField f) => ref
      .read(formValuesProvider.notifier)
      .updateValue(
        f.id,
        List<Map<String, dynamic>>.from(_repeaterRows[f.id] ?? []),
      );

  Widget _repCell(
    JourneyField repF,
    int ri,
    JourneyField cf,
    Map<String, dynamic> rv,
  ) {
    final cur = rv[cf.id]?.toString() ?? '';
    void upd(dynamic v) => setState(() {
      _repeaterRows[repF.id]![ri][cf.id] = v;
      _syncRep(repF);
    });
    switch (cf.type.toLowerCase()) {
      case 'dropdown':
        final opts = cf.getResolvedOptions();
        return DropdownButtonFormField<String>(
          value: opts.contains(cur) ? cur : null,
          decoration: _fd(label: cf.label, dense: true),
          dropdownColor: _IT.white,
          items: opts
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: (v) {
            if (v != null) upd(v);
          },
        );
      case 'checkbox':
      case 'switch':
        return CheckboxListTile(
          title: Text(cf.label, style: GoogleFonts.poppins(fontSize: 12)),
          value: cur == 'true',
          activeColor: _IT.brand,
          contentPadding: EdgeInsets.zero,
          onChanged: (v) => upd((v ?? false).toString()),
        );
      default:
        return TextFormField(
          initialValue: cur,
          decoration: _fd(label: cf.label, dense: true),
          keyboardType: cf.type == 'number'
              ? TextInputType.number
              : TextInputType.text,
          style: GoogleFonts.poppins(fontSize: 12, color: _IT.textDark),
          onChanged: upd,
        );
    }
  }

  // ─── TIMELINE ────────────────────────────────────────────────────────────
  Widget _buildTimeline(JourneyField field) {
    final items = _cfgList(field, 'items', [
      {
        'title': 'Started',
        'description': 'Journey started',
        'status': 'completed',
      },
      {'title': 'Current', 'description': 'Current step', 'status': 'active'},
      {'title': 'Completed', 'description': 'Final state', 'status': 'pending'},
    ]);
    Color sc(String? s) => s == 'completed'
        ? _IT.success
        : s == 'active'
        ? _IT.brand
        : _IT.textLight;
    return Container(
      decoration: BoxDecoration(
        color: _IT.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _IT.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _IT.textDark,
            ),
          ),
          const SizedBox(height: 12),
          ...items.asMap().entries.map(
            (e) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: sc(e.value['status']?.toString()),
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (e.key < items.length - 1)
                      Container(width: 2, height: 34, color: _IT.border),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.value['title']?.toString() ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _IT.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          e.value['description']?.toString() ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: _IT.textMid,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── NESTED ───────────────────────────────────────────────────────────────
  Widget _buildNested(
    JourneyField f,
    Map<String, dynamic> vals,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: _IT.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _IT.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _IT.brandSurface,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 15, color: _IT.brand),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  f.label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _IT.textDark,
                  ),
                ),
              ),
            ],
          ),
          if ((f.nestedFields ?? []).isNotEmpty) ...[
            const SizedBox(height: 12),
            ..._buildFields(f.nestedFields!, vals),
          ],
        ],
      ),
    );
  }

  Widget _buildNestedRow(JourneyField f, Map<String, dynamic> vals) {
    final ch = (f.nestedFields ?? <JourneyField>[])
        .where((c) => EngineHelper.isFieldVisible(c, vals))
        .toList();
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: ch.map((c) {
        final span =
            int.tryParse(c.componentConfig?['colSpan']?.toString() ?? '') ?? 12;
        final w = MediaQuery.of(context).size.width;
        return SizedBox(
          width: w > 760
              ? ((w - 220) * (span.clamp(1, 12) / 12))
              : double.infinity,
          child: _buildField(c, vals),
        );
      }).toList(),
    );
  }

  Widget _buildTabs(JourneyField f, Map<String, dynamic> vals) {
    final tabs = f.nestedFields ?? <JourneyField>[];
    if (tabs.isEmpty) return _buildNested(f, vals, Icons.tab_rounded);
    return DefaultTabController(
      length: tabs.length,
      child: Container(
        decoration: BoxDecoration(
          color: _IT.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _IT.border),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              f.label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _IT.textDark,
              ),
            ),
            const SizedBox(height: 10),
            TabBar(
              isScrollable: true,
              labelColor: _IT.brand,
              unselectedLabelColor: _IT.textMid,
              indicatorColor: _IT.brand,
              labelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              tabs: tabs.map((t) => Tab(text: t.label)).toList(),
            ),
            SizedBox(
              height: 300,
              child: TabBarView(
                children: tabs
                    .map(
                      (t) => SingleChildScrollView(
                        padding: const EdgeInsets.only(top: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _buildFields(t.nestedFields ?? [], vals),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// API DROPDOWN
// ─────────────────────────────────────────────────────────────────────────────
class ApiDropdownWidget extends ConsumerStatefulWidget {
  final JourneyField field;
  final String? initialValue;
  final ValueChanged<String> onChanged;
  final String? errorText;
  const ApiDropdownWidget({
    super.key,
    required this.field,
    required this.initialValue,
    required this.onChanged,
    this.errorText,
  });

  @override
  ConsumerState<ApiDropdownWidget> createState() => _ApiDropdownState();
}

class _ApiDropdownState extends ConsumerState<ApiDropdownWidget> {
  List<String> _opts = [];
  bool _loading = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void didUpdateWidget(ApiDropdownWidget old) {
    super.didUpdateWidget(old);
    if (old.field.dropdownApiUrl != widget.field.dropdownApiUrl) _fetch();
  }

  Future<void> _fetch() async {
    final url = widget.field.dropdownApiUrl;
    if (url == null || url.trim().isEmpty) {
      setState(() {
        _opts = widget.field.options ?? ["Select"];
        _loading = false;
        _err = "No API URL";
      });
      return;
    }
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final res = await http
          .get(Uri.parse(url.trim()))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final dec = json.decode(res.body);
        final List<String> out = [];
        void ext(dynamic data) {
          if (data is! List) return;
          final dk = widget.field.dropdownValue ?? 'title';
          for (var item in data) {
            if (item is String) {
              out.add(item);
            } else if (item is num || item is bool) {
              out.add(item.toString());
            } else if (item is Map) {
              if (item[dk] != null) {
                out.add(item[dk].toString());
              } else {
                final keys = [
                  'name',
                  'title',
                  'value',
                  'label',
                  'text',
                  'username',
                  'display_name',
                ];
                String? f;
                for (var k in keys) {
                  if (item[k] != null) {
                    f = item[k].toString();
                    break;
                  }
                }
                f ??= item.isNotEmpty ? item.values.first.toString() : null;
                if (f != null) out.add(f);
              }
            }
          }
        }

        if (dec is List) {
          ext(dec);
        } else if (dec is Map) {
          final rk = widget.field.dropdownApiResponseKey;
          bool found = false;
          if (rk != null && rk.isNotEmpty && dec[rk] is List) {
            ext(dec[rk]);
            found = true;
          }
          if (!found) {
            for (var k in ['data', 'results', 'items', 'users', 'options']) {
              if (dec[k] is List) {
                ext(dec[k]);
                found = true;
                break;
              }
            }
          }
          if (!found) {
            for (var v in dec.values) {
              if (v is List) {
                ext(v);
                found = true;
                break;
              }
            }
          }
          if (!found) _err = "List not found in response";
        }
        if (out.isEmpty && _err == null) _err = "No options found";
        setState(() {
          _opts = out.isNotEmpty ? out : ["Select"];
          _loading = false;
        });
      } else {
        setState(() {
          _err = "HTTP ${res.statusCode}";
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _err = "Connection failed";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: _opts.contains(widget.initialValue) ? widget.initialValue : null,
      decoration: _fd(
        label: widget.field.label,
        hint: widget.field.placeholder ?? "Select option",
        error: (_err ?? widget.errorText),
        suffix: _loading
            ? const Padding(
                padding: EdgeInsets.all(13),
                child: SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(_IT.brand),
                  ),
                ),
              )
            : _err != null
            ? IconButton(
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Colors.amber,
                  size: 18,
                ),
                onPressed: _fetch,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              )
            : null,
      ),
      style: GoogleFonts.poppins(fontSize: 13, color: _IT.textDark),
      dropdownColor: _IT.white,
      borderRadius: BorderRadius.circular(14),
      items: _opts
          .map((o) => DropdownMenuItem(value: o, child: Text(o)))
          .toList(),
      onChanged: _loading
          ? null
          : (v) {
              if (v != null) widget.onChanged(v);
            },
    );
  }
}
