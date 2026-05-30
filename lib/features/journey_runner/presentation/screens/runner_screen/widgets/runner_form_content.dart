import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:revojourneytryone/features/journey_builder/domain/entities/journey_models.dart';
import 'package:revojourneytryone/features/journey_builder/application/controllers/journey_controller.dart';
import 'package:revojourneytryone/features/journey_builder/application/controllers/journey_validation_manager.dart';
import 'package:revojourneytryone/features/journey_runner/presentation/screens/fields/field_plugins.dart';
import 'package:revojourneytryone/features/journey_runner/presentation/screens/runner_screen/runner_theme.dart';
import 'package:revojourneytryone/features/journey_runner/domain/journey_execution_models.dart';
import 'package:revojourneytryone/features/journey_runner/presentation/screens/runner_screen/widgets/fields/api_dropdown_widget.dart';
import 'package:revojourneytryone/features/journey_runner/presentation/screens/runner_screen/widgets/fields/runner_grid_widget.dart';
import 'package:revojourneytryone/features/journey_runner/presentation/screens/runner_screen/widgets/fields/runner_repeater_widget.dart';
import 'package:revojourneytryone/features/journey_runner/presentation/screens/runner_screen/widgets/fields/runner_timeline_widget.dart';
import 'package:revojourneytryone/features/journey_runner/presentation/screens/runner_screen/widgets/fields/runner_nested_widget.dart';

class RunnerFormContent extends ConsumerWidget {
  final JourneyConfig cfg;
  final JourneyStep activeStep;
  final int activeIdx;
  final Map<String, dynamic> formValues;
  final Map<String, String> errors;
  final bool showSubmit;
  final bool isMobile;
  final bool isExecuting;
  final List<String> stepHistory;
  final GlobalKey<FormState> formKey;
  final Function(JourneyAction, JourneyStep, JourneyConfig) runAction;
  final Function(StringMsg, {bool isError}) showSnack;

  const RunnerFormContent({
    super.key,
    required this.cfg,
    required this.activeStep,
    required this.activeIdx,
    required this.formValues,
    required this.errors,
    required this.showSubmit,
    required this.isMobile,
    required this.isExecuting,
    required this.stepHistory,
    required this.formKey,
    required this.runAction,
    required this.showSnack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Form(
      key: formKey,
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
                color: RunnerTheme.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              activeStep.description,
              style: GoogleFonts.poppins(fontSize: 12, color: RunnerTheme.textMid),
            ),
            const SizedBox(height: 18),
            const Divider(color: RunnerTheme.dividerColor, height: 1),
            const SizedBox(height: 18),
            ..._buildFields(activeStep.fields, formValues, ref, context),
            const SizedBox(height: 24),
            _buildActions(cfg, activeStep, showSubmit, isMobile: isMobile),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFields(
    List<JourneyField> fields,
    Map<String, dynamic> values,
    WidgetRef ref,
    BuildContext context,
  ) {
    return fields.map((f) {
      if (!EngineHelper.isFieldVisible(f, values)) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _buildField(f, values, ref, context),
      );
    }).toList();
  }

  Widget _buildField(
    JourneyField field,
    Map<String, dynamic> values,
    WidgetRef ref,
    BuildContext context,
  ) {
    return RunnerFieldPluginRegistry.buildField(
      FieldBuildContext(
        context: context,
        field: field,
        values: values,
        ref: ref,
        errors: errors,
        fd: ({
          required String label,
          String? hint,
          Widget? prefix,
          Widget? suffix,
          String? error,
          bool dense = false,
        }) =>
            buildRunnerInputDecoration(
          label: label,
          hint: hint,
          prefix: prefix,
          suffix: suffix,
          error: error,
          dense: dense,
        ),
        buildField: (f, v) => _buildField(f, v, ref, context),
        buildUpload: (f, v, hasErr, errMsg, {isImage = false}) =>
            _buildUpload(f, v, hasErr, errMsg, ref, isImage: isImage),
        buildGrid: (f) => RunnerGridWidget(field: f, showSnack: showSnack),
        buildRepeater: (f) => RunnerRepeaterWidget(field: f),
        buildTimeline: (f) => RunnerTimelineWidget(field: f),
        buildNested: (f, v, icon) => RunnerNestedWidget(
          field: f,
          values: v,
          icon: icon,
          buildFields: (fs, vs) => _buildFields(fs, vs, ref, context),
        ),
        buildTabs: (f, v) => RunnerTabsWidget(
          field: f,
          values: v,
          buildFields: (fs, vs) => _buildFields(fs, vs, ref, context),
        ),
        buildNestedRow: (f, v) => RunnerNestedRowWidget(
          field: f,
          values: v,
          buildField: (fs, vs) => _buildField(fs, vs, ref, context),
        ),
        buildApiDropdown: (f, initVal, onChange, err) => ApiDropdownWidget(
          field: f,
          initialValue: initVal,
          onChanged: onChange,
          errorText: err,
        ),
      ),
    );
  }

  Widget _buildUpload(
    JourneyField field,
    Map<String, dynamic> values,
    bool hasErr,
    String? errMsg,
    WidgetRef ref, {
    bool isImage = false,
  }) {
    final cur = values[field.id]?.toString() ?? '';
    return GestureDetector(
      onTap: () => ref.read(formValuesProvider.notifier).updateValue(
            field.id,
            isImage ? "image_uploaded.png" : "document_uploaded.pdf",
          ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: RunnerTheme.inputBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: hasErr ? RunnerTheme.error : RunnerTheme.border),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: RunnerTheme.brandSurface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isImage ? Icons.image_outlined : Icons.cloud_upload_outlined,
                color: RunnerTheme.brand,
                size: 22,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              cur.isNotEmpty ? cur : (isImage ? 'Click to upload image' : 'Drag & Drop or click to upload'),
              style: GoogleFonts.poppins(fontSize: 12, color: RunnerTheme.textMid),
            ),
            const SizedBox(height: 3),
            Text(
              'PNG, JPG, PDF up to 10MB',
              style: GoogleFonts.poppins(fontSize: 11, color: RunnerTheme.textLight),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => ref.read(formValuesProvider.notifier).updateValue(
                    field.id,
                    isImage ? "image_uploaded.png" : "document_uploaded.pdf",
                  ),
              style: OutlinedButton.styleFrom(
                foregroundColor: RunnerTheme.brand,
                side: const BorderSide(color: RunnerTheme.brand),
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
                style: GoogleFonts.poppins(fontSize: 11, color: RunnerTheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActions(
    JourneyConfig cfg,
    JourneyStep step,
    bool showSubmit, {
    bool isMobile = false,
  }) {
    final canGoBack = stepHistory.isNotEmpty;
    return isMobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: isExecuting
                    ? null
                    : () => runAction(
                          showSubmit ? JourneyAction.submit : JourneyAction.next,
                          step,
                          cfg,
                        ),
                icon: isExecuting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        showSubmit ? Icons.check_rounded : Icons.arrow_forward_rounded,
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
                  backgroundColor: RunnerTheme.brand,
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
                        onPressed: isExecuting ? null : () => runAction(JourneyAction.previous, step, cfg),
                        icon: const Icon(Icons.arrow_back_rounded, size: 15),
                        label: Text(
                          'Back',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: RunnerTheme.brand,
                          side: const BorderSide(color: RunnerTheme.border),
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
                      onPressed: isExecuting ? null : () => runAction(JourneyAction.saveDraft, step, cfg),
                      icon: const Icon(Icons.bookmark_border_rounded, size: 15),
                      label: Text(
                        'Save Draft',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: RunnerTheme.textMid,
                        side: const BorderSide(color: RunnerTheme.border),
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
                  () => runAction(JourneyAction.previous, step, cfg),
                  color: RunnerTheme.brand,
                ),
                const SizedBox(width: 10),
              ],
              _outlinedBtn(
                Icons.bookmark_border_rounded,
                'Save Draft',
                () => runAction(JourneyAction.saveDraft, step, cfg),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: isExecuting
                    ? null
                    : () => runAction(
                          showSubmit ? JourneyAction.submit : JourneyAction.next,
                          step,
                          cfg,
                        ),
                icon: isExecuting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        showSubmit ? Icons.check_rounded : Icons.arrow_forward_rounded,
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
                  backgroundColor: RunnerTheme.brand,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: RunnerTheme.brand.withValues(alpha: 0.45),
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
      onPressed: isExecuting ? null : onTap,
      icon: Icon(icon, size: 15),
      label: Text(
        label,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: const BorderSide(color: RunnerTheme.border),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
