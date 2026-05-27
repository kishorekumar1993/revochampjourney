import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:revojourneytryone/features/journey_runner/presentation/screens/stepper.dart';
import '../../../journey_builder/data/models.dart';
import '../../../journey_builder/presentation/providers/journey_provider.dart';
import '../../application/journey_draft_store.dart';
import '../../application/journey_execution_engine.dart';
import '../../domain/journey_execution_models.dart';
import 'advanced_formula_field_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS  (light purple insurance theme matching the reference image)
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
  static const divider = Color(0xFFF0F0FF);
}

// Shared InputDecoration theme for all fields
InputDecoration _fieldDecor({
  required String label,
  String? hint,
  Widget? prefix,
  Widget? suffix,
  String? errorText,
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
    errorText: errorText,
    errorStyle: GoogleFonts.poppins(fontSize: 11, color: _IT.error),
    prefixIcon: prefix,
    suffixIcon: suffix,
    filled: true,
    fillColor: _IT.inputBg,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
  final Map<String, List<Map<String, dynamic>>> _gridRows = {};
  final Map<String, Set<int>> _gridSelections = {};
  final Map<String, List<Map<String, dynamic>>> _repeaterRows = {};
  final Map<String, String> _gridSearch = {};
  final Map<String, String> _gridSortField = {};
  final Map<String, bool> _gridSortAscending = {};
  final Set<String> _gridApiLoaded = {};
  final Set<String> _gridApiLoading = {};
  final Map<String, String> _gridApiErrors = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapRunner());
  }

  void _bootstrapRunner() {
    final config = ref.read(journeyConfigProvider);
    if (config.steps.isEmpty) return;
    final draft = ref.read(journeyDraftStoreProvider)[config.journeyName];
    if (draft != null) {
      _offerResumeDraft(config, draft);
      return;
    }
    final step = widget.initialStepId != null
        ? config.steps.firstWhere(
            (s) => s.id == widget.initialStepId!,
            orElse: () => config.steps.first,
          )
        : config.steps.first;
    setState(() {
      _runnerStepId = step.id;
      _stepHistory = [];
    });
    ref.read(formValuesProvider.notifier).mergeStepDefaults(step);
  }

  Future<void> _offerResumeDraft(
    JourneyConfig config,
    JourneyDraft draft,
  ) async {
    if (!mounted) return;
    final resume = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
          'A saved draft was found for "${config.journeyName}" (step: ${draft.currentStepId}).',
          style: GoogleFonts.poppins(fontSize: 13, color: _IT.textMid),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Start Fresh',
              style: GoogleFonts.poppins(color: _IT.textMid),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _IT.brand,
              foregroundColor: _IT.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Resume', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (resume == true) {
      await _runAction(
        JourneyAction.resume,
        config.steps.firstWhere(
          (s) => s.id == draft.currentStepId,
          orElse: () => config.steps.first,
        ),
        config,
        draftToResume: draft,
      );
      return;
    }
    ref.read(journeyDraftStoreProvider.notifier).clearDraft(config.journeyName);
    final first = config.steps.first;
    setState(() {
      _runnerStepId = first.id;
      _stepHistory = [];
    });
    ref.read(formValuesProvider.notifier).mergeStepDefaults(first);
  }

  void _syncRoute(String stepId) {
    if (!mounted) return;
    final current = GoRouterState.of(context).uri.queryParameters['step'];
    if (current == stepId) return;
    context.go(
      Uri(path: '/runner', queryParameters: {'step': stepId}).toString(),
    );
  }

  Future<void> _runAction(
    JourneyAction action,
    JourneyStep currentStep,
    JourneyConfig config, {
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
        config: config,
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
      _snackError(result.message ?? 'Validation failed.');
      return;
    }
    if (result.status == JourneyExecutionStatus.apiFailed) {
      _snackError(result.message ?? 'API execution failed.');
      return;
    }
    if (result.status == JourneyExecutionStatus.notFound ||
        result.status == JourneyExecutionStatus.noDraft) {
      if (result.message != null)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result.message!)));
      return;
    }
    if (result.savedDraft != null) {
      ref
          .read(journeyDraftStoreProvider.notifier)
          .saveDraft(result.savedDraft!);
      _snackSuccess(result.message ?? 'Draft saved.');
      return;
    }
    ref
        .read(formValuesProvider.notifier)
        .restoreSession(
          values: result.formValues,
          step: result.targetStepId != null
              ? config.steps.firstWhere(
                  (s) => s.id == result.targetStepId,
                  orElse: () => currentStep,
                )
              : null,
        );
    if (result.journeyCompleted) {
      ref
          .read(journeyDraftStoreProvider.notifier)
          .clearDraft(config.journeyName);
      _recordCompletedRun(config, currentStep, result.formValues);
      _showCompletionDialog();
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

  void _snackError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins()),
        backgroundColor: _IT.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _snackSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins()),
        backgroundColor: _IT.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _recordCompletedRun(
    JourneyConfig config,
    JourneyStep step,
    Map<String, dynamic> values,
  ) {
    final currentRuns = ref.read(journeyRunsProvider);
    final nextRunNumber = 1050 + currentRuns.length;
    final userEmail =
        values['email']?.toString() ??
        values['mobile']?.toString() ??
        'anonymous@revo.com';
    ref.read(journeyRunsProvider.notifier).addRun({
      'id': 'RUN-$nextRunNumber',
      'journeyName': config.journeyName,
      'user': userEmail,
      'status': 'Completed',
      'currentStep': step.title,
      'progress': 1.0,
      'stepsCount': '${config.steps.length}/${config.steps.length}',
      'started': 'Just now',
      'data': Map<String, dynamic>.from(values),
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              foregroundColor: _IT.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              Navigator.pop(context);
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

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // ref.watch(themeModeProvider);
    final config = ref.watch(journeyConfigProvider);
    if (config.steps.isEmpty) {
      return Scaffold(
        backgroundColor: _IT.bg,
        body: Center(
          child: Text(
            'No steps defined',
            style: GoogleFonts.poppins(color: _IT.textMid),
          ),
        ),
      );
    }
    final activeId = _runnerStepId ?? config.steps.first.id;
    final activeIdx = config.steps.indexWhere((s) => s.id == activeId);
    final activeStep = activeIdx != -1
        ? config.steps[activeIdx]
        : config.steps.first;
    final formValues = ref.watch(formValuesProvider);
    final showSubmit = _engine.shouldShowSubmit(activeStep, formValues);

    return Scaffold(
      backgroundColor: _IT.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Header ──────────────────────────────────────────────
            _buildHeader(context, config),

            // ── Timeline Stepper ────────────────────────────────────────
            JourneyTimeline(
              steps: config.steps,
              activeIndex: activeIdx,
              onStepTap: (i) {
                if (i <= activeIdx) {
                  _runAction(JourneyAction.previous, config.steps[i], config);
                }
              },
            ),

            // ── Content ─────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: _buildCard(
                      config,
                      activeStep,
                      activeIdx,
                      formValues,
                      showSubmit,
                    ),
                  ),
                ),
              ),
            ),

            // ── Bottom Save-Progress Bar ─────────────────────────────────
            _buildBottomBar(config, activeStep),
          ],
        ),
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, JourneyConfig config) {
    return Container(
      height: 60,
      color: _IT.white,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _IT.bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: _IT.textDark,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              config.journeyName,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _IT.textDark,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _IT.bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: _IT.textMid,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── MAIN CARD (left panel + right form) ───────────────────────────────────
  Widget _buildCard(
    JourneyConfig config,
    JourneyStep activeStep,
    int activeIdx,
    Map<String, dynamic> formValues,
    bool showSubmit,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: _IT.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _IT.brand.withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 680;
          if (isWide) {
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left info panel
                  SizedBox(
                    width: 280,
                    child: _buildLeftPanel(
                      activeStep,
                      activeIdx,
                      config.steps.length,
                    ),
                  ),
                  // Vertical divider
                  VerticalDivider(width: 1, color: _IT.divider),
                  // Right form panel
                  Expanded(
                    child: _buildFormPanel(
                      config,
                      activeStep,
                      formValues,
                      showSubmit,
                    ),
                  ),
                ],
              ),
            );
          } else {
            // Stacked layout for narrow screens
            return Column(
              children: [
                _buildLeftPanel(activeStep, activeIdx, config.steps.length),
                const Divider(height: 1, color: _IT.divider),
                _buildFormPanel(config, activeStep, formValues, showSubmit),
              ],
            );
          }
        },
      ),
    );
  }

  // ── LEFT PANEL ────────────────────────────────────────────────────────────
  Widget _buildLeftPanel(JourneyStep activeStep, int activeIdx, int total) {
    return Container(
      decoration: BoxDecoration(
        color: _IT.leftPanelBg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          bottomLeft: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step icon circle
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _IT.brand,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _IT.brand.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                _stepIconForLabel(activeStep.title),
                color: _IT.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            activeStep.title,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _IT.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            activeStep.description,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: _IT.textMid,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          // Illustration placeholder (soft purple abstract shapes)
          Expanded(child: Center(child: _buildIllustration(activeStep.title))),
          const SizedBox(height: 20),
          // Security badge
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _IT.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _IT.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _IT.brandSurface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    color: _IT.brand,
                    size: 17,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your information is safe with us',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _IT.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'We use bank-level security to protect your data.',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
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

  // ── STEP ILLUSTRATION  (contextual icon art, no dependencies) ────────────
  Widget _buildIllustration(String title) {
    final t = title.toLowerCase();
    IconData mainIcon;
    if (t.contains('personal'))
      mainIcon = Icons.assignment_ind_outlined;
    else if (t.contains('vehicle'))
      mainIcon = Icons.directions_car_outlined;
    else if (t.contains('nominee'))
      mainIcon = Icons.people_alt_outlined;
    else if (t.contains('document'))
      mainIcon = Icons.upload_file_outlined;
    else if (t.contains('payment'))
      mainIcon = Icons.payment_outlined;
    else if (t.contains('review'))
      mainIcon = Icons.fact_check_outlined;
    else
      mainIcon = Icons.shield_outlined;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Soft background circles
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            color: _IT.brand.withValues(alpha: 0.06),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: _IT.brand.withValues(alpha: 0.09),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: _IT.brandSurface,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _IT.brand.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(mainIcon, color: _IT.brand, size: 38),
        ),
      ],
    );
  }

  IconData _stepIconForLabel(String title) {
    final t = title.toLowerCase();
    if (t.contains('personal')) return Icons.person_outline_rounded;
    if (t.contains('vehicle')) return Icons.directions_car_outlined;
    if (t.contains('nominee')) return Icons.supervisor_account_outlined;
    if (t.contains('document')) return Icons.upload_file_outlined;
    if (t.contains('review') || t.contains('confirm'))
      return Icons.fact_check_outlined;
    if (t.contains('payment')) return Icons.credit_card_outlined;
    if (t.contains('success')) return Icons.verified_outlined;
    return Icons.article_outlined;
  }

  // ── RIGHT FORM PANEL ──────────────────────────────────────────────────────
  Widget _buildFormPanel(
    JourneyConfig config,
    JourneyStep activeStep,
    Map<String, dynamic> formValues,
    bool showSubmit,
  ) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Form(
        key: _formKey,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: Column(
            key: ValueKey(activeStep.id),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section title
              Text(
                activeStep.title,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _IT.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                activeStep.description,
                style: GoogleFonts.poppins(fontSize: 13, color: _IT.textMid),
              ),
              const SizedBox(height: 24),
              const Divider(color: _IT.divider),
              const SizedBox(height: 20),

              // Fields
              ..._buildRunnerFields(activeStep.fields, formValues),

              const SizedBox(height: 18),
              // Action buttons
              _buildActionButtons(config, activeStep, showSubmit),
            ],
          ),
        ),
      ),
    );
  }

  // ── ACTION BUTTONS ────────────────────────────────────────────────────────
  Widget _buildActionButtons(
    JourneyConfig config,
    JourneyStep activeStep,
    bool showSubmit,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (_stepHistory.isNotEmpty) ...[
          OutlinedButton.icon(
            onPressed: _isExecuting
                ? null
                : () => _runAction(JourneyAction.previous, activeStep, config),
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: Text(
              'Back',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _IT.brand,
              side: const BorderSide(color: _IT.border),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        OutlinedButton.icon(
          onPressed: _isExecuting
              ? null
              : () => _runAction(JourneyAction.saveDraft, activeStep, config),
          icon: const Icon(Icons.bookmark_border_rounded, size: 16),
          label: Text(
            'Save Draft',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: _IT.textMid,
            side: const BorderSide(color: _IT.border),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Primary CTA
        ElevatedButton.icon(
          onPressed: _isExecuting
              ? null
              : () => _runAction(
                  showSubmit ? JourneyAction.submit : JourneyAction.next,
                  activeStep,
                  config,
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
            foregroundColor: _IT.white,
            disabledBackgroundColor: _IT.brand.withValues(alpha: 0.5),
            elevation: 0,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  // ── BOTTOM BAR ────────────────────────────────────────────────────────────
  Widget _buildBottomBar(JourneyConfig config, JourneyStep activeStep) {
    return Container(
      color: _IT.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline_rounded, size: 14, color: _IT.textMid),
          const SizedBox(width: 6),
          Text(
            'You can save your progress and continue later',
            style: GoogleFonts.poppins(fontSize: 12, color: _IT.textMid),
          ),
        ],
      ),
    );
  }

  // ─── FIELD BUILDERS ───────────────────────────────────────────────────────
  List<Widget> _buildRunnerFields(
    List<JourneyField> fields,
    Map<String, dynamic> values,
  ) {
    return fields.map((field) {
      final isVisible = EngineHelper.isFieldVisible(field, values);
      if (!isVisible) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 18.0),
        child: _buildRunnerField(field, values),
      );
    }).toList();
  }

  Widget _buildRunnerField(JourneyField field, Map<String, dynamic> values) {
    final hasError = _errors.containsKey(field.id);
    final errorMsg = _errors[field.id];

    switch (field.type.toLowerCase()) {
      case 'divider':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(
              field.label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _IT.brand,
              ),
            ),
            const SizedBox(height: 6),
            const Divider(color: _IT.divider),
          ],
        );

      case 'dropdown':
        final options = field.getResolvedOptions();
        final display = options.isEmpty ? ["Select"] : options;
        final currentVal = values[field.id]?.toString();
        return DropdownButtonFormField<String>(
          value: display.contains(currentVal) ? currentVal : null,
          decoration: _fieldDecor(
            label: field.label,
            hint: field.placeholder ?? field.hintText,
            prefix: Icon(
              Icons.expand_more_rounded,
              color: _IT.textLight,
              size: 18,
            ),
            errorText: hasError ? errorMsg : null,
          ),
          style: GoogleFonts.poppins(fontSize: 13, color: _IT.textDark),
          dropdownColor: _IT.white,
          borderRadius: BorderRadius.circular(14),
          items: display
              .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
              .toList(),
          onChanged: (val) {
            if (val != null)
              ref.read(formValuesProvider.notifier).updateValue(field.id, val);
          },
        );

      case 'api_dropdown':
        return ApiDropdownWidget(
          field: field,
          initialValue: values[field.id]?.toString(),
          onChanged: (val) =>
              ref.read(formValuesProvider.notifier).updateValue(field.id, val),
          errorText: hasError ? errorMsg : null,
        );

      case 'radio':
        final options = field.getResolvedOptions();
        final currentVal = values[field.id]?.toString();
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
              children: options.map((opt) {
                final isSelected = currentVal == opt;
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
                      color: isSelected ? _IT.brand : _IT.white,
                      border: Border.all(
                        color: isSelected ? _IT.brand : _IT.border,
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          size: 15,
                          color: isSelected ? _IT.white : _IT.textMid,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          opt,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? _IT.white : _IT.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            if (hasError) ...[
              const SizedBox(height: 6),
              Text(
                errorMsg!,
                style: GoogleFonts.poppins(fontSize: 11, color: _IT.error),
              ),
            ],
          ],
        );

      case 'checkbox':
        final currentVal = values[field.id]?.toString() == 'true';
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
            value: currentVal,
            activeColor: _IT.brand,
            checkColor: _IT.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onChanged: (val) => ref
                .read(formValuesProvider.notifier)
                .updateValue(field.id, (val ?? false).toString()),
            subtitle: hasError
                ? Text(
                    errorMsg!,
                    style: GoogleFonts.poppins(fontSize: 11, color: _IT.error),
                  )
                : null,
          ),
        );

      case 'switch':
        final currentVal = values[field.id]?.toString() == 'true';
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
            value: currentVal,
            activeColor: _IT.brand,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            onChanged: (val) => ref
                .read(formValuesProvider.notifier)
                .updateValue(field.id, val.toString()),
            subtitle: hasError
                ? Text(
                    errorMsg!,
                    style: GoogleFonts.poppins(fontSize: 11, color: _IT.error),
                  )
                : null,
          ),
        );

      case 'date':
      case 'time':
      case 'datetime':
        final currentVal = values[field.id]?.toString() ?? '';
        return TextField(
          controller: TextEditingController(text: currentVal),
          readOnly: true,
          style: GoogleFonts.poppins(fontSize: 13, color: _IT.textDark),
          decoration: _fieldDecor(
            label: field.label,
            hint: field.type == 'time' ? 'HH : MM' : 'DD / MM / YYYY',
            prefix: Icon(
              Icons.calendar_today_outlined,
              color: _IT.brand,
              size: 18,
            ),
            errorText: hasError ? errorMsg : null,
          ),
          onTap: () async {
            if (field.type == 'time') {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
                builder: (ctx, child) =>
                    Theme(data: _pickerTheme(), child: child!),
              );
              if (picked != null && context.mounted)
                ref
                    .read(formValuesProvider.notifier)
                    .updateValue(field.id, picked.format(context));
              return;
            }
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
              builder: (ctx, child) =>
                  Theme(data: _pickerTheme(), child: child!),
            );
            if (picked != null) {
              final fmt =
                  "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
              ref.read(formValuesProvider.notifier).updateValue(field.id, fmt);
            }
          },
        );

      case 'number':
        return TextField(
          keyboardType: TextInputType.number,
          style: GoogleFonts.poppins(fontSize: 13, color: _IT.textDark),
          onChanged: (val) =>
              ref.read(formValuesProvider.notifier).updateValue(field.id, val),
          decoration: _fieldDecor(
            label: field.label,
            hint: field.placeholder,
            errorText: hasError ? errorMsg : null,
          ),
        );

      case 'phone':
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: _IT.inputBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _IT.border),
              ),
              alignment: Alignment.center,
              child: Row(
                children: [
                  const Text("🇮🇳", style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 4),
                  Text(
                    "+91",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: _IT.textDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
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
                onChanged: (val) => ref
                    .read(formValuesProvider.notifier)
                    .updateValue(field.id, val),
                decoration: _fieldDecor(
                  label: field.label,
                  hint: field.placeholder ?? 'Enter mobile number',
                  errorText: hasError ? errorMsg : null,
                ),
              ),
            ),
          ],
        );

      case 'email':
        return TextField(
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.poppins(fontSize: 13, color: _IT.textDark),
          onChanged: (val) =>
              ref.read(formValuesProvider.notifier).updateValue(field.id, val),
          decoration: _fieldDecor(
            label: field.label,
            hint: field.placeholder ?? 'Enter email address',
            prefix: const Icon(
              Icons.mail_outline_rounded,
              color: _IT.brand,
              size: 18,
            ),
            errorText: hasError ? errorMsg : null,
          ),
        );

      case 'textarea':
        return TextField(
          maxLines: 4,
          style: GoogleFonts.poppins(fontSize: 13, color: _IT.textDark),
          onChanged: (val) =>
              ref.read(formValuesProvider.notifier).updateValue(field.id, val),
          decoration:
              _fieldDecor(
                label: field.label,
                hint: field.placeholder,
                errorText: hasError ? errorMsg : null,
              ).copyWith(
                alignLabelWithHint: true,
                prefix: Padding(
                  padding: const EdgeInsets.only(left: 4, top: 4),
                  child: Icon(
                    Icons.location_on_outlined,
                    color: _IT.brand,
                    size: 18,
                  ),
                ),
              ),
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
                  width: 46,
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
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      filled: true,
                      fillColor: _IT.inputBg,
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
                    onChanged: (val) {
                      if (val.isNotEmpty && idx < 5)
                        FocusScope.of(context).nextFocus();
                      ref
                          .read(formValuesProvider.notifier)
                          .updateValue(field.id, "123456");
                    },
                  ),
                ),
              ),
            ),
            if (hasError) ...[
              const SizedBox(height: 6),
              Text(
                errorMsg!,
                style: GoogleFonts.poppins(fontSize: 11, color: _IT.error),
              ),
            ],
          ],
        );

      case 'image':
        return _buildUploadField(
          field,
          values,
          hasError,
          errorMsg,
          isImage: true,
        );
      case 'file':
        return _buildUploadField(field, values, hasError, errorMsg);

      case 'table_grid':
        return _buildTableGridRunner(field);
      case 'repeater':
        return _buildRepeaterRunner(field);
      case 'timeline':
        return _buildTimelineRunner(field);
      case 'section':
        return _buildNestedContainer(field, values, Icons.view_agenda_outlined);
      case 'card':
        return _buildNestedContainer(field, values, Icons.crop_square_rounded);
      case 'tabs':
        return _buildNestedTabs(field, values);
      case 'accordion':
        return _buildNestedContainer(field, values, Icons.unfold_more_rounded);
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
          onChanged: (val) =>
              ref.read(formValuesProvider.notifier).updateValue(field.id, val),
          decoration: _fieldDecor(
            label: field.label,
            hint: field.placeholder,
            errorText: hasError ? errorMsg : null,
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

  // ── UPLOAD FIELD ─────────────────────────────────────────────────────────
  Widget _buildUploadField(
    JourneyField field,
    Map<String, dynamic> values,
    bool hasError,
    String? errorMsg, {
    bool isImage = false,
  }) {
    final currentVal = values[field.id]?.toString() ?? '';
    return GestureDetector(
      onTap: () => ref
          .read(formValuesProvider.notifier)
          .updateValue(
            field.id,
            isImage ? "image_uploaded.png" : "document_uploaded.pdf",
          ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _IT.inputBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasError ? _IT.error : _IT.border,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _IT.brandSurface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isImage ? Icons.image_outlined : Icons.cloud_upload_outlined,
                color: _IT.brand,
                size: 24,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              currentVal.isNotEmpty
                  ? currentVal
                  : (isImage
                        ? 'Click to upload image'
                        : 'Drag & Drop or click to upload'),
              style: GoogleFonts.poppins(fontSize: 13, color: _IT.textMid),
            ),
            const SizedBox(height: 4),
            Text(
              'PNG, JPG, PDF up to 10MB',
              style: GoogleFonts.poppins(fontSize: 11, color: _IT.textLight),
            ),
            const SizedBox(height: 14),
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
                  horizontal: 20,
                  vertical: 10,
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
            if (hasError) ...[
              const SizedBox(height: 8),
              Text(
                errorMsg!,
                style: GoogleFonts.poppins(fontSize: 11, color: _IT.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── GRID / REPEATER / TIMELINE / NESTED (carry over, restyled) ───────────
  Map<String, dynamic> _componentConfig(JourneyField field) {
    final config = Map<String, dynamic>.from(field.componentConfig ?? {});
    if (field.type == 'table_grid') {
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
        'filtering': true,
        'stickyColumns': true,
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
        ...config,
      };
    }
    return config;
  }

  List<Map<String, dynamic>> _configList(
    JourneyField field,
    String key,
    List<Map<String, dynamic>> fallback,
  ) {
    final value = _componentConfig(field)[key];
    if (value is List) {
      final parsed = value
          .map(
            (item) => item is Map
                ? Map<String, dynamic>.from(item)
                : <String, dynamic>{},
          )
          .where((item) => item.isNotEmpty)
          .toList();
      if (parsed.isNotEmpty) return parsed;
    }
    return fallback;
  }

  Widget _buildTableGridRunner(JourneyField field) {
    final config = _componentConfig(field);
    final columns = _configList(field, 'columns', [
      if (field.nestedFields != null && field.nestedFields!.isNotEmpty)
        ...field.nestedFields!.map(
          (nested) => {
            'label': nested.label,
            'fieldId': nested.id,
            'type': nested.type,
            'required': nested.required,
          },
        )
      else ...[
        {'label': '#'},
        {'label': 'Name', 'fieldId': 'name', 'required': true},
        {'label': 'Age', 'fieldId': 'age'},
      ],
    ]);
    final allowAdd = config['allowAddRow'] != false;
    final allowDelete = config['allowDeleteRow'] != false;
    final inlineEdit = config['inlineEdit'] != false;
    final bulkSelection = config['bulkSelection'] != false;
    final exportCsv = config['exportCsv'] != false;
    final searchEnabled = config['search'] != false;
    final sortingEnabled = config['sorting'] != false;
    final validationEnabled = config['dynamicRowValidation'] != false;
    final dataSource = config['dataSource']?.toString() ?? 'manual';
    final pagination = config['pagination'] != false;
    final rowActions = config['rowActions'] is List
        ? List<String>.from(
            (config['rowActions'] as List).map((item) => item.toString()),
          )
        : <String>['edit', 'delete'];
    final rowsPerPage =
        int.tryParse(config['rowsPerPage']?.toString() ?? '') ?? 10;
    final maxRows = int.tryParse(config['maxRows']?.toString() ?? '') ?? 10;
    final rows = _ensureGridRows(field, columns, config);
    if (dataSource == 'api' &&
        !_gridApiLoaded.contains(field.id) &&
        !_gridApiLoading.contains(field.id)) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _loadGridRowsFromApi(field, columns, config),
      );
    }
    final search = _gridSearch[field.id] ?? '';
    final sortField = _gridSortField[field.id];
    final sortAscending = _gridSortAscending[field.id] ?? true;
    final selected = _gridSelections.putIfAbsent(field.id, () => <int>{});
    var visibleRows = rows.asMap().entries.where((entry) {
      if (search.trim().isEmpty) return true;
      final q = search.toLowerCase();
      return entry.value.values.any(
        (value) => value.toString().toLowerCase().contains(q),
      );
    }).toList();
    if (sortField != null && sortField.isNotEmpty) {
      visibleRows.sort((a, b) {
        final l = a.value[sortField]?.toString() ?? '';
        final r = b.value[sortField]?.toString() ?? '';
        final c = l.compareTo(r);
        return sortAscending ? c : -c;
      });
    }
    final pagedRows = pagination
        ? visibleRows.take(rowsPerPage).toList()
        : visibleRows;
    final sortColumnIndex = sortField == null
        ? -1
        : columns.indexWhere((c) => _columnFieldId(c) == sortField);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _IT.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _IT.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                if (dataSource == 'api')
                  IconButton(
                    tooltip: "Reload",
                    onPressed: _gridApiLoading.contains(field.id)
                        ? null
                        : () => _loadGridRowsFromApi(
                            field,
                            columns,
                            config,
                            force: true,
                          ),
                    icon: _gridApiLoading.contains(field.id)
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _IT.brand,
                            ),
                          )
                        : const Icon(
                            Icons.refresh_rounded,
                            size: 18,
                            color: _IT.textMid,
                          ),
                  ),
                if (exportCsv)
                  IconButton(
                    tooltip: "Export CSV",
                    onPressed: () => _exportGridCsv(field, columns, rows),
                    icon: const Icon(
                      Icons.download_rounded,
                      size: 18,
                      color: _IT.textMid,
                    ),
                  ),
                if (allowAdd)
                  ElevatedButton.icon(
                    onPressed: rows.length >= maxRows
                        ? null
                        : () => _addGridRow(field, columns),
                    icon: const Icon(Icons.add_rounded, size: 14),
                    label: Text(
                      "Add Row",
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _IT.brand,
                      foregroundColor: _IT.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
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
              padding: const EdgeInsets.all(12),
              child: Text(
                _gridApiErrors[field.id]!,
                style: GoogleFonts.poppins(fontSize: 11, color: _IT.error),
              ),
            ),
          if (searchEnabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                decoration:
                    _fieldDecor(
                      label: '',
                      hint: 'Search rows...',
                      prefix: const Icon(
                        Icons.search_rounded,
                        size: 16,
                        color: _IT.textMid,
                      ),
                    ).copyWith(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                style: GoogleFonts.poppins(fontSize: 12),
                onChanged: (value) =>
                    setState(() => _gridSearch[field.id] = value),
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: DataTable(
              showCheckboxColumn: bulkSelection,
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
              dataRowMinHeight: 48,
              dataRowMaxHeight: 64,
              sortColumnIndex: sortColumnIndex < 0 ? null : sortColumnIndex,
              sortAscending: sortAscending,
              columns: [
                ...columns.map(
                  (col) => DataColumn(
                    label: Text(col['label']?.toString() ?? 'Col'),
                    onSort: sortingEnabled
                        ? (_, asc) => setState(() {
                            _gridSortField[field.id] = _columnFieldId(col);
                            _gridSortAscending[field.id] = asc;
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
              rows: pagedRows.map((entry) {
                final rowIndex = entry.key;
                final row = entry.value;
                return DataRow(
                  selected: selected.contains(rowIndex),
                  onSelectChanged: bulkSelection
                      ? (c) => setState(() {
                          c == true
                              ? selected.add(rowIndex)
                              : selected.remove(rowIndex);
                        })
                      : null,
                  cells: [
                    ...columns.map(
                      (col) => DataCell(
                        _gridCell(
                          field,
                          col,
                          row,
                          rowIndex,
                          inlineEdit,
                          validationEnabled,
                        ),
                      ),
                    ),
                    DataCell(
                      _gridActions(
                        field,
                        columns,
                        rowIndex,
                        row,
                        rowActions,
                        allowDelete,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          if (pagination)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                "${pagedRows.length} of ${visibleRows.length} row(s)",
                style: GoogleFonts.poppins(fontSize: 11, color: _IT.textLight),
              ),
            ),
        ],
      ),
    );
  }

  Widget _gridActions(
    JourneyField field,
    List<Map<String, dynamic>> columns,
    int rowIndex,
    Map<String, dynamic> row,
    List<String> actions,
    bool allowDelete,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: actions.map((action) {
        switch (action.toLowerCase()) {
          case 'delete':
            if (!allowDelete) return const SizedBox.shrink();
            return IconButton(
              tooltip: "Delete",
              onPressed: () => _deleteGridRow(field, rowIndex),
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 16,
                color: Colors.redAccent,
              ),
            );
          case 'duplicate':
            return IconButton(
              tooltip: "Duplicate",
              onPressed: () => _duplicateGridRow(field, columns, row),
              icon: const Icon(
                Icons.copy_rounded,
                size: 15,
                color: _IT.textMid,
              ),
            );
          case 'view':
            return const Icon(
              Icons.visibility_outlined,
              size: 15,
              color: _IT.textMid,
            );
          case 'edit':
            return const Icon(Icons.edit_outlined, size: 15, color: _IT.brand);
          default:
            return const SizedBox.shrink();
        }
      }).toList(),
    );
  }

  List<Map<String, dynamic>> _ensureGridRows(
    JourneyField field,
    List<Map<String, dynamic>> columns,
    Map<String, dynamic> config,
  ) {
    return _gridRows.putIfAbsent(field.id, () {
      final minRows = int.tryParse(config['minRows']?.toString() ?? '') ?? 0;
      if ((config['dataSource']?.toString() ?? 'manual') == 'api')
        return <Map<String, dynamic>>[];
      return List.generate(
        minRows > 0 ? minRows : 1,
        (_) => _emptyGridRow(columns),
      );
    });
  }

  Future<void> _loadGridRowsFromApi(
    JourneyField field,
    List<Map<String, dynamic>> columns,
    Map<String, dynamic> config, {
    bool force = false,
  }) async {
    if (!force && _gridApiLoading.contains(field.id)) return;
    final urlText = config['gridApiUrl']?.toString().trim() ?? '';
    if (urlText.isEmpty) {
      setState(() {
        _gridApiLoaded.add(field.id);
        _gridApiErrors[field.id] = 'Grid API URL is required.';
      });
      return;
    }
    setState(() {
      _gridApiLoading.add(field.id);
      _gridApiErrors.remove(field.id);
    });
    try {
      final uri = _gridApiUri(urlText, config);
      final method = (config['gridApiMethod']?.toString() ?? 'GET')
          .toUpperCase();
      final headers = _gridApiHeaders(config['gridApiHeaders']);
      final bodyText = config['gridApiBody']?.toString().trim() ?? '';
      final body = bodyText.isEmpty ? null : bodyText;
      http.Response response;
      if (method == 'POST') {
        response = await http.post(uri, headers: headers, body: body);
      } else if (method == 'PUT') {
        response = await http.put(uri, headers: headers, body: body);
      } else if (method == 'DELETE') {
        response = await http.delete(uri, headers: headers, body: body);
      } else {
        response = await http.get(uri, headers: headers);
      }
      if (response.statusCode < 200 || response.statusCode >= 300)
        throw Exception('Grid API failed with status ${response.statusCode}');
      final decoded = json.decode(response.body);
      final listKey = config['gridApiListKey']?.toString() ?? '';
      final rows = _normalizeGridApiRows(decoded, listKey, columns);
      setState(() {
        _gridRows[field.id] = rows;
        _gridSelections[field.id]?.clear();
        _gridApiLoaded.add(field.id);
        _gridApiLoading.remove(field.id);
      });
      _syncGridValue(field);
    } catch (e) {
      setState(() {
        _gridApiLoaded.add(field.id);
        _gridApiLoading.remove(field.id);
        _gridApiErrors[field.id] = e.toString();
      });
    }
  }

  Uri _gridApiUri(String urlText, Map<String, dynamic> config) {
    final uri = Uri.parse(urlText);
    if (config['apiPagination'] != true) return uri;
    final pageParam = config['apiPageParam']?.toString() ?? 'page';
    final sizeParam = config['apiPageSizeParam']?.toString() ?? 'limit';
    final rowsPerPage = config['rowsPerPage']?.toString() ?? '10';
    return uri.replace(
      queryParameters: {
        ...uri.queryParameters,
        if (pageParam.isNotEmpty) pageParam: '1',
        if (sizeParam.isNotEmpty) sizeParam: rowsPerPage,
      },
    );
  }

  Map<String, String> _gridApiHeaders(dynamic rawHeaders) {
    final headers = <String, String>{};
    if (rawHeaders is Map) {
      rawHeaders.forEach(
        (key, value) => headers[key.toString()] = value.toString(),
      );
    } else if (rawHeaders is String && rawHeaders.trim().isNotEmpty) {
      final decoded = json.decode(rawHeaders);
      if (decoded is Map) {
        decoded.forEach(
          (key, value) => headers[key.toString()] = value.toString(),
        );
      }
    }
    return headers;
  }

  List<Map<String, dynamic>> _normalizeGridApiRows(
    dynamic decoded,
    String listKey,
    List<Map<String, dynamic>> columns,
  ) {
    dynamic source = decoded;
    if (decoded is Map && listKey.trim().isNotEmpty) {
      source = _readJsonPath(decoded, listKey) ?? decoded[listKey];
    }
    if (source is! List && decoded is Map) {
      for (final key in ['data', 'items', 'results', 'rows']) {
        if (decoded[key] is List) {
          source = decoded[key];
          break;
        }
      }
    }
    if (source is! List) return <Map<String, dynamic>>[];
    return source.map<Map<String, dynamic>>((item) {
      if (item is Map) return Map<String, dynamic>.from(item);
      final row = _emptyGridRow(columns);
      if (columns.isNotEmpty)
        row[_columnFieldId(columns.first)] = item.toString();
      return row;
    }).toList();
  }

  dynamic _readJsonPath(dynamic source, String path) {
    if (path.trim().isEmpty) return null;
    dynamic cursor = source;
    for (final part in path.split('.')) {
      if (cursor is Map) {
        cursor = cursor[part];
      } else {
        return null;
      }
    }
    return cursor;
  }

  Map<String, dynamic> _emptyGridRow(List<Map<String, dynamic>> columns) => {
    for (final col in columns) _columnFieldId(col): '',
  };
  String _columnFieldId(Map<String, dynamic> col) =>
      (col['fieldId'] ?? col['key'] ?? col['label'] ?? 'column').toString();

  Widget _gridCell(
    JourneyField field,
    Map<String, dynamic> column,
    Map<String, dynamic> row,
    int rowIndex,
    bool inlineEdit,
    bool validationEnabled,
  ) {
    final fieldId = _columnFieldId(column);
    final value = row[fieldId]?.toString() ?? '';
    final required = column['required'] == true;
    final hasError = validationEnabled && required && value.trim().isEmpty;
    if (!inlineEdit)
      return Text(
        value.isEmpty ? '-' : value,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: hasError ? _IT.error : _IT.textMid,
        ),
      );
    return SizedBox(
      width: 140,
      child: TextFormField(
        initialValue: value,
        decoration: InputDecoration(
          isDense: true,
          hintText: column['label']?.toString(),
          errorText: hasError ? "Required" : null,
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
        keyboardType: column['type'] == 'number'
            ? TextInputType.number
            : TextInputType.text,
        style: GoogleFonts.poppins(fontSize: 12, color: _IT.textDark),
        onChanged: (v) => _updateGridCell(field, rowIndex, fieldId, v),
      ),
    );
  }

  void _addGridRow(JourneyField field, List<Map<String, dynamic>> columns) =>
      setState(() {
        _gridRows.putIfAbsent(field.id, () => []).add(_emptyGridRow(columns));
        _syncGridValue(field);
      });
  void _deleteGridRow(JourneyField field, int rowIndex) => setState(() {
    final rows = _gridRows[field.id];
    if (rows == null || rowIndex < 0 || rowIndex >= rows.length) return;
    rows.removeAt(rowIndex);
    _gridSelections[field.id]?.remove(rowIndex);
    _syncGridValue(field);
  });
  void _duplicateGridRow(
    JourneyField field,
    List<Map<String, dynamic>> columns,
    Map<String, dynamic> row,
  ) => setState(() {
    _gridRows.putIfAbsent(field.id, () => []).add({
      ..._emptyGridRow(columns),
      ...row,
    });
    _syncGridValue(field);
  });
  void _deleteSelectedGridRows(JourneyField field) => setState(() {
    final rows = _gridRows[field.id];
    final selected = _gridSelections[field.id];
    if (rows == null || selected == null) return;
    final sorted = selected.toList()..sort((a, b) => b.compareTo(a));
    for (final i in sorted) {
      if (i >= 0 && i < rows.length) rows.removeAt(i);
    }
    selected.clear();
    _syncGridValue(field);
  });
  void _updateGridCell(
    JourneyField field,
    int rowIndex,
    String fieldId,
    String value,
  ) => setState(() {
    final rows = _gridRows[field.id];
    if (rows == null || rowIndex < 0 || rowIndex >= rows.length) return;
    rows[rowIndex][fieldId] = value;
    _syncGridValue(field);
  });
  void _syncGridValue(JourneyField field) => ref
      .read(formValuesProvider.notifier)
      .updateValue(field.id, jsonEncode(_gridRows[field.id] ?? []));

  void _exportGridCsv(
    JourneyField field,
    List<Map<String, dynamic>> columns,
    List<Map<String, dynamic>> rows,
  ) {
    final headers = columns
        .map((col) => col['label']?.toString() ?? _columnFieldId(col))
        .toList();
    final keys = columns.map(_columnFieldId).toList();
    final csv = [
      headers.map(_escapeCsv).join(','),
      ...rows.map(
        (row) =>
            keys.map((k) => _escapeCsv(row[k]?.toString() ?? '')).join(','),
      ),
    ].join('\n');
    Clipboard.setData(ClipboardData(text: csv));
    _snackSuccess("CSV copied to clipboard");
  }

  String _escapeCsv(String v) {
    final e = v.replaceAll('"', '""');
    return v.contains(',') || v.contains('"') || v.contains('\n') ? '"$e"' : e;
  }

  Widget _buildRepeaterRunner(JourneyField field) {
    final config = _componentConfig(field);
    final nestedFields = field.nestedFields ?? const <JourneyField>[];
    final allowAdd = config['allowAdd'] != false;
    final allowRemove = config['allowRemove'] != false;
    final itemLabel = config['itemLabel']?.toString() ?? 'Item';
    final addLabel = config['addButtonLabel']?.toString() ?? 'Add $itemLabel';
    final maxRows = int.tryParse(config['maxRows']?.toString() ?? '') ?? 20;
    final rows = _repeaterRows.putIfAbsent(
      field.id,
      () => [_emptyRepeaterRow(nestedFields)],
    );

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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ...rows.asMap().entries.map((entry) {
                  final rowIndex = entry.key;
                  final rowValues = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
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
                                '$itemLabel ${rowIndex + 1}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _IT.textDark,
                                ),
                              ),
                            ),
                            if (allowRemove && rows.length > 1)
                              GestureDetector(
                                onTap: () => setState(() {
                                  _repeaterRows[field.id]!.removeAt(rowIndex);
                                  _syncRepeaterValue(field);
                                }),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 14,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (nestedFields.isNotEmpty)
                          ...nestedFields.map(
                            (nf) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _buildRepeaterCell(
                                field,
                                rowIndex,
                                nf,
                                rowValues,
                              ),
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
                  );
                }),
                if (allowAdd && rows.length < maxRows)
                  OutlinedButton.icon(
                    onPressed: () => setState(() {
                      _repeaterRows[field.id]!.add(
                        _emptyRepeaterRow(nestedFields),
                      );
                      _syncRepeaterValue(field);
                    }),
                    icon: const Icon(Icons.add_rounded, size: 14),
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
                        horizontal: 16,
                        vertical: 10,
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

  Map<String, dynamic> _emptyRepeaterRow(List<JourneyField> fields) => {
    for (final f in fields) f.id: f.defaultValue ?? '',
  };
  void _syncRepeaterValue(JourneyField field) => ref
      .read(formValuesProvider.notifier)
      .updateValue(
        field.id,
        List<Map<String, dynamic>>.from(_repeaterRows[field.id] ?? []),
      );

  Widget _buildRepeaterCell(
    JourneyField repeaterField,
    int rowIndex,
    JourneyField cellField,
    Map<String, dynamic> rowValues,
  ) {
    final currentVal = rowValues[cellField.id]?.toString() ?? '';
    void updateCell(dynamic val) => setState(() {
      _repeaterRows[repeaterField.id]![rowIndex][cellField.id] = val;
      _syncRepeaterValue(repeaterField);
    });
    switch (cellField.type.toLowerCase()) {
      case 'dropdown':
        final opts = cellField.getResolvedOptions();
        return DropdownButtonFormField<String>(
          value: opts.contains(currentVal) ? currentVal : null,
          decoration: _fieldDecor(
            label: cellField.label,
          ).copyWith(isDense: true),
          dropdownColor: _IT.white,
          items: opts
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: (v) {
            if (v != null) updateCell(v);
          },
        );
      case 'checkbox':
      case 'switch':
        return CheckboxListTile(
          title: Text(
            cellField.label,
            style: GoogleFonts.poppins(fontSize: 12),
          ),
          value: currentVal == 'true',
          activeColor: _IT.brand,
          contentPadding: EdgeInsets.zero,
          onChanged: (v) => updateCell((v ?? false).toString()),
        );
      default:
        return TextFormField(
          initialValue: currentVal,
          decoration: _fieldDecor(
            label: cellField.label,
          ).copyWith(isDense: true),
          keyboardType: cellField.type == 'number'
              ? TextInputType.number
              : TextInputType.text,
          style: GoogleFonts.poppins(fontSize: 12, color: _IT.textDark),
          onChanged: updateCell,
        );
    }
  }

  Widget _buildTimelineRunner(JourneyField field) {
    final items = _configList(field, 'items', [
      {
        'title': 'Started',
        'description': 'Journey started',
        'status': 'completed',
      },
      {'title': 'Current', 'description': 'Current step', 'status': 'active'},
      {'title': 'Completed', 'description': 'Final state', 'status': 'pending'},
    ]);
    Color statusColor(String? s) => s == 'completed'
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
      padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 14),
          ...items.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final color = statusColor(item['status']?.toString());
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (idx < items.length - 1)
                      Container(width: 2, height: 36, color: _IT.border),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title']?.toString() ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _IT.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item['description']?.toString() ?? '',
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
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNestedContainer(
    JourneyField field,
    Map<String, dynamic> values,
    IconData icon,
  ) {
    final children = field.nestedFields ?? const <JourneyField>[];
    return Container(
      decoration: BoxDecoration(
        color: _IT.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _IT.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _IT.brandSurface,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: _IT.brand),
              ),
              const SizedBox(width: 10),
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
            ],
          ),
          if (children.isNotEmpty) ...[
            const SizedBox(height: 14),
            ..._buildRunnerFields(children, values),
          ],
        ],
      ),
    );
  }

  Widget _buildNestedRow(JourneyField field, Map<String, dynamic> values) {
    final children = (field.nestedFields ?? const <JourneyField>[])
        .where((c) => EngineHelper.isFieldVisible(c, values))
        .toList();
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: children.map((child) {
        final colSpan =
            int.tryParse(child.componentConfig?['colSpan']?.toString() ?? '') ??
            12;
        final width = MediaQuery.of(context).size.width;
        final itemWidth = width > 760
            ? ((width - 220) * (colSpan.clamp(1, 12) / 12))
            : double.infinity;
        return SizedBox(
          width: itemWidth,
          child: _buildRunnerField(child, values),
        );
      }).toList(),
    );
  }

  Widget _buildNestedTabs(JourneyField field, Map<String, dynamic> values) {
    final tabs = field.nestedFields ?? const <JourneyField>[];
    if (tabs.isEmpty)
      return _buildNestedContainer(field, values, Icons.tab_rounded);
    return DefaultTabController(
      length: tabs.length,
      child: Container(
        decoration: BoxDecoration(
          color: _IT.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _IT.border),
        ),
        padding: const EdgeInsets.all(16),
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
              tabs: tabs.map((tab) => Tab(text: tab.label)).toList(),
            ),
            SizedBox(
              height: 320,
              child: TabBarView(
                children: tabs
                    .map(
                      (tab) => SingleChildScrollView(
                        padding: const EdgeInsets.only(top: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _buildRunnerFields(
                            tab.nestedFields ?? const <JourneyField>[],
                            values,
                          ),
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
// API DROPDOWN WIDGET  (restyled)
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
  ConsumerState<ApiDropdownWidget> createState() => _ApiDropdownWidgetState();
}

class _ApiDropdownWidgetState extends ConsumerState<ApiDropdownWidget> {
  List<String> _options = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchOptions();
  }

  @override
  void didUpdateWidget(ApiDropdownWidget old) {
    super.didUpdateWidget(old);
    if (old.field.dropdownApiUrl != widget.field.dropdownApiUrl)
      _fetchOptions();
  }

  Future<void> _fetchOptions() async {
    final urlStr = widget.field.dropdownApiUrl;
    if (urlStr == null || urlStr.trim().isEmpty) {
      setState(() {
        _options = widget.field.options ?? ["Select"];
        _isLoading = false;
        _error = "No API URL configured";
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await http
          .get(Uri.parse(urlStr.trim()))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List<String> parsedOptions = [];
        void extractList(dynamic data) {
          if (data is List) {
            final displayKey = widget.field.dropdownValue ?? 'title';
            for (var item in data) {
              if (item is String) {
                parsedOptions.add(item);
              } else if (item is num || item is bool) {
                parsedOptions.add(item.toString());
              } else if (item is Map) {
                if (item.containsKey(displayKey) && item[displayKey] != null) {
                  parsedOptions.add(item[displayKey].toString());
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
                  String? found;
                  for (var k in keys) {
                    if (item.containsKey(k) && item[k] != null) {
                      found = item[k].toString();
                      break;
                    }
                  }
                  found ??= item.isNotEmpty
                      ? item.values.first.toString()
                      : null;
                  if (found != null) parsedOptions.add(found);
                }
              }
            }
          }
        }

        final responseKey = widget.field.dropdownApiResponseKey;
        if (decoded is List) {
          extractList(decoded);
        } else if (decoded is Map) {
          bool foundList = false;
          if (responseKey != null &&
              responseKey.isNotEmpty &&
              decoded[responseKey] is List) {
            extractList(decoded[responseKey]);
            foundList = true;
          }
          if (!foundList) {
            for (var k in ['data', 'results', 'items', 'users', 'options']) {
              if (decoded[k] is List) {
                extractList(decoded[k]);
                foundList = true;
                break;
              }
            }
          }
          if (!foundList) {
            for (var val in decoded.values) {
              if (val is List) {
                extractList(val);
                foundList = true;
                break;
              }
            }
          }
          if (!foundList) _error = "Could not find list in response";
        } else {
          _error = "Invalid JSON response format";
        }
        if (parsedOptions.isEmpty && _error == null)
          _error = "No options found in response";
        setState(() {
          _options = parsedOptions.isNotEmpty ? parsedOptions : ["Select"];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = "HTTP error: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Connection failed";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _error != null || widget.errorText != null;
    final displayError = _error ?? widget.errorText;
    return DropdownButtonFormField<String>(
      value: _options.contains(widget.initialValue)
          ? widget.initialValue
          : null,
      decoration: _fieldDecor(
        label: widget.field.label,
        hint: widget.field.placeholder ?? "Select option",
        errorText: hasError ? displayError : null,
        suffix: _isLoading
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(_IT.brand),
                  ),
                ),
              )
            : _error != null
            ? IconButton(
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Colors.amber,
                  size: 18,
                ),
                tooltip: "Retry",
                onPressed: _fetchOptions,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              )
            : null,
      ),
      style: GoogleFonts.poppins(fontSize: 13, color: _IT.textDark),
      dropdownColor: _IT.white,
      borderRadius: BorderRadius.circular(14),
      items: _options
          .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
          .toList(),
      onChanged: _isLoading
          ? null
          : (val) {
              if (val != null) widget.onChanged(val);
            },
    );
  }
}

// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter/services.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:go_router/go_router.dart';
// import 'package:http/http.dart' as http;
// import 'package:revojourneytryone/features/journey_runner/presentation/screens/stepper.dart';
// import '../../../../core/theme.dart';
// import '../../../journey_builder/data/models.dart';
// import '../../../journey_builder/presentation/providers/journey_provider.dart';
// import '../../application/journey_draft_store.dart';
// import '../../application/journey_execution_engine.dart';
// import '../../domain/journey_execution_models.dart';
// import 'advanced_formula_field_widget.dart';

// class JourneyRunnerScreen extends ConsumerStatefulWidget {
//   const JourneyRunnerScreen({super.key, this.initialStepId});

//   final String? initialStepId;

//   @override
//   ConsumerState<JourneyRunnerScreen> createState() =>
//       _JourneyRunnerScreenState();
// }

// class _JourneyRunnerScreenState extends ConsumerState<JourneyRunnerScreen> {
//   final _engine = JourneyExecutionEngine();
//   String? _runnerStepId;
//   List<String> _stepHistory = [];
//   bool _isExecuting = false;
//   final _formKey = GlobalKey<FormState>();
//   final Map<String, String> _errors = {};
//   final Map<String, List<Map<String, dynamic>>> _gridRows = {};
//   final Map<String, Set<int>> _gridSelections = {};
//   // repeater state: fieldId → list of per-row value maps
//   final Map<String, List<Map<String, dynamic>>> _repeaterRows = {};
//   final Map<String, String> _gridSearch = {};
//   final Map<String, String> _gridSortField = {};
//   final Map<String, bool> _gridSortAscending = {};
//   final Set<String> _gridApiLoaded = {};
//   final Set<String> _gridApiLoading = {};
//   final Map<String, String> _gridApiErrors = {};

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _bootstrapRunner();
//     });
//   }

//   void _bootstrapRunner() {
//     final config = ref.read(journeyConfigProvider);
//     if (config.steps.isEmpty) return;

//     final draft = ref.read(journeyDraftStoreProvider)[config.journeyName];
//     if (draft != null) {
//       _offerResumeDraft(config, draft);
//       return;
//     }

//     final initialStepId = widget.initialStepId;
//     final step = initialStepId != null
//         ? config.steps.firstWhere(
//             (s) => s.id == initialStepId,
//             orElse: () => config.steps.first,
//           )
//         : config.steps.first;

//     setState(() {
//       _runnerStepId = step.id;
//       _stepHistory = [];
//     });
//     ref.read(formValuesProvider.notifier).mergeStepDefaults(step);
//   }

//   Future<void> _offerResumeDraft(
//     JourneyConfig config,
//     JourneyDraft draft,
//   ) async {
//     if (!mounted) return;
//     final resume = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: RevoTheme.cardBg,
//         title: const Text('Resume Journey?'),
//         content: Text(
//           'A saved draft was found for "${config.journeyName}" '
//           '(step: ${draft.currentStepId}).',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Start Fresh'),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text('Resume'),
//           ),
//         ],
//       ),
//     );

//     if (!mounted) return;

//     if (resume == true) {
//       await _runAction(
//         JourneyAction.resume,
//         config.steps.firstWhere(
//           (s) => s.id == draft.currentStepId,
//           orElse: () => config.steps.first,
//         ),
//         config,
//         draftToResume: draft,
//       );
//       return;
//     }

//     ref.read(journeyDraftStoreProvider.notifier).clearDraft(config.journeyName);
//     final first = config.steps.first;
//     setState(() {
//       _runnerStepId = first.id;
//       _stepHistory = [];
//     });
//     ref.read(formValuesProvider.notifier).mergeStepDefaults(first);
//   }

//   void _syncRoute(String stepId) {
//     if (!mounted) return;
//     final current = GoRouterState.of(context).uri.queryParameters['step'];
//     if (current == stepId) return;
//     context.go(
//       Uri(path: '/runner', queryParameters: {'step': stepId}).toString(),
//     );
//   }

//   Future<void> _runAction(
//     JourneyAction action,
//     JourneyStep currentStep,
//     JourneyConfig config, {
//     JourneyDraft? draftToResume,
//   }) async {
//     if (_isExecuting || _engine.isLocked) return;

//     setState(() {
//       _isExecuting = true;
//       if (action != JourneyAction.resume) {
//         _errors.clear();
//       }
//     });

//     final values = ref.read(formValuesProvider);
//     final result = await _engine.execute(
//       JourneyExecutionRequest(
//         action: action,
//         config: config,
//         currentStep: currentStep,
//         formValues: values,
//         stepHistory: _stepHistory,
//         draftToResume: draftToResume,
//       ),
//     );

//     if (!mounted) return;

//     setState(() => _isExecuting = false);

//     if (result.status == JourneyExecutionStatus.busy) return;

//     if (result.status == JourneyExecutionStatus.validationFailed) {
//       setState(() {
//         _errors
//           ..clear()
//           ..addAll(result.fieldErrors);
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(result.message ?? 'Validation failed.'),
//           backgroundColor: RevoTheme.error,
//         ),
//       );
//       return;
//     }

//     if (result.status == JourneyExecutionStatus.apiFailed) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(result.message ?? 'API execution failed.'),
//           backgroundColor: RevoTheme.error,
//         ),
//       );
//       return;
//     }

//     if (result.status == JourneyExecutionStatus.notFound ||
//         result.status == JourneyExecutionStatus.noDraft) {
//       if (result.message != null) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text(result.message!)));
//       }
//       return;
//     }

//     if (result.savedDraft != null) {
//       ref
//           .read(journeyDraftStoreProvider.notifier)
//           .saveDraft(result.savedDraft!);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(result.message ?? 'Draft saved.'),
//           backgroundColor: RevoTheme.secondary,
//         ),
//       );
//       return;
//     }

//     ref
//         .read(formValuesProvider.notifier)
//         .restoreSession(
//           values: result.formValues,
//           step: result.targetStepId != null
//               ? config.steps.firstWhere(
//                   (s) => s.id == result.targetStepId,
//                   orElse: () => currentStep,
//                 )
//               : null,
//         );

//     if (result.journeyCompleted) {
//       ref
//           .read(journeyDraftStoreProvider.notifier)
//           .clearDraft(config.journeyName);
//       _recordCompletedRun(config, currentStep, result.formValues);
//       _showCompletionDialog();
//       return;
//     }

//     if (result.targetStepId != null) {
//       setState(() {
//         _runnerStepId = result.targetStepId;
//         _stepHistory = result.stepHistory;
//       });
//       _syncRoute(result.targetStepId!);
//     }
//   }

//   void _recordCompletedRun(
//     JourneyConfig config,
//     JourneyStep step,
//     Map<String, dynamic> values,
//   ) {
//     final currentRuns = ref.read(journeyRunsProvider);
//     final nextRunNumber = 1050 + currentRuns.length;
//     final userEmail =
//         values['email']?.toString() ??
//         values['mobile']?.toString() ??
//         'anonymous@revo.com';

//     ref.read(journeyRunsProvider.notifier).addRun({
//       'id': 'RUN-$nextRunNumber',
//       'journeyName': config.journeyName,
//       'user': userEmail,
//       'status': 'Completed',
//       'currentStep': step.title,
//       'progress': 1.0,
//       'stepsCount': '${config.steps.length}/${config.steps.length}',
//       'started': 'Just now',
//       'data': Map<String, dynamic>.from(values),
//     });
//   }

//   void _showCompletionDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: RevoTheme.cardBg,
//         title: const Text('Journey Completed!'),
//         content: const Text(
//           'All steps have been completed and validated successfully.',
//         ),
//         actions: [
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(context);
//               context.pop();
//             },
//             child: const Text('Back to Dashboard'),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     ref.watch(themeModeProvider);
//     final config = ref.watch(journeyConfigProvider);
//     if (config.steps.isEmpty) {
//       return const Scaffold(
//         body: Center(child: Text("No steps defined in configuration")),
//       );
//     }

//     final activeId = _runnerStepId ?? config.steps.first.id;
//     final activeStepIndex = config.steps.indexWhere((s) => s.id == activeId);
//     final activeStep = activeStepIndex != -1
//         ? config.steps[activeStepIndex]
//         : config.steps.first;
//     final formValues = ref.watch(formValuesProvider);
//     final showSubmit = _engine.shouldShowSubmit(activeStep, formValues);

//     return Scaffold(
//       backgroundColor: RevoTheme.background,
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Top Nav Header
//             _buildRunnerHeader(context, config, activeStep),

//             // Timelines step indicator
//             _buildTimeline(config, activeStepIndex),

//             // Form container wrapper
//             Expanded(
//               child: Center(
//                 child: SingleChildScrollView(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 24,
//                     vertical: 32,
//                   ),
//                   child: Container(
//                     width: 550,
//                     decoration: BoxDecoration(
//                       color: RevoTheme.cardBg.withValues(alpha: 0.7),
//                       borderRadius: BorderRadius.circular(24),
//                       border: Border.all(
//                         color: RevoTheme.cardBorder.withValues(alpha: 0.5),
//                       ),
//                       boxShadow: [
//                         BoxShadow(
//                           color: RevoTheme.primary.withValues(alpha: 0.1),
//                           blurRadius: 40,
//                           offset: const Offset(0, 10),
//                         ),
//                       ],
//                     ),
//                     padding: const EdgeInsets.all(40),
//                     child: Form(
//                       key: _formKey,
//                       child: AnimatedSwitcher(
//                         duration: const Duration(milliseconds: 300),
//                         child: Column(
//                           key: ValueKey(activeStep.id),
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Text(
//                               activeStep.title,
//                               style: GoogleFonts.outfit(
//                                 fontSize: 24,
//                                 fontWeight: FontWeight.bold,
//                                 color: RevoTheme.textPrimary,
//                               ),
//                             ),
//                             const SizedBox(height: 8),
//                             Text(
//                               activeStep.description,
//                               style: GoogleFonts.inter(
//                                 fontSize: 13,
//                                 color: RevoTheme.textSecondary,
//                               ),
//                             ),
//                             const SizedBox(height: 24),

//                             // Fields List
//                             ..._buildRunnerFields(
//                               activeStep.fields,
//                               formValues,
//                             ),

//                             const SizedBox(height: 24),
//                             // Button actions
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 if (_stepHistory.isNotEmpty)
//                                   OutlinedButton(
//                                     onPressed: _isExecuting
//                                         ? null
//                                         : () => _runAction(
//                                             JourneyAction.previous,
//                                             activeStep,
//                                             config,
//                                           ),
//                                     style: OutlinedButton.styleFrom(
//                                       padding: const EdgeInsets.symmetric(
//                                         horizontal: 24,
//                                         vertical: 16,
//                                       ),
//                                     ),
//                                     child: const Text('Back'),
//                                   )
//                                 else
//                                   const SizedBox.shrink(),
//                                 Row(
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     OutlinedButton(
//                                       onPressed: _isExecuting
//                                           ? null
//                                           : () => _runAction(
//                                               JourneyAction.saveDraft,
//                                               activeStep,
//                                               config,
//                                             ),
//                                       style: OutlinedButton.styleFrom(
//                                         padding: const EdgeInsets.symmetric(
//                                           horizontal: 16,
//                                           vertical: 16,
//                                         ),
//                                       ),
//                                       child: const Text('Save Draft'),
//                                     ),
//                                     const SizedBox(width: 12),
//                                     ElevatedButton(
//                                       onPressed: _isExecuting
//                                           ? null
//                                           : () => _runAction(
//                                               showSubmit
//                                                   ? JourneyAction.submit
//                                                   : JourneyAction.next,
//                                               activeStep,
//                                               config,
//                                             ),
//                                       style: ElevatedButton.styleFrom(
//                                         padding: const EdgeInsets.symmetric(
//                                           horizontal: 32,
//                                           vertical: 16,
//                                         ),
//                                       ),
//                                       child: _isExecuting
//                                           ? const SizedBox(
//                                               width: 18,
//                                               height: 18,
//                                               child: CircularProgressIndicator(
//                                                 strokeWidth: 2,
//                                                 color: Colors.white,
//                                               ),
//                                             )
//                                           : Text(
//                                               showSubmit ? 'Submit' : 'Next',
//                                             ),
//                                     ),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildRunnerHeader(
//     BuildContext context,
//     JourneyConfig config,
//     JourneyStep activeStep,
//   ) {
//     return Container(
//       height: 64,
//       padding: const EdgeInsets.symmetric(horizontal: 24),
//       decoration: BoxDecoration(
//         color: RevoTheme.sidebarBackground,
//         border: Border(
//           bottom: BorderSide(color: RevoTheme.cardBorder, width: 1),
//         ),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Expanded(
//             child: Row(
//               children: [
//                 IconButton(
//                   icon: Icon(
//                     Icons.arrow_back_rounded,
//                     color: RevoTheme.textPrimary,
//                   ),
//                   onPressed: () => context.pop(),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Text(
//                     config.journeyName,
//                     style: GoogleFonts.outfit(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           IconButton(
//             icon: Icon(Icons.close_rounded, color: RevoTheme.textSecondary),
//             onPressed: () => context.pop(),
//           ),
//         ],
//       ),
//     );
//   }


// Widget _buildTimeline(JourneyConfig config, int activeIndex) {
//   return JourneyTimeline(
//     steps: config.steps,
//     activeIndex: activeIndex,
//     onStepTap: (index) {
//       // Only allow if index <= activeIndex (already visited)
//       if (index <= activeIndex) {
//         _runAction(
//           JourneyAction.previous, // you may need to implement this action
//           config.steps[index],
//           config,
//         );
//       }
//     },
//   );
// }


// void _onStepTap(String stepId) {
//   // Optional: implement navigation to previous/completed steps
//   // Only allow if step is already visited (index <= activeIndex)
//   // Use existing _runAction with a new action or direct state update
//   // For safety, we'll leave as a placeholder – you can connect it:
//   // if (canGoToStep(stepId)) {
//   //   _runAction(JourneyAction.goToStep, ...);
//   // }
//   ScaffoldMessenger.of(context).showSnackBar(
//     SnackBar(content: Text('Tap to navigate to $stepId'), duration: Duration(seconds: 1)),
//   );
// }

//   Widget _buildRunnerField(JourneyField field, Map<String, dynamic> values) {
//     final hasError = _errors.containsKey(field.id);
//     final errorMsg = _errors[field.id];

//     switch (field.type.toLowerCase()) {
//       case 'divider':
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const SizedBox(height: 12),
//             Text(
//               field.label,
//               style: GoogleFonts.outfit(
//                 fontSize: 14,
//                 fontWeight: FontWeight.bold,
//                 color: RevoTheme.primaryLight,
//               ),
//             ),
//             const SizedBox(height: 6),
//             Divider(color: RevoTheme.cardBorder),
//           ],
//         );

//       case 'dropdown':
//         final options = field.getResolvedOptions();
//         final displayOptions = options.isEmpty ? ["Select"] : options;
//         final currentVal = values[field.id]?.toString();
//         return DropdownButtonFormField<String>(
//           initialValue: displayOptions.contains(currentVal) ? currentVal : null,
//           decoration: InputDecoration(
//             labelText: field.label,
//             hintText: field.placeholder ?? field.hintText,
//             errorText: hasError ? errorMsg : null,
//           ),
//           dropdownColor: RevoTheme.cardBg,
//           items: displayOptions.map((opt) {
//             return DropdownMenuItem(value: opt, child: Text(opt));
//           }).toList(),
//           onChanged: (val) {
//             if (val != null) {
//               ref.read(formValuesProvider.notifier).updateValue(field.id, val);
//             }
//           },
//         );

//       case 'api_dropdown':
//         final currentVal = values[field.id]?.toString();
//         return ApiDropdownWidget(
//           field: field,
//           initialValue: currentVal,
//           onChanged: (val) {
//             ref.read(formValuesProvider.notifier).updateValue(field.id, val);
//           },
//           errorText: hasError ? errorMsg : null,
//         );

//       case 'radio':
//         final options = field.getResolvedOptions();
//         final displayOptions = options.isEmpty ? [] : options;
//         final currentVal = values[field.id]?.toString();
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               field.label,
//               style: GoogleFonts.inter(
//                 fontSize: 12,
//                 fontWeight: FontWeight.bold,
//                 color: RevoTheme.textPrimary,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Wrap(
//               spacing: 12,
//               children: displayOptions.map((opt) {
//                 final isSelected = currentVal == opt;
//                 return ChoiceChip(
//                   label: Text(opt),
//                   selected: isSelected,
//                   selectedColor: RevoTheme.primary,
//                   backgroundColor: RevoTheme.cardBg,
//                   checkmarkColor: Colors.white,
//                   onSelected: (selected) {
//                     if (selected) {
//                       ref
//                           .read(formValuesProvider.notifier)
//                           .updateValue(field.id, opt);
//                     }
//                   },
//                 );
//               }).toList(),
//             ),
//             if (hasError) ...[
//               const SizedBox(height: 6),
//               Text(
//                 errorMsg!,
//                 style: const TextStyle(color: Colors.red, fontSize: 10),
//               ),
//             ],
//           ],
//         );

//       case 'checkbox':
//         final currentVal = values[field.id]?.toString() == 'true';
//         return CheckboxListTile(
//           title: Text(field.label, style: GoogleFonts.inter(fontSize: 12)),
//           value: currentVal,
//           activeColor: RevoTheme.primary,
//           checkColor: Colors.white,
//           contentPadding: EdgeInsets.zero,
//           onChanged: (val) {
//             ref
//                 .read(formValuesProvider.notifier)
//                 .updateValue(field.id, (val ?? false).toString());
//           },
//           subtitle: hasError
//               ? Text(
//                   errorMsg!,
//                   style: const TextStyle(color: Colors.red, fontSize: 10),
//                 )
//               : null,
//         );

//       case 'switch':
//         final currentVal = values[field.id]?.toString() == 'true';
//         return SwitchListTile(
//           title: Text(field.label, style: GoogleFonts.inter(fontSize: 12)),
//           value: currentVal,
//           activeThumbColor: RevoTheme.primaryLight,
//           contentPadding: EdgeInsets.zero,
//           onChanged: (val) {
//             ref
//                 .read(formValuesProvider.notifier)
//                 .updateValue(field.id, val.toString());
//           },
//           subtitle: hasError
//               ? Text(
//                   errorMsg!,
//                   style: const TextStyle(color: Colors.red, fontSize: 10),
//                 )
//               : null,
//         );

//       case 'date':
//       case 'time':
//       case 'datetime':
//         final currentVal = values[field.id]?.toString() ?? '';
//         return TextField(
//           controller: TextEditingController(text: currentVal),
//           readOnly: true,
//           decoration: InputDecoration(
//             labelText: field.label,
//             hintText:
//                 field.placeholder ??
//                 (field.type == 'time' ? 'Select Time' : 'Select Date'),
//             suffixIcon: Icon(
//               Icons.calendar_today_rounded,
//               color: RevoTheme.textSecondary,
//             ),
//             errorText: hasError ? errorMsg : null,
//           ),
//           onTap: () async {
//             if (field.type == 'time') {
//               final picked = await showTimePicker(
//                 context: context,
//                 initialTime: TimeOfDay.now(),
//               );
//               if (picked != null) {
//                 if (!context.mounted) return;
//                 ref
//                     .read(formValuesProvider.notifier)
//                     .updateValue(field.id, picked.format(context));
//               }
//               return;
//             }
//             final picked = await showDatePicker(
//               context: context,
//               initialDate: DateTime.now(),
//               firstDate: DateTime(1900),
//               lastDate: DateTime(2100),
//             );
//             if (picked != null) {
//               final formatted =
//                   "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
//               ref
//                   .read(formValuesProvider.notifier)
//                   .updateValue(field.id, formatted);
//             }
//           },
//         );

//       case 'number':
//         return TextField(
//           keyboardType: TextInputType.number,
//           onChanged: (val) {
//             ref.read(formValuesProvider.notifier).updateValue(field.id, val);
//           },
//           decoration: InputDecoration(
//             labelText: field.label,
//             hintText: field.placeholder,
//             errorText: hasError ? errorMsg : null,
//           ),
//         );

//       case 'image':
//         return _buildUploadLikeField(
//           field,
//           values,
//           hasError,
//           errorMsg,
//           isImage: true,
//         );

//       case 'table_grid':
//         return _buildTableGridRunner(field);

//       case 'repeater':
//         return _buildRepeaterRunner(field);

//       case 'timeline':
//         return _buildTimelineRunner(field);

//       case 'section':
//         return _buildNestedContainer(field, values, Icons.view_agenda_outlined);

//       case 'card':
//         return _buildNestedContainer(field, values, Icons.crop_square_rounded);

//       case 'tabs':
//         return _buildNestedTabs(field, values);

//       case 'accordion':
//         return _buildNestedContainer(field, values, Icons.unfold_more_rounded);

//       case 'row':
//         return _buildNestedRow(field, values);

//       case 'formula':
//         return FormulaFieldWidget(
//           label: field.label,
//           formula: field.formula!,
//           formValues: values,
//         );

//       case 'phone':
//         return Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Container(
//               height: 52,
//               padding: const EdgeInsets.symmetric(horizontal: 12),
//               decoration: BoxDecoration(
//                 color: const Color(0x12FFFFFF),
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: const Color(0x22A086FA)),
//               ),
//               alignment: Alignment.center,
//               child: Row(
//                 children: [
//                   const Text("🇮🇳", style: TextStyle(fontSize: 18)),
//                   const SizedBox(width: 4),
//                   const Text(
//                     "+91",
//                     style: TextStyle(fontSize: 13, color: Colors.white70),
//                   ),
//                   Icon(
//                     Icons.keyboard_arrow_down_rounded,
//                     size: 14,
//                     color: RevoTheme.textSecondary,
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(width: 8),
//             Expanded(
//               child: TextField(
//                 keyboardType: TextInputType.phone,
//                 onChanged: (val) {
//                   ref
//                       .read(formValuesProvider.notifier)
//                       .updateValue(field.id, val);
//                 },
//                 decoration: InputDecoration(
//                   labelText: field.label,
//                   hintText: field.placeholder ?? 'Enter Phone Number',
//                   errorText: hasError ? errorMsg : null,
//                 ),
//               ),
//             ),
//           ],
//         );

//       case 'file':
//         return _buildUploadLikeField(field, values, hasError, errorMsg);

//       case 'textarea':
//         return TextField(
//           maxLines: 4,
//           onChanged: (val) {
//             ref.read(formValuesProvider.notifier).updateValue(field.id, val);
//           },
//           decoration: InputDecoration(
//             labelText: field.label,
//             hintText: field.placeholder,
//             alignLabelWithHint: true,
//             errorText: hasError ? errorMsg : null,
//           ),
//         );

//       case 'otp':
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               field.label,
//               style: GoogleFonts.inter(
//                 fontSize: 12,
//                 color: RevoTheme.textSecondary,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: List.generate(6, (idx) {
//                 return SizedBox(
//                   width: 40,
//                   child: TextField(
//                     textAlign: TextAlign.center,
//                     keyboardType: TextInputType.number,
//                     maxLength: 1,
//                     decoration: InputDecoration(
//                       counterText: '',
//                       contentPadding: const EdgeInsets.symmetric(vertical: 12),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                         borderSide: BorderSide(color: RevoTheme.cardBorder),
//                       ),
//                     ),
//                     onChanged: (val) {
//                       if (val.isNotEmpty && idx < 5) {
//                         FocusScope.of(context).nextFocus();
//                       }
//                       // Mock values update
//                       ref
//                           .read(formValuesProvider.notifier)
//                           .updateValue(field.id, "123456");
//                     },
//                   ),
//                 );
//               }),
//             ),
//             if (hasError) ...[
//               const SizedBox(height: 6),
//               Text(
//                 errorMsg!,
//                 style: const TextStyle(color: Colors.red, fontSize: 10),
//               ),
//             ],
//           ],
//         );

//       default:
//         return TextField(
//           onChanged: (val) {
//             ref.read(formValuesProvider.notifier).updateValue(field.id, val);
//           },
//           decoration: InputDecoration(
//             labelText: field.label,
//             hintText: field.placeholder,
//             errorText: hasError ? errorMsg : null,
//           ),
//         );
//     }
//   }

//   Widget _buildUploadLikeField(
//     JourneyField field,
//     Map<String, dynamic> values,
//     bool hasError,
//     String? errorMsg, {
//     bool isImage = false,
//   }) {
//     final currentVal = values[field.id]?.toString() ?? '';
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: RevoTheme.cardBg,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: RevoTheme.cardBorder),
//       ),
//       child: Column(
//         children: [
//           Icon(
//             isImage ? Icons.image_outlined : Icons.cloud_upload_outlined,
//             size: 28,
//             color: RevoTheme.primaryLight,
//           ),
//           const SizedBox(height: 8),
//           Text(
//             currentVal.isNotEmpty
//                 ? currentVal
//                 : (isImage
//                       ? "Click to upload image"
//                       : "Drag & Drop or Click to Upload file"),
//             style: GoogleFonts.inter(
//               fontSize: 12,
//               color: RevoTheme.textSecondary,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 12),
//           OutlinedButton(
//             onPressed: () {
//               ref
//                   .read(formValuesProvider.notifier)
//                   .updateValue(
//                     field.id,
//                     isImage ? "image_uploaded.png" : "document_uploaded.pdf",
//                   );
//             },
//             style: OutlinedButton.styleFrom(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               side: BorderSide(color: RevoTheme.primary),
//             ),
//             child: Text(
//               isImage ? "Select Image" : "Select File",
//               style: const TextStyle(fontSize: 11),
//             ),
//           ),
//           if (hasError) ...[
//             const SizedBox(height: 8),
//             Text(
//               errorMsg!,
//               style: const TextStyle(color: Colors.red, fontSize: 10),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Map<String, dynamic> _componentConfig(JourneyField field) {
//     final config = Map<String, dynamic>.from(field.componentConfig ?? {});
//     if (field.type == 'table_grid') {
//       return {
//         'columns': [
//           {
//             'label': '#',
//             'fieldId': 'rowIndex',
//             'type': 'number',
//             'required': false,
//           },
//           {
//             'label': 'Name',
//             'fieldId': 'name',
//             'type': 'text',
//             'required': true,
//           },
//           {
//             'label': 'Age',
//             'fieldId': 'age',
//             'type': 'number',
//             'required': false,
//           },
//         ],
//         'rowActions': ['edit', 'delete'],
//         'allowAddRow': true,
//         'allowDeleteRow': true,
//         'inlineEdit': true,
//         'bulkSelection': true,
//         'exportCsv': true,
//         'search': true,
//         'sorting': true,
//         'filtering': true,
//         'stickyColumns': true,
//         'dataSource': 'manual',
//         'gridApiUrl': '',
//         'gridApiMethod': 'GET',
//         'gridApiHeaders': {},
//         'gridApiBody': '',
//         'gridApiListKey': 'data',
//         'apiPagination': false,
//         'dynamicRowValidation': true,
//         'pagination': true,
//         'rowsPerPage': 10,
//         'minRows': 0,
//         'maxRows': 10,
//         ...config,
//       };
//     }
//     return config;
//   }

//   List<Map<String, dynamic>> _configList(
//     JourneyField field,
//     String key,
//     List<Map<String, dynamic>> fallback,
//   ) {
//     final value = _componentConfig(field)[key];
//     if (value is List) {
//       final parsed = value
//           .map(
//             (item) => item is Map
//                 ? Map<String, dynamic>.from(item)
//                 : <String, dynamic>{},
//           )
//           .where((item) => item.isNotEmpty)
//           .toList();
//       if (parsed.isNotEmpty) return parsed;
//     }
//     return fallback;
//   }

//   Widget _buildTableGridRunner(JourneyField field) {
//     final config = _componentConfig(field);
//     final columns = _configList(field, 'columns', [
//       if (field.nestedFields != null && field.nestedFields!.isNotEmpty)
//         ...field.nestedFields!.map(
//           (nested) => {
//             'label': nested.label,
//             'fieldId': nested.id,
//             'type': nested.type,
//             'required': nested.required,
//           },
//         )
//       else ...[
//         {'label': '#'},
//         {'label': 'Name', 'fieldId': 'name', 'required': true},
//         {'label': 'Age', 'fieldId': 'age'},
//       ],
//     ]);
//     final allowAdd = config['allowAddRow'] != false;
//     final allowDelete = config['allowDeleteRow'] != false;
//     final inlineEdit = config['inlineEdit'] != false;
//     final bulkSelection = config['bulkSelection'] != false;
//     final exportCsv = config['exportCsv'] != false;
//     final searchEnabled = config['search'] != false;
//     final sortingEnabled = config['sorting'] != false;
//     final validationEnabled = config['dynamicRowValidation'] != false;
//     final dataSource = config['dataSource']?.toString() ?? 'manual';
//     final pagination = config['pagination'] != false;
//     final apiPagination = config['apiPagination'] == true;
//     final rowActions = config['rowActions'] is List
//         ? List<String>.from(
//             (config['rowActions'] as List).map((item) => item.toString()),
//           )
//         : <String>['edit', 'delete'];
//     final rowsPerPage =
//         int.tryParse(config['rowsPerPage']?.toString() ?? '') ?? 10;
//     final maxRows = int.tryParse(config['maxRows']?.toString() ?? '') ?? 10;
//     final rows = _ensureGridRows(field, columns, config);
//     if (dataSource == 'api' &&
//         !_gridApiLoaded.contains(field.id) &&
//         !_gridApiLoading.contains(field.id)) {
//       WidgetsBinding.instance.addPostFrameCallback(
//         (_) => _loadGridRowsFromApi(field, columns, config),
//       );
//     }
//     final search = _gridSearch[field.id] ?? '';
//     final sortField = _gridSortField[field.id];
//     final sortAscending = _gridSortAscending[field.id] ?? true;
//     final selected = _gridSelections.putIfAbsent(field.id, () => <int>{});
//     var visibleRows = rows.asMap().entries.where((entry) {
//       if (search.trim().isEmpty) return true;
//       final q = search.toLowerCase();
//       return entry.value.values.any(
//         (value) => value.toString().toLowerCase().contains(q),
//       );
//     }).toList();
//     if (sortField != null && sortField.isNotEmpty) {
//       visibleRows.sort((a, b) {
//         final left = a.value[sortField]?.toString() ?? '';
//         final right = b.value[sortField]?.toString() ?? '';
//         final comparison = left.compareTo(right);
//         return sortAscending ? comparison : -comparison;
//       });
//     }
//     final pagedRows = pagination
//         ? visibleRows.take(rowsPerPage).toList()
//         : visibleRows;
//     final sortColumnIndex = sortField == null
//         ? -1
//         : columns.indexWhere((c) => _columnFieldId(c) == sortField);

//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: RevoTheme.cardBg,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: RevoTheme.cardBorder),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Expanded(
//                 child: Text(
//                   field.label,
//                   style: GoogleFonts.inter(
//                     fontSize: 13,
//                     fontWeight: FontWeight.w700,
//                     color: RevoTheme.textPrimary,
//                   ),
//                 ),
//               ),
//               if (dataSource == 'api')
//                 IconButton(
//                   tooltip: "Reload API data",
//                   onPressed: _gridApiLoading.contains(field.id)
//                       ? null
//                       : () => _loadGridRowsFromApi(
//                           field,
//                           columns,
//                           config,
//                           force: true,
//                         ),
//                   icon: _gridApiLoading.contains(field.id)
//                       ? SizedBox(
//                           width: 16,
//                           height: 16,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             color: RevoTheme.primaryLight,
//                           ),
//                         )
//                       : Icon(
//                           Icons.refresh_rounded,
//                           size: 18,
//                           color: RevoTheme.textSecondary,
//                         ),
//                 ),
//               if (exportCsv)
//                 IconButton(
//                   tooltip: "Export CSV",
//                   onPressed: () => _exportGridCsv(field, columns, rows),
//                   icon: Icon(
//                     Icons.download_rounded,
//                     size: 18,
//                     color: RevoTheme.textSecondary,
//                   ),
//                 ),
//               if (allowAdd)
//                 OutlinedButton.icon(
//                   onPressed: rows.length >= maxRows
//                       ? null
//                       : () => _addGridRow(field, columns),
//                   icon: const Icon(Icons.add_rounded, size: 14),
//                   label: const Text("Add Row", style: TextStyle(fontSize: 11)),
//                 ),
//             ],
//           ),
//           if (_gridApiErrors[field.id] != null) ...[
//             const SizedBox(height: 8),
//             Text(
//               _gridApiErrors[field.id]!,
//               style: GoogleFonts.inter(fontSize: 10, color: Colors.redAccent),
//             ),
//           ],
//           if (searchEnabled) ...[
//             const SizedBox(height: 10),
//             TextField(
//               decoration: InputDecoration(
//                 prefixIcon: Icon(
//                   Icons.search_rounded,
//                   size: 16,
//                   color: RevoTheme.textSecondary,
//                 ),
//                 hintText: "Search rows",
//                 hintStyle: GoogleFonts.inter(
//                   fontSize: 11,
//                   color: RevoTheme.textSecondary,
//                 ),
//                 contentPadding: const EdgeInsets.symmetric(
//                   horizontal: 10,
//                   vertical: 8,
//                 ),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               style: GoogleFonts.inter(
//                 fontSize: 11,
//                 color: RevoTheme.textPrimary,
//               ),
//               onChanged: (value) =>
//                   setState(() => _gridSearch[field.id] = value),
//             ),
//           ],
//           const SizedBox(height: 10),
//           SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: DataTable(
//               showCheckboxColumn: bulkSelection,
//               headingRowColor: WidgetStatePropertyAll(RevoTheme.background),
//               dataRowMinHeight: 48,
//               dataRowMaxHeight: 64,
//               sortColumnIndex: sortColumnIndex < 0 ? null : sortColumnIndex,
//               sortAscending: sortAscending,
//               columns: [
//                 ...columns.map((column) {
//                   final fieldId = _columnFieldId(column);
//                   return DataColumn(
//                     label: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Text(column['label']?.toString() ?? 'Column'),
//                         if (column['sticky'] == true ||
//                             config['stickyColumns'] == true &&
//                                 columns.indexOf(column) == 0)
//                           Padding(
//                             padding: const EdgeInsets.only(left: 4),
//                             child: Icon(
//                               Icons.push_pin_rounded,
//                               size: 12,
//                               color: RevoTheme.primaryLight,
//                             ),
//                           ),
//                       ],
//                     ),
//                     onSort: sortingEnabled
//                         ? (_, ascending) {
//                             setState(() {
//                               _gridSortField[field.id] = fieldId;
//                               _gridSortAscending[field.id] = ascending;
//                             });
//                           }
//                         : null,
//                   );
//                 }),
//                 DataColumn(
//                   label: Text(
//                     "Action",
//                     style: GoogleFonts.inter(fontWeight: FontWeight.w700),
//                   ),
//                 ),
//               ],
//               rows: pagedRows.map((entry) {
//                 final rowIndex = entry.key;
//                 final row = entry.value;
//                 return DataRow(
//                   selected: selected.contains(rowIndex),
//                   onSelectChanged: bulkSelection
//                       ? (checked) {
//                           setState(() {
//                             checked == true
//                                 ? selected.add(rowIndex)
//                                 : selected.remove(rowIndex);
//                           });
//                         }
//                       : null,
//                   cells: [
//                     ...columns.map(
//                       (column) => DataCell(
//                         _gridCell(
//                           field,
//                           column,
//                           row,
//                           rowIndex,
//                           inlineEdit,
//                           validationEnabled,
//                         ),
//                       ),
//                     ),
//                     DataCell(
//                       _gridActions(
//                         field,
//                         columns,
//                         rowIndex,
//                         row,
//                         rowActions,
//                         allowDelete,
//                       ),
//                     ),
//                   ],
//                 );
//               }).toList(),
//             ),
//           ),
//           if (bulkSelection && selected.isNotEmpty) ...[
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 Expanded(
//                   child: Text(
//                     "${selected.length} selected",
//                     style: GoogleFonts.inter(
//                       fontSize: 11,
//                       color: RevoTheme.textSecondary,
//                     ),
//                   ),
//                 ),
//                 if (allowDelete)
//                   TextButton.icon(
//                     onPressed: () => _deleteSelectedGridRows(field),
//                     icon: const Icon(Icons.delete_outline_rounded, size: 14),
//                     label: const Text("Delete Selected"),
//                   ),
//               ],
//             ),
//           ],
//           if (pagination || apiPagination) ...[
//             const SizedBox(height: 8),
//             Text(
//               "${pagedRows.length} of ${visibleRows.length} row(s) shown${apiPagination ? " | API page params enabled" : ""}",
//               style: GoogleFonts.inter(
//                 fontSize: 10,
//                 color: RevoTheme.textSecondary,
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _gridActions(
//     JourneyField field,
//     List<Map<String, dynamic>> columns,
//     int rowIndex,
//     Map<String, dynamic> row,
//     List<String> actions,
//     bool allowDelete,
//   ) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: actions.map((action) {
//         switch (action.toLowerCase()) {
//           case 'delete':
//             if (!allowDelete) return const SizedBox.shrink();
//             return IconButton(
//               tooltip: "Delete row",
//               onPressed: () => _deleteGridRow(field, rowIndex),
//               icon: const Icon(
//                 Icons.delete_outline_rounded,
//                 size: 18,
//                 color: Colors.redAccent,
//               ),
//             );
//           case 'duplicate':
//             return IconButton(
//               tooltip: "Duplicate row",
//               onPressed: () => _duplicateGridRow(field, columns, row),
//               icon: Icon(
//                 Icons.copy_rounded,
//                 size: 16,
//                 color: RevoTheme.textSecondary,
//               ),
//             );
//           case 'view':
//             return Icon(
//               Icons.visibility_outlined,
//               size: 16,
//               color: RevoTheme.textSecondary,
//             );
//           case 'edit':
//             return Icon(
//               Icons.edit_outlined,
//               size: 16,
//               color: RevoTheme.primaryLight,
//             );
//           default:
//             return const SizedBox.shrink();
//         }
//       }).toList(),
//     );
//   }

//   List<Map<String, dynamic>> _ensureGridRows(
//     JourneyField field,
//     List<Map<String, dynamic>> columns,
//     Map<String, dynamic> config,
//   ) {
//     return _gridRows.putIfAbsent(field.id, () {
//       final minRows = int.tryParse(config['minRows']?.toString() ?? '') ?? 0;
//       if ((config['dataSource']?.toString() ?? 'manual') == 'api') {
//         return <Map<String, dynamic>>[];
//       }
//       final initialCount = minRows > 0 ? minRows : 1;
//       return List.generate(initialCount, (_) => _emptyGridRow(columns));
//     });
//   }

//   Future<void> _loadGridRowsFromApi(
//     JourneyField field,
//     List<Map<String, dynamic>> columns,
//     Map<String, dynamic> config, {
//     bool force = false,
//   }) async {
//     if (!force && _gridApiLoading.contains(field.id)) return;
//     final urlText = config['gridApiUrl']?.toString().trim() ?? '';
//     if (urlText.isEmpty) {
//       setState(() {
//         _gridApiLoaded.add(field.id);
//         _gridApiErrors[field.id] = 'Grid API URL is required.';
//       });
//       return;
//     }

//     setState(() {
//       _gridApiLoading.add(field.id);
//       _gridApiErrors.remove(field.id);
//     });

//     try {
//       final uri = _gridApiUri(urlText, config);
//       final method = (config['gridApiMethod']?.toString() ?? 'GET')
//           .toUpperCase();
//       final headers = _gridApiHeaders(config['gridApiHeaders']);
//       final bodyText = config['gridApiBody']?.toString().trim() ?? '';
//       final body = bodyText.isEmpty ? null : bodyText;
//       http.Response response;

//       if (method == 'POST') {
//         response = await http.post(uri, headers: headers, body: body);
//       } else if (method == 'PUT') {
//         response = await http.put(uri, headers: headers, body: body);
//       } else if (method == 'DELETE') {
//         response = await http.delete(uri, headers: headers, body: body);
//       } else {
//         response = await http.get(uri, headers: headers);
//       }

//       if (response.statusCode < 200 || response.statusCode >= 300) {
//         throw Exception('Grid API failed with status ${response.statusCode}');
//       }

//       final decoded = json.decode(response.body);
//       final listKey = config['gridApiListKey']?.toString() ?? '';
//       final rows = _normalizeGridApiRows(decoded, listKey, columns);

//       setState(() {
//         _gridRows[field.id] = rows;
//         _gridSelections[field.id]?.clear();
//         _gridApiLoaded.add(field.id);
//         _gridApiLoading.remove(field.id);
//       });
//       _syncGridValue(field);
//     } catch (e) {
//       setState(() {
//         _gridApiLoaded.add(field.id);
//         _gridApiLoading.remove(field.id);
//         _gridApiErrors[field.id] = e.toString();
//       });
//     }
//   }

//   Uri _gridApiUri(String urlText, Map<String, dynamic> config) {
//     final uri = Uri.parse(urlText);
//     if (config['apiPagination'] != true) return uri;
//     final pageParam = config['apiPageParam']?.toString() ?? 'page';
//     final sizeParam = config['apiPageSizeParam']?.toString() ?? 'limit';
//     final rowsPerPage = config['rowsPerPage']?.toString() ?? '10';
//     return uri.replace(
//       queryParameters: {
//         ...uri.queryParameters,
//         if (pageParam.isNotEmpty) pageParam: '1',
//         if (sizeParam.isNotEmpty) sizeParam: rowsPerPage,
//       },
//     );
//   }

//   Map<String, String> _gridApiHeaders(dynamic rawHeaders) {
//     final headers = <String, String>{};
//     if (rawHeaders is Map) {
//       rawHeaders.forEach(
//         (key, value) => headers[key.toString()] = value.toString(),
//       );
//     } else if (rawHeaders is String && rawHeaders.trim().isNotEmpty) {
//       final decoded = json.decode(rawHeaders);
//       if (decoded is Map) {
//         decoded.forEach(
//           (key, value) => headers[key.toString()] = value.toString(),
//         );
//       }
//     }
//     return headers;
//   }

//   List<Map<String, dynamic>> _normalizeGridApiRows(
//     dynamic decoded,
//     String listKey,
//     List<Map<String, dynamic>> columns,
//   ) {
//     dynamic source = decoded;
//     if (decoded is Map && listKey.trim().isNotEmpty) {
//       source = _readJsonPath(decoded, listKey) ?? decoded[listKey];
//     }
//     if (source is! List && decoded is Map) {
//       for (final key in ['data', 'items', 'results', 'rows']) {
//         if (decoded[key] is List) {
//           source = decoded[key];
//           break;
//         }
//       }
//     }
//     if (source is! List) return <Map<String, dynamic>>[];
//     return source.map<Map<String, dynamic>>((item) {
//       if (item is Map) return Map<String, dynamic>.from(item);
//       final row = _emptyGridRow(columns);
//       if (columns.isNotEmpty)
//         row[_columnFieldId(columns.first)] = item.toString();
//       return row;
//     }).toList();
//   }

//   dynamic _readJsonPath(dynamic source, String path) {
//     if (path.trim().isEmpty) return null;
//     dynamic cursor = source;
//     for (final part in path.split('.')) {
//       if (cursor is Map) {
//         cursor = cursor[part];
//       } else {
//         return null;
//       }
//     }
//     return cursor;
//   }

//   Map<String, dynamic> _emptyGridRow(List<Map<String, dynamic>> columns) {
//     return {for (final column in columns) _columnFieldId(column): ''};
//   }

//   String _columnFieldId(Map<String, dynamic> column) {
//     return (column['fieldId'] ?? column['key'] ?? column['label'] ?? 'column')
//         .toString();
//   }

//   Widget _gridCell(
//     JourneyField field,
//     Map<String, dynamic> column,
//     Map<String, dynamic> row,
//     int rowIndex,
//     bool inlineEdit,
//     bool validationEnabled,
//   ) {
//     final fieldId = _columnFieldId(column);
//     final value = row[fieldId]?.toString() ?? '';
//     final required = column['required'] == true;
//     final hasError = validationEnabled && required && value.trim().isEmpty;
//     if (!inlineEdit) {
//       return Text(
//         value.isEmpty ? '-' : value,
//         style: GoogleFonts.inter(
//           fontSize: 11,
//           color: hasError ? Colors.redAccent : RevoTheme.textSecondary,
//         ),
//       );
//     }
//     return SizedBox(
//       width: 140,
//       child: TextFormField(
//         initialValue: value,
//         decoration: InputDecoration(
//           isDense: true,
//           hintText: column['label']?.toString(),
//           errorText: hasError ? "Required" : null,
//           contentPadding: const EdgeInsets.symmetric(
//             horizontal: 8,
//             vertical: 8,
//           ),
//           border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
//         ),
//         keyboardType: column['type'] == 'number'
//             ? TextInputType.number
//             : TextInputType.text,
//         style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textPrimary),
//         onChanged: (value) => _updateGridCell(field, rowIndex, fieldId, value),
//       ),
//     );
//   }

//   void _addGridRow(JourneyField field, List<Map<String, dynamic>> columns) {
//     setState(() {
//       final rows = _gridRows.putIfAbsent(field.id, () => []);
//       rows.add(_emptyGridRow(columns));
//       _syncGridValue(field);
//     });
//   }

//   void _deleteGridRow(JourneyField field, int rowIndex) {
//     setState(() {
//       final rows = _gridRows[field.id];
//       if (rows == null || rowIndex < 0 || rowIndex >= rows.length) return;
//       rows.removeAt(rowIndex);
//       _gridSelections[field.id]?.remove(rowIndex);
//       _syncGridValue(field);
//     });
//   }

//   void _duplicateGridRow(
//     JourneyField field,
//     List<Map<String, dynamic>> columns,
//     Map<String, dynamic> row,
//   ) {
//     setState(() {
//       final rows = _gridRows.putIfAbsent(field.id, () => []);
//       rows.add({..._emptyGridRow(columns), ...row});
//       _syncGridValue(field);
//     });
//   }

//   void _deleteSelectedGridRows(JourneyField field) {
//     setState(() {
//       final rows = _gridRows[field.id];
//       final selected = _gridSelections[field.id];
//       if (rows == null || selected == null) return;
//       final sorted = selected.toList()..sort((a, b) => b.compareTo(a));
//       for (final index in sorted) {
//         if (index >= 0 && index < rows.length) rows.removeAt(index);
//       }
//       selected.clear();
//       _syncGridValue(field);
//     });
//   }

//   void _updateGridCell(
//     JourneyField field,
//     int rowIndex,
//     String fieldId,
//     String value,
//   ) {
//     setState(() {
//       final rows = _gridRows[field.id];
//       if (rows == null || rowIndex < 0 || rowIndex >= rows.length) return;
//       rows[rowIndex][fieldId] = value;
//       _syncGridValue(field);
//     });
//   }

//   void _syncGridValue(JourneyField field) {
//     ref
//         .read(formValuesProvider.notifier)
//         .updateValue(field.id, jsonEncode(_gridRows[field.id] ?? []));
//   }

//   void _exportGridCsv(
//     JourneyField field,
//     List<Map<String, dynamic>> columns,
//     List<Map<String, dynamic>> rows,
//   ) {
//     final headers = columns
//         .map((column) => column['label']?.toString() ?? _columnFieldId(column))
//         .toList();
//     final keys = columns.map(_columnFieldId).toList();
//     final csv = [
//       headers.map(_escapeCsv).join(','),
//       ...rows.map(
//         (row) =>
//             keys.map((key) => _escapeCsv(row[key]?.toString() ?? '')).join(','),
//       ),
//     ].join('\n');
//     Clipboard.setData(ClipboardData(text: csv));
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(const SnackBar(content: Text("CSV copied to clipboard")));
//   }

//   String _escapeCsv(String value) {
//     final escaped = value.replaceAll('"', '""');
//     return value.contains(',') || value.contains('"') || value.contains('\n')
//         ? '"$escaped"'
//         : escaped;
//   }

//   Widget _buildRepeaterRunner(JourneyField field) {
//     final config = _componentConfig(field);
//     final nestedFields = field.nestedFields ?? const <JourneyField>[];
//     final allowAdd = config['allowAdd'] != false;
//     final allowRemove = config['allowRemove'] != false;
//     final itemLabel = config['itemLabel']?.toString() ?? 'Item';
//     final addLabel = config['addButtonLabel']?.toString() ?? 'Add $itemLabel';
//     final maxRows = int.tryParse(config['maxRows']?.toString() ?? '') ?? 20;

//     // Initialise rows with one empty entry if none yet
//     final rows = _repeaterRows.putIfAbsent(
//       field.id,
//       () => [_emptyRepeaterRow(nestedFields)],
//     );

//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: RevoTheme.cardBg,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: RevoTheme.cardBorder),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             field.label,
//             style: GoogleFonts.inter(
//               fontSize: 13,
//               fontWeight: FontWeight.w700,
//               color: RevoTheme.textPrimary,
//             ),
//           ),
//           const SizedBox(height: 10),
//           ...rows.asMap().entries.map((entry) {
//             final rowIndex = entry.key;
//             final rowValues = entry.value;
//             return Container(
//               margin: const EdgeInsets.only(bottom: 10),
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: RevoTheme.background,
//                 borderRadius: BorderRadius.circular(10),
//                 border: Border.all(color: RevoTheme.cardBorder),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Expanded(
//                         child: Text(
//                           '$itemLabel ${rowIndex + 1}',
//                           style: GoogleFonts.inter(
//                             fontSize: 12,
//                             fontWeight: FontWeight.w700,
//                             color: RevoTheme.textPrimary,
//                           ),
//                         ),
//                       ),
//                       if (allowRemove && rows.length > 1)
//                         IconButton(
//                           icon: const Icon(
//                             Icons.delete_outline_rounded,
//                             size: 16,
//                             color: Colors.redAccent,
//                           ),
//                           onPressed: () => setState(() {
//                             _repeaterRows[field.id]!.removeAt(rowIndex);
//                             _syncRepeaterValue(field);
//                           }),
//                           padding: const EdgeInsets.all(4),
//                           constraints: const BoxConstraints(),
//                         ),
//                     ],
//                   ),
//                   const SizedBox(height: 10),
//                   // Render each nestedField with its own isolated row-scoped value map
//                   if (nestedFields.isNotEmpty)
//                     ...nestedFields.map(
//                       (nestedField) => Padding(
//                         padding: const EdgeInsets.only(bottom: 10),
//                         child: _buildRepeaterCell(
//                           field,
//                           rowIndex,
//                           nestedField,
//                           rowValues,
//                         ),
//                       ),
//                     )
//                   else
//                     Text(
//                       'No fields configured inside this repeater.',
//                       style: GoogleFonts.inter(
//                         fontSize: 11,
//                         color: RevoTheme.textSecondary,
//                       ),
//                     ),
//                 ],
//               ),
//             );
//           }),
//           if (allowAdd && rows.length < maxRows)
//             OutlinedButton.icon(
//               onPressed: () => setState(() {
//                 _repeaterRows[field.id]!.add(_emptyRepeaterRow(nestedFields));
//                 _syncRepeaterValue(field);
//               }),
//               icon: const Icon(Icons.add_rounded, size: 14),
//               label: Text(addLabel, style: const TextStyle(fontSize: 11)),
//             ),
//         ],
//       ),
//     );
//   }

//   Map<String, dynamic> _emptyRepeaterRow(List<JourneyField> fields) {
//     final row = <String, dynamic>{};
//     for (final f in fields) {
//       row[f.id] = f.defaultValue ?? '';
//     }
//     return row;
//   }

//   void _syncRepeaterValue(JourneyField field) {
//     ref
//         .read(formValuesProvider.notifier)
//         .updateValue(
//           field.id,
//           List<Map<String, dynamic>>.from(_repeaterRows[field.id] ?? []),
//         );
//   }

//   Widget _buildRepeaterCell(
//     JourneyField repeaterField,
//     int rowIndex,
//     JourneyField cellField,
//     Map<String, dynamic> rowValues,
//   ) {
//     final currentVal = rowValues[cellField.id]?.toString() ?? '';
//     void updateCell(dynamic val) {
//       setState(() {
//         _repeaterRows[repeaterField.id]![rowIndex][cellField.id] = val;
//         _syncRepeaterValue(repeaterField);
//       });
//     }

//     switch (cellField.type.toLowerCase()) {
//       case 'dropdown':
//         final opts = cellField.getResolvedOptions();
//         return DropdownButtonFormField<String>(
//           initialValue: opts.contains(currentVal) ? currentVal : null,
//           decoration: InputDecoration(
//             labelText: cellField.label,
//             isDense: true,
//           ),
//           dropdownColor: RevoTheme.cardBg,
//           items: opts
//               .map((o) => DropdownMenuItem(value: o, child: Text(o)))
//               .toList(),
//           onChanged: (v) {
//             if (v != null) updateCell(v);
//           },
//         );
//       case 'checkbox':
//       case 'switch':
//         final checked = currentVal == 'true';
//         return CheckboxListTile(
//           title: Text(cellField.label, style: GoogleFonts.inter(fontSize: 12)),
//           value: checked,
//           activeColor: RevoTheme.primary,
//           contentPadding: EdgeInsets.zero,
//           onChanged: (v) => updateCell((v ?? false).toString()),
//         );
//       default:
//         return TextFormField(
//           initialValue: currentVal,
//           decoration: InputDecoration(
//             labelText: cellField.label,
//             isDense: true,
//           ),
//           keyboardType: cellField.type == 'number'
//               ? TextInputType.number
//               : TextInputType.text,
//           onChanged: updateCell,
//         );
//     }
//   }

//   Widget _buildTimelineRunner(JourneyField field) {
//     final items = _configList(field, 'items', [
//       {
//         'title': 'Started',
//         'description': 'Journey started',
//         'status': 'completed',
//       },
//       {'title': 'Current', 'description': 'Current step', 'status': 'active'},
//       {'title': 'Completed', 'description': 'Final state', 'status': 'pending'},
//     ]);

//     Color statusColor(String? status) {
//       switch (status) {
//         case 'completed':
//           return RevoTheme.secondary;
//         case 'active':
//           return RevoTheme.primaryLight;
//         case 'failed':
//           return Colors.redAccent;
//         default:
//           return RevoTheme.textSecondary;
//       }
//     }

//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: RevoTheme.cardBg,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: RevoTheme.cardBorder),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             field.label,
//             style: GoogleFonts.inter(
//               fontSize: 13,
//               fontWeight: FontWeight.w700,
//               color: RevoTheme.textPrimary,
//             ),
//           ),
//           const SizedBox(height: 12),
//           ...items.asMap().entries.map((entry) {
//             final index = entry.key;
//             final item = entry.value;
//             final color = statusColor(item['status']?.toString());
//             return Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Column(
//                   children: [
//                     Container(
//                       width: 14,
//                       height: 14,
//                       decoration: BoxDecoration(
//                         color: color,
//                         shape: BoxShape.circle,
//                       ),
//                     ),
//                     if (index < items.length - 1)
//                       Container(
//                         width: 2,
//                         height: 38,
//                         color: RevoTheme.cardBorder,
//                       ),
//                   ],
//                 ),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Padding(
//                     padding: const EdgeInsets.only(bottom: 14),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           item['title']?.toString() ?? 'Timeline item',
//                           style: GoogleFonts.inter(
//                             fontSize: 12,
//                             fontWeight: FontWeight.w700,
//                             color: RevoTheme.textPrimary,
//                           ),
//                         ),
//                         const SizedBox(height: 3),
//                         Text(
//                           item['description']?.toString() ?? '',
//                           style: GoogleFonts.inter(
//                             fontSize: 11,
//                             color: RevoTheme.textSecondary,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             );
//           }),
//         ],
//       ),
//     );
//   }

//   Widget _buildStructuredComponent(
//     JourneyField field,
//     IconData icon,
//     String fallbackLabel,
//   ) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: RevoTheme.cardBg,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: RevoTheme.cardBorder),
//       ),
//       child: Row(
//         children: [
//           Icon(icon, size: 22, color: RevoTheme.primaryLight),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   field.label.isNotEmpty ? field.label : fallbackLabel,
//                   style: GoogleFonts.inter(
//                     fontSize: 13,
//                     fontWeight: FontWeight.w700,
//                     color: RevoTheme.textPrimary,
//                   ),
//                 ),
//                 if ((field.placeholder ?? field.hintText ?? '').isNotEmpty) ...[
//                   const SizedBox(height: 4),
//                   Text(
//                     field.placeholder ?? field.hintText!,
//                     style: GoogleFonts.inter(
//                       fontSize: 11,
//                       color: RevoTheme.textSecondary,
//                     ),
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ],
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   List<Widget> _buildRunnerFields(
//     List<JourneyField> fields,
//     Map<String, dynamic> values,
//   ) {
//     return fields.map((field) {
//       final isVisible = EngineHelper.isFieldVisible(field, values);
//       if (!isVisible) return const SizedBox.shrink();
//       return Padding(
//         padding: const EdgeInsets.only(bottom: 20.0),
//         child: _buildRunnerField(field, values),
//       );
//     }).toList();
//   }

//   Widget _buildNestedContainer(
//     JourneyField field,
//     Map<String, dynamic> values,
//     IconData icon,
//   ) {
//     final children = field.nestedFields ?? const <JourneyField>[];
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: RevoTheme.cardBg,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: RevoTheme.cardBorder),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(icon, size: 18, color: RevoTheme.primaryLight),
//               const SizedBox(width: 10),
//               Expanded(
//                 child: Text(
//                   field.label,
//                   style: GoogleFonts.inter(
//                     fontSize: 13,
//                     fontWeight: FontWeight.w700,
//                     color: RevoTheme.textPrimary,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           if (children.isNotEmpty) ...[
//             const SizedBox(height: 14),
//             ..._buildRunnerFields(children, values),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildNestedRow(JourneyField field, Map<String, dynamic> values) {
//     final children = (field.nestedFields ?? const <JourneyField>[])
//         .where((child) => EngineHelper.isFieldVisible(child, values))
//         .toList();
//     return Wrap(
//       spacing: 12,
//       runSpacing: 12,
//       children: children.map((child) {
//         final colSpan =
//             int.tryParse(child.componentConfig?['colSpan']?.toString() ?? '') ??
//             12;
//         final width = MediaQuery.of(context).size.width;
//         final itemWidth = width > 760
//             ? ((width - 220) * (colSpan.clamp(1, 12) / 12))
//             : double.infinity;
//         return SizedBox(
//           width: itemWidth,
//           child: _buildRunnerField(child, values),
//         );
//       }).toList(),
//     );
//   }

//   Widget _buildNestedTabs(JourneyField field, Map<String, dynamic> values) {
//     final tabs = field.nestedFields ?? const <JourneyField>[];
//     if (tabs.isEmpty)
//       return _buildStructuredComponent(field, Icons.tab_rounded, 'Tabs');
//     return DefaultTabController(
//       length: tabs.length,
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: RevoTheme.cardBg,
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: RevoTheme.cardBorder),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               field.label,
//               style: GoogleFonts.inter(
//                 fontSize: 13,
//                 fontWeight: FontWeight.w700,
//                 color: RevoTheme.textPrimary,
//               ),
//             ),
//             const SizedBox(height: 10),
//             TabBar(
//               isScrollable: true,
//               labelColor: RevoTheme.primaryLight,
//               unselectedLabelColor: RevoTheme.textSecondary,
//               tabs: tabs.map((tab) => Tab(text: tab.label)).toList(),
//             ),
//             SizedBox(
//               height: 320,
//               child: TabBarView(
//                 children: tabs.map((tab) {
//                   return SingleChildScrollView(
//                     padding: const EdgeInsets.only(top: 14),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: _buildRunnerFields(
//                         tab.nestedFields ?? const <JourneyField>[],
//                         values,
//                       ),
//                     ),
//                   );
//                 }).toList(),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   String _evaluateSimpleFormula(
//     JourneyField field,
//     Map<String, dynamic> values,
//   ) {
//     final formula = field.formula;
//     if (formula == null || formula.trim().isEmpty)
//       return field.defaultValue ?? '';
//     final multiply = RegExp(
//       r'^\s*([A-Za-z0-9_]+)\s*\*\s*([0-9.]+)\s*$',
//     ).firstMatch(formula);
//     if (multiply != null) {
//       final left =
//           double.tryParse(values[multiply.group(1)]?.toString() ?? '') ?? 0;
//       final right = double.tryParse(multiply.group(2) ?? '') ?? 0;
//       return (left * right).toStringAsFixed(2);
//     }
//     return formula;
//   }
// }

// class ApiDropdownWidget extends ConsumerStatefulWidget {
//   final JourneyField field;
//   final String? initialValue;
//   final ValueChanged<String> onChanged;
//   final String? errorText;

//   const ApiDropdownWidget({
//     super.key,
//     required this.field,
//     required this.initialValue,
//     required this.onChanged,
//     this.errorText,
//   });

//   @override
//   ConsumerState<ApiDropdownWidget> createState() => _ApiDropdownWidgetState();
// }

// class _ApiDropdownWidgetState extends ConsumerState<ApiDropdownWidget> {
//   List<String> _options = [];
//   bool _isLoading = false;
//   String? _error;

//   @override
//   void initState() {
//     super.initState();
//     _fetchOptions();
//   }

//   @override
//   void didUpdateWidget(ApiDropdownWidget oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (oldWidget.field.dropdownApiUrl != widget.field.dropdownApiUrl) {
//       _fetchOptions();
//     }
//   }

//   Future<void> _fetchOptions() async {
//     final urlStr = widget.field.dropdownApiUrl;
//     if (urlStr == null || urlStr.trim().isEmpty) {
//       setState(() {
//         _options = widget.field.options ?? ["Select"];
//         _isLoading = false;
//         _error = "No API URL configured";
//       });
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//       _error = null;
//     });

//     try {
//       final uri = Uri.parse(urlStr.trim());
//       final response = await http.get(uri).timeout(const Duration(seconds: 10));

//       if (response.statusCode == 200) {
//         final decoded = json.decode(response.body);
//         final List<String> parsedOptions = [];

//         void extractList(dynamic data) {
//           if (data is List) {
//             final displayKey = widget.field.dropdownValue ?? 'title';
//             for (var item in data) {
//               if (item is String) {
//                 parsedOptions.add(item);
//               } else if (item is num || item is bool) {
//                 parsedOptions.add(item.toString());
//               } else if (item is Map) {
//                 if (item.containsKey(displayKey) && item[displayKey] != null) {
//                   parsedOptions.add(item[displayKey].toString());
//                 } else {
//                   final keysToTry = [
//                     'name',
//                     'title',
//                     'value',
//                     'label',
//                     'text',
//                     'username',
//                     'display_name',
//                   ];
//                   String? foundVal;
//                   for (var key in keysToTry) {
//                     if (item.containsKey(key) && item[key] != null) {
//                       foundVal = item[key].toString();
//                       break;
//                     }
//                   }
//                   if (foundVal == null && item.isNotEmpty) {
//                     foundVal = item.values.first.toString();
//                   }
//                   if (foundVal != null) {
//                     parsedOptions.add(foundVal);
//                   }
//                 }
//               }
//             }
//           }
//         }

//         final responseKey = widget.field.dropdownApiResponseKey;
//         if (decoded is List) {
//           extractList(decoded);
//         } else if (decoded is Map) {
//           bool foundList = false;
//           if (responseKey != null && responseKey.isNotEmpty) {
//             if (decoded[responseKey] is List) {
//               extractList(decoded[responseKey]);
//               foundList = true;
//             }
//           }
//           if (!foundList) {
//             final keysToTry = ['data', 'results', 'items', 'users', 'options'];
//             for (var key in keysToTry) {
//               if (decoded[key] is List) {
//                 extractList(decoded[key]);
//                 foundList = true;
//                 break;
//               }
//             }
//           }
//           if (!foundList) {
//             for (var val in decoded.values) {
//               if (val is List) {
//                 extractList(val);
//                 foundList = true;
//                 break;
//               }
//             }
//           }
//           if (!foundList) {
//             _error = "Could not find list in response";
//           }
//         } else {
//           _error = "Invalid JSON response format";
//         }

//         if (parsedOptions.isEmpty && _error == null) {
//           _error = "No options found in response";
//         }

//         setState(() {
//           _options = parsedOptions.isNotEmpty ? parsedOptions : ["Select"];
//           _isLoading = false;
//         });
//       } else {
//         setState(() {
//           _error = "HTTP error: ${response.statusCode}";
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _error = "Connection failed";
//         _isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final hasError = _error != null || widget.errorText != null;
//     final displayError = _error ?? widget.errorText;

//     return DropdownButtonFormField<String>(
//       initialValue: _options.contains(widget.initialValue)
//           ? widget.initialValue
//           : null,
//       decoration: InputDecoration(
//         labelText: widget.field.label,
//         hintText: widget.field.placeholder ?? "Select option",
//         errorText: hasError ? displayError : null,
//         suffixIcon: _isLoading
//             ? Padding(
//                 padding: const EdgeInsets.all(14.0),
//                 child: SizedBox(
//                   width: 16,
//                   height: 16,
//                   child: CircularProgressIndicator(
//                     strokeWidth: 2,
//                     valueColor: AlwaysStoppedAnimation<Color>(
//                       RevoTheme.primaryLight,
//                     ),
//                   ),
//                 ),
//               )
//             : _error != null
//             ? IconButton(
//                 icon: const Icon(
//                   Icons.refresh_rounded,
//                   color: Colors.amberAccent,
//                   size: 20,
//                 ),
//                 tooltip: "Retry fetching options",
//                 onPressed: _fetchOptions,
//                 constraints: const BoxConstraints(),
//                 padding: EdgeInsets.zero,
//               )
//             : null,
//       ),
//       dropdownColor: RevoTheme.cardBg,
//       items: _options.map((opt) {
//         return DropdownMenuItem(value: opt, child: Text(opt));
//       }).toList(),
//       onChanged: _isLoading
//           ? null
//           : (val) {
//               if (val != null) {
//                 widget.onChanged(val);
//               }
//             },
//     );
//   }
// }
