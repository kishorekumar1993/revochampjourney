import 'package:revojourneytryone/codegenerator/filegegnerator/journey_step_codegen.dart';
import 'package:revojourneytryone/codegenerator/getx/getx_model_naming.dart';
import 'layouts/split_layout.dart';
import 'layouts/focus_layout.dart';
import 'layouts/timeline_layout.dart';
import 'layouts/tabbed_layout.dart';
import 'layouts/carousel_layout.dart';
import 'layouts/accordion_layout.dart';
import 'layouts/masterdetail_layout.dart';
import 'layouts/default_layout.dart';
import 'layouts/wizard_layout.dart';
import 'layouts/review_layout.dart';
import 'layouts/dashboard_layout.dart';
import 'layouts/chat_layout.dart';
import 'layouts/kanban_layout.dart';
import 'layouts/stepper_layout.dart';
import 'plugins/field_generator_plugins.dart';

String generateviewClass(
  String className,
  List<dynamic> fields,
  String fileName, {
  Map<String, dynamic>? stepJson,
  List<dynamic>? allSteps,
  String layoutStyle = 'split',
}) {
  final buffer = StringBuffer();
  final stepMeta = JourneyStepCodegen.fromJson(stepJson ?? {});
  final stepsList = allSteps ?? [];
  final activeIdx = stepsList.indexWhere((s) => s['id'] == stepMeta.id);
  final activeIdxClamp = activeIdx != -1 ? activeIdx : 0;

  // ─── Recursive flatten ────────────────────────────────────────
  void flattenFields(dynamic source, List<Map<String, dynamic>> result) {
    if (source == null) return;
    if (source is List) {
      for (final item in source) {
        flattenFields(item, result);
      }
      return;
    }
    if (source is! Map) return;
    final map = Map<String, dynamic>.from(source);
    if (map.containsKey('steps')) {
      flattenFields(map['steps'], result);
      return;
    }
    if (map.containsKey('fields')) {
      flattenFields(map['fields'], result);
      return;
    }
    if (map.containsKey('type')) {
      result.add(map);
      flattenFields(map['nestedFields'], result);
      final config = map['componentConfig'];
      if (config is Map) {
        flattenFields(config['fields'], result);
        flattenFields(config['columns'], result);
      }
    }
  }

  final flatFields = <Map<String, dynamic>>[];
  flattenFields(fields, flatFields);

  // ─── Imports ──────────────────────────────────────────────────
  buffer.writeln("import 'package:flutter/material.dart';");
  buffer.writeln("import 'package:flutter/services.dart';");
  buffer.writeln("import 'package:get/get.dart';");
  buffer.writeln("import 'package:google_fonts/google_fonts.dart';");
  buffer.writeln(
    "import '../controllers/${fileName.toLowerCase().replaceAll(' ', '_')}_controller.dart';",
  );
  buffer.writeln("import '../../../../core/widgets/widgets.dart';");

  final emittedModelFiles = <String>{};
  for (final field in flatFields) {
    if (!fieldNeedsGetxModel(field)) continue;
    final modelFile = resolveGetxModelFileBase(field);
    if (emittedModelFiles.add(modelFile)) {
      buffer.writeln("import '${getxModelImportPath(modelFile)}';");
    }
  }
  buffer.writeln();

  // ─── View class ──────────────────────────────────────────────
  buffer.writeln(
    "class ${className}View extends GetView<${className}Controller> {",
  );
  buffer.writeln("  const ${className}View({super.key});");
  buffer.writeln();

  // Generate build method based on layoutStyle
  buffer.writeln("  @override");
  buffer.writeln("  Widget build(BuildContext context) {");
  buffer.writeln("    final theme = Theme.of(context);");
  buffer.writeln();

  final normStyle = layoutStyle.toLowerCase().trim();

  if (normStyle == 'split') {
    generateSplitLayout(buffer, stepMeta, className);
  } else if (normStyle == 'focus') {
    generateFocusLayout(buffer, stepMeta, className, stepsList, activeIdxClamp);
  } else if (normStyle == 'timeline') {
    generateTimelineLayout(buffer, stepMeta, className, stepsList, activeIdxClamp);
  } else if (normStyle == 'tabbed') {
    generateTabbedLayout(buffer, stepMeta, className, stepsList, activeIdxClamp);
  } else if (normStyle == 'carousel' || normStyle == 'curasole') {
    generateCarouselLayout(buffer, stepMeta, className, stepsList, activeIdxClamp);
  } else if (normStyle == 'accordion') {
    generateAccordionLayout(buffer, stepMeta, className, stepsList, activeIdxClamp);
  } else if (normStyle == 'masterdetail') {
    generateMasterDetailLayout(buffer, stepMeta, className, stepsList, activeIdxClamp);
  } else if (normStyle == 'wizard') {
    generateWizardLayout(buffer, stepMeta, className, stepsList, activeIdxClamp);
  } else if (normStyle == 'review') {
    generateReviewLayout(buffer, stepMeta, className, stepsList, activeIdxClamp);
  } else if (normStyle == 'dashboard') {
    generateDashboardLayout(buffer, stepMeta, className, stepsList, activeIdxClamp);
  } else if (normStyle == 'chat' || normStyle == 'chatform') {
    generateChatLayout(buffer, stepMeta, className, stepsList, activeIdxClamp);
  } else if (normStyle == 'kanban') {
    generateKanbanLayout(buffer, stepMeta, className, stepsList, activeIdxClamp);
  } else if (normStyle == 'stepper') {
    generateStepperLayout(buffer, stepMeta, className, stepsList, activeIdxClamp);
  } else {
    generateDefaultLayout(buffer, stepMeta, className);
  }

  buffer.writeln("  }");
  buffer.writeln();

  // Generate _buildFormContent method
  buffer.writeln("  Widget _buildFormContent(BuildContext context, {bool isMobile = false}) {");
  buffer.writeln("    final theme = Theme.of(context);");
  buffer.writeln("    return Form(");
  buffer.writeln("      key: controller.formKey,");
  buffer.writeln("      autovalidateMode: AutovalidateMode.onUserInteraction,");
  buffer.writeln("      child: Column(");
  buffer.writeln("        crossAxisAlignment: CrossAxisAlignment.start,");
  buffer.writeln("        children: [");
  
  stepMeta.writeFlutterStepHeader(buffer);

  // ─── Recursive widget builder ────────────────────────────────
  void buildWidgets(List<dynamic> currentFields) {
    for (int i = 0; i < currentFields.length; i++) {
      final rawField = currentFields[i];
      if (rawField is! Map<String, dynamic>) continue;
      final field = rawField;

      final rawId =
          (field['label'] ?? field['id'] ?? field['fieldId'] ?? 'field')
              .toString()
              .trim();
      final rawLabel = rawId;
      final name = camelCaseName(rawId);
      final capitalLabel = pascalCaseName(rawId);
      final type = (field['type'] ?? '').toString().toLowerCase().trim();
      final hint = (field['placeholder'] ?? field['hintText'] ?? '').toString();
      final isRequired = field['required'] == true;
      final isPassword = field['obscureText'] == true;
      final isReadOnly = field['readOnly'] == true;
      final rawKeyboard = (field['keyboardType'] ?? 'text')
          .toString()
          .toLowerCase();
      final keyboardType = _mapKeyboardType(rawKeyboard);
      final textInputAction = (field['textInputAction'] ?? 'done')
          .toString()
          .toLowerCase();
      final textCapitalization = (field['textCapitalization'] ?? 'none')
          .toString()
          .toLowerCase();
      final maxLength = int.tryParse(field['maxLength']?.toString() ?? '') ?? 0;

      final fieldId = field['id']?.toString() ?? '';
      final constName =
          fieldId.isNotEmpty ? 'kField${pascalCaseName(rawId)}' : '';
      final fieldIdRef = fieldId.isNotEmpty
          ? '${className}Controller.$constName'
          : "''";
      final visibilityCheck = fieldId.isNotEmpty
          ? "controller.isVisible($fieldIdRef)"
          : 'true';
      final errorRef = fieldId.isNotEmpty
          ? "controller.fieldErrors[$fieldIdRef]"
          : "''";

      buffer.writeln("                Obx(() {");
      buffer.writeln("                  if (!$visibilityCheck) return const SizedBox.shrink();");
      buffer.writeln("                  return ");

      final plugin = FieldGeneratorRegistry.find(type);
      if (plugin != null) {
        plugin.generateWidget(
          buffer,
          field,
          name,
          capitalLabel,
          rawLabel,
          hint,
          isRequired,
          isPassword,
          isReadOnly,
          keyboardType,
          textInputAction,
          textCapitalization,
          maxLength,
          errorRef,
          className,
          buildWidgets,
        );
      } else {
        buffer.writeln("                  // TODO: unsupported field type '$type' for '$rawLabel'");
        buffer.writeln("                  const SizedBox.shrink();");
      }

      buffer.writeln("                }),"); // Close outer Obx

      if (i < currentFields.length - 1) {
        buffer.writeln("                const SizedBox(height: 16),");
      }
    }
  }

  buildWidgets(fields);

  // ─── Render action buttons panel at the bottom of the form ──
  buffer.writeln("                const SizedBox(height: 24),");
  buffer.writeln("                _buildActions(context, isMobile: isMobile),");

  buffer.writeln("        ],");
  buffer.writeln("      ),");
  buffer.writeln("    );");
  buffer.writeln("  }");
  buffer.writeln();

  // Generate layouts helpers
  _generateLayoutHelperMethods(buffer, normStyle, stepsList, activeIdxClamp, flatFields);

  // Generate loading overlay
  buffer.writeln("  Widget _buildLoadingOverlay() {");
  buffer.writeln("    return Obx(() {");
  buffer.writeln("      if (!controller.isExecuting.value) return const SizedBox.shrink();");
  buffer.writeln("      return AbsorbPointer(");
  buffer.writeln("        absorbing: true,");
  buffer.writeln("        child: Container(");
  buffer.writeln("          color: Colors.black.withValues(alpha: 0.15),");
  buffer.writeln("          child: const Center(");
  buffer.writeln("            child: CircularProgressIndicator(");
  buffer.writeln("              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5B4FCF)),");
  buffer.writeln("            ),");
  buffer.writeln("          ),");
  buffer.writeln("        ),");
  buffer.writeln("      );");
  buffer.writeln("    });");
  buffer.writeln("  }");

  // Generate _formatDateTime if any datetime fields exist
  final hasDateTime = flatFields.any((f) {
    final t = (f['type'] ?? '').toString().toLowerCase();
    return t == 'datetime' || t == 'date time';
  });
  if (hasDateTime) {
    buffer.writeln();
    buffer.writeln("  String _formatDateTime(DateTime dt) {");
    buffer.writeln("    return '\${dt.year}-\${dt.month.toString().padLeft(2, '0')}-\${dt.day.toString().padLeft(2, '0')} '");
    buffer.writeln("        '\${dt.hour.toString().padLeft(2, '0')}:\${dt.minute.toString().padLeft(2, '0')}';");
    buffer.writeln("  }");
  }

  buffer.writeln("}");
  return buffer.toString();
}

// ─── Keyboard mapping & name helpers ───────────────────────────
String _mapKeyboardType(String raw) {
  switch (raw) {
    case 'number':
    case 'numeric':
    case 'integer':
    case 'int':
      return 'number';
    case 'decimal':
    case 'double':
    case 'float':
    case 'decimalPad':
      return 'decimalPad';
    case 'phone':
      return 'phone';
    case 'email':
    case 'emailAddress':
      return 'emailAddress';
    case 'url':
      return 'url';
    case 'multiline':
      return 'multiline';
    default:
      return 'text';
  }
}

String capitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
String normalizeLabel(String label) =>
    label.trim().replaceAll(RegExp(r'\s+'), '');
String camelCaseName(String label) {
  final n = normalizeLabel(label);
  return n.isEmpty ? '' : n[0].toLowerCase() + n.substring(1);
}
String pascalCaseName(String label) {
  final n = normalizeLabel(label);
  return n.isEmpty ? '' : n[0].toUpperCase() + n.substring(1);
}

void _generateLayoutHelperMethods(
  StringBuffer buffer,
  String layoutStyle,
  List<dynamic> stepsList,
  int activeIdxClamp,
  List<Map<String, dynamic>> flatFields,
) {
  // Generate _getStepTitle
  buffer.writeln("  String _getStepTitle(int index) {");
  buffer.writeln("    switch (index) {");
  for (int i = 0; i < stepsList.length; i++) {
    final title = (stepsList[i]['title'] ?? 'Step ${i + 1}').toString().replaceAll("'", "\\'");
    buffer.writeln("      case $i: return '$title';");
  }
  buffer.writeln("      default: return 'Step';");
  buffer.writeln("    }");
  buffer.writeln("  }");
  buffer.writeln();

  // Generate _getStepDesc
  buffer.writeln("  String _getStepDesc(int index) {");
  buffer.writeln("    switch (index) {");
  for (int i = 0; i < stepsList.length; i++) {
    final desc = (stepsList[i]['description'] ?? '').toString().replaceAll("'", "\\'");
    buffer.writeln("      case $i: return '$desc';");
  }
  buffer.writeln("      default: return '';");
  buffer.writeln("    }");
  buffer.writeln("  }");
  buffer.writeln();

  // Generate _getStepId
  buffer.writeln("  String _getStepId(int index) {");
  buffer.writeln("    switch (index) {");
  for (int i = 0; i < stepsList.length; i++) {
    final id = (stepsList[i]['id'] ?? 'step').toString().replaceAll("'", "\\'");
    buffer.writeln("      case $i: return '$id';");
  }
  buffer.writeln("      default: return '';");
  buffer.writeln("    }");
  buffer.writeln("  }");
  buffer.writeln();

  // Generate _stepIconForTitle
  buffer.writeln("  IconData _stepIconForTitle(String title) {");
  buffer.writeln("    final t = title.toLowerCase();");
  buffer.writeln("    if (t.contains('personal')) return Icons.person_outline_rounded;");
  buffer.writeln("    if (t.contains('vehicle')) return Icons.directions_car_outlined;");
  buffer.writeln("    if (t.contains('nominee')) return Icons.supervisor_account_outlined;");
  buffer.writeln("    if (t.contains('document')) return Icons.upload_file_outlined;");
  buffer.writeln("    if (t.contains('review') || t.contains('confirm')) {");
  buffer.writeln("      return Icons.fact_check_outlined;");
  buffer.writeln("    }");
  buffer.writeln("    if (t.contains('payment')) return Icons.credit_card_outlined;");
  buffer.writeln("    if (t.contains('success')) return Icons.verified_outlined;");
  buffer.writeln("    return Icons.article_outlined;");
  buffer.writeln("  }");
  buffer.writeln();

  // Generate _buildIllustration
  buffer.writeln("  Widget _buildIllustration(String title) {");
  buffer.writeln("    final icon = _stepIconForTitle(title);");
  buffer.writeln("    return SizedBox(");
  buffer.writeln("      height: 150,");
  buffer.writeln("      child: Stack(");
  buffer.writeln("        alignment: Alignment.center,");
  buffer.writeln("        children: [");
  buffer.writeln("          Container(");
  buffer.writeln("            width: 140,");
  buffer.writeln("            height: 140,");
  buffer.writeln("            decoration: BoxDecoration(");
  buffer.writeln("              color: const Color(0xFF5B4FCF).withValues(alpha: 0.05),");
  buffer.writeln("              shape: BoxShape.circle,");
  buffer.writeln("            ),");
  buffer.writeln("          ),");
  buffer.writeln("          Container(");
  buffer.writeln("            width: 100,");
  buffer.writeln("            height: 100,");
  buffer.writeln("            decoration: BoxDecoration(");
  buffer.writeln("              color: const Color(0xFF5B4FCF).withValues(alpha: 0.08),");
  buffer.writeln("              shape: BoxShape.circle,");
  buffer.writeln("            ),");
  buffer.writeln("          ),");
  buffer.writeln("          Container(");
  buffer.writeln("            width: 68,");
  buffer.writeln("            height: 68,");
  buffer.writeln("            decoration: const BoxDecoration(");
  buffer.writeln("              color: Color(0xFFEEECFD),");
  buffer.writeln("              shape: BoxShape.circle,");
  buffer.writeln("              boxShadow: [");
  buffer.writeln("                BoxShadow(");
  buffer.writeln("                  color: Color(0x215B4FCF),");
  buffer.writeln("                  blurRadius: 18,");
  buffer.writeln("                  offset: Offset(0, 5),");
  buffer.writeln("                ),");
  buffer.writeln("              ],");
  buffer.writeln("            ),");
  buffer.writeln("            child: Icon(icon, color: const Color(0xFF5B4FCF), size: 32),");
  buffer.writeln("          ),");
  buffer.writeln("        ],");
  buffer.writeln("      ),");
  buffer.writeln("    );");
  buffer.writeln("  }");
  buffer.writeln();

  // Generate _buildActions panel method
  _generateActionsBuilder(buffer, stepsList, activeIdxClamp);

  // Generate style-specific helper methods
  if (layoutStyle == 'split') {
    generateSplitHelpers(buffer, activeIdxClamp, stepsList.length);
  } else if (layoutStyle == 'focus') {
    generateFocusHelpers(buffer);
  } else if (layoutStyle == 'tabbed') {
    _generateLiveSummaryBuilder(buffer, flatFields);
  } else if (layoutStyle == 'carousel' || layoutStyle == 'curasole') {
    generateCarouselHelpers(buffer);
  } else if (layoutStyle == 'dashboard') {
    generateDashboardHelpers(buffer);
  } else if (layoutStyle == 'chat' || layoutStyle == 'chatform') {
    generateChatHelpers(buffer);
  } else if (layoutStyle == 'kanban') {
    generateKanbanHelpers(buffer);
  }
}

void _generateActionsBuilder(StringBuffer buffer, List<dynamic> stepsList, int activeIdxClamp) {
  buffer.writeln("  Widget _buildActions(BuildContext context, {bool isMobile = false}) {");
  buffer.writeln("    final canGoBack = $activeIdxClamp > 0;");
  if (activeIdxClamp > 0 && activeIdxClamp - 1 < stepsList.length) {
    final backId = stepsList[activeIdxClamp - 1]['id'];
    buffer.writeln("    final backTarget = '$backId';");
  } else {
    buffer.writeln("    final backTarget = '';");
  }
  buffer.writeln();

  buffer.writeln("    final primaryButton = Obx(() => ElevatedButton.icon(");
  buffer.writeln("      onPressed: controller.isExecuting.value");
  buffer.writeln("          ? null");
  buffer.writeln("          : () => controller.onPrimaryAction(),");
  buffer.writeln("      icon: controller.isExecuting.value");
  buffer.writeln("          ? const SizedBox(");
  buffer.writeln("              width: 16,");
  buffer.writeln("              height: 16,");
  buffer.writeln("              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),");
  buffer.writeln("            )");
  buffer.writeln("          : const Icon(Icons.arrow_forward_rounded, size: 18),");
  buffer.writeln("      label: Text(");
  buffer.writeln("        'Save & Continue',");
  buffer.writeln("        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),");
  buffer.writeln("      ),");
  buffer.writeln("      style: ElevatedButton.styleFrom(");
  buffer.writeln("        backgroundColor: const Color(0xFF5B4FCF),");
  buffer.writeln("        foregroundColor: Colors.white,");
  buffer.writeln("        disabledBackgroundColor: const Color(0xFF5B4FCF).withValues(alpha: 0.45),");
  buffer.writeln("        elevation: 0,");
  buffer.writeln("        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),");
  buffer.writeln("        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),");
  buffer.writeln("      ),");
  buffer.writeln("    ));");
  buffer.writeln();

  buffer.writeln("    final draftButton = OutlinedButton.icon(");
  buffer.writeln("      onPressed: () {");
  buffer.writeln("        Get.snackbar(");
  buffer.writeln("          'Draft Saved',");
  buffer.writeln("          'Your progress has been saved successfully.',");
  buffer.writeln("          snackPosition: SnackPosition.BOTTOM,");
  buffer.writeln("          backgroundColor: const Color(0xFF5B4FCF),");
  buffer.writeln("          colorText: Colors.white,");
  buffer.writeln("          borderRadius: 8,");
  buffer.writeln("          margin: const EdgeInsets.all(12),");
  buffer.writeln("        );");
  buffer.writeln("      },");
  buffer.writeln("      icon: const Icon(Icons.bookmark_border_rounded, size: 15),");
  buffer.writeln("      label: Text(");
  buffer.writeln("        'Save Draft',");
  buffer.writeln("        style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13),");
  buffer.writeln("      ),");
  buffer.writeln("      style: OutlinedButton.styleFrom(");
  buffer.writeln("        foregroundColor: const Color(0xFF6B7280),");
  buffer.writeln("        side: const BorderSide(color: Color(0xFFE4E6F0)),");
  buffer.writeln("        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),");
  buffer.writeln("        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),");
  buffer.writeln("      ),");
  buffer.writeln("    );");
  buffer.writeln();

  buffer.writeln("    Widget? backButton;");
  buffer.writeln("    if (canGoBack) {");
  buffer.writeln("      backButton = OutlinedButton.icon(");
  buffer.writeln("        onPressed: () => Get.toNamed('/' + backTarget),");
  buffer.writeln("        icon: const Icon(Icons.arrow_back_rounded, size: 15),");
  buffer.writeln("        label: Text(");
  buffer.writeln("          'Back',");
  buffer.writeln("          style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13),");
  buffer.writeln("        ),");
  buffer.writeln("        style: OutlinedButton.styleFrom(");
  buffer.writeln("          foregroundColor: const Color(0xFF5B4FCF),");
  buffer.writeln("          side: const BorderSide(color: Color(0xFFE4E6F0)),");
  buffer.writeln("          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),");
  buffer.writeln("          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),");
  buffer.writeln("        ),");
  buffer.writeln("      );");
  buffer.writeln("    }");
  buffer.writeln();

  buffer.writeln("    if (isMobile) {");
  buffer.writeln("      return Column(");
  buffer.writeln("        crossAxisAlignment: CrossAxisAlignment.stretch,");
  buffer.writeln("        children: [");
  buffer.writeln("          SizedBox(width: double.infinity, child: primaryButton),");
  buffer.writeln("          const SizedBox(height: 10),");
  buffer.writeln("          Row(");
  buffer.writeln("            children: [");
  buffer.writeln("              if (backButton != null) ...[");
  buffer.writeln("                Expanded(child: backButton),");
  buffer.writeln("                const SizedBox(width: 10),");
  buffer.writeln("              ],");
  buffer.writeln("              Expanded(child: draftButton),");
  buffer.writeln("            ],");
  buffer.writeln("          ),");
  buffer.writeln("        ],");
  buffer.writeln("      );");
  buffer.writeln("    }");
  buffer.writeln();

  buffer.writeln("    return Row(");
  buffer.writeln("      mainAxisAlignment: MainAxisAlignment.end,");
  buffer.writeln("      children: [");
  buffer.writeln("        if (backButton != null) ...[");
  buffer.writeln("          backButton,");
  buffer.writeln("          const SizedBox(width: 10),");
  buffer.writeln("        ],");
  buffer.writeln("        draftButton,");
  buffer.writeln("        const SizedBox(width: 10),");
  buffer.writeln("        primaryButton,");
  buffer.writeln("      ],");
  buffer.writeln("    );");
  buffer.writeln("  }");
  buffer.writeln();
}

void _generateLiveSummaryBuilder(StringBuffer buffer, List<Map<String, dynamic>> flatFields) {
  buffer.writeln("  Widget _buildLiveSummaryCard(BuildContext context) {");
  buffer.writeln("    return Column(");
  buffer.writeln("      crossAxisAlignment: CrossAxisAlignment.start,");
  buffer.writeln("      children: [");
  buffer.writeln("        Row(");
  buffer.writeln("          children: [");
  buffer.writeln("            const Icon(Icons.analytics_outlined, color: Color(0xFF5B4FCF), size: 18),");
  buffer.writeln("            const SizedBox(width: 8),");
  buffer.writeln("            Text(");
  buffer.writeln("              'Real-time Summary',");
  buffer.writeln("              style: GoogleFonts.poppins(");
  buffer.writeln("                fontSize: 13,");
  buffer.writeln("                fontWeight: FontWeight.bold,");
  buffer.writeln("                color: const Color(0xFF1A1A2E),");
  buffer.writeln("              ),");
  buffer.writeln("            ),");
  buffer.writeln("          ],");
  buffer.writeln("        ),");
  buffer.writeln("        const SizedBox(height: 12),");
  buffer.writeln("        const Divider(color: Color(0xFFE4E6F0), height: 1),");
  buffer.writeln("        const SizedBox(height: 12),");
  buffer.writeln("        Expanded(");
  buffer.writeln("          child: ListView(");
  buffer.writeln("            children: [");

  for (final field in flatFields) {
    final rawId = (field['label'] ?? field['id'] ?? 'field').toString().trim();
    final rawLabel = rawId;
    final name = camelCaseName(rawId);
    final capitalLabel = pascalCaseName(rawId);
    final type = (field['type'] ?? '').toString().toLowerCase().trim();

    final plugin = FieldGeneratorRegistry.find(type);
    if (plugin != null) {
      plugin.generateSummaryRow(
        buffer,
        field,
        name,
        capitalLabel,
        rawLabel,
      );
    }
  }

  buffer.writeln("            ],");
  buffer.writeln("          ),");
  buffer.writeln("        ),");
  buffer.writeln("      ],");
  buffer.writeln("    );");
  buffer.writeln("  }");
  buffer.writeln();

  // Summary Row Widget
  buffer.writeln("  Widget _buildSummaryRow(String label, String value) {");
  buffer.writeln("    return Padding(");
  buffer.writeln("      padding: const EdgeInsets.only(bottom: 8.0),");
  buffer.writeln("      child: Column(");
  buffer.writeln("        crossAxisAlignment: CrossAxisAlignment.start,");
  buffer.writeln("        children: [");
  buffer.writeln("          Text(");
  buffer.writeln("            label.toUpperCase(),");
  buffer.writeln("            style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF5B4FCF)),");
  buffer.writeln("          ),");
  buffer.writeln("          const SizedBox(height: 2),");
  buffer.writeln("          Text(");
  buffer.writeln("            value,");
  buffer.writeln("            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A2E)),");
  buffer.writeln("          ),");
  buffer.writeln("          const SizedBox(height: 6),");
  buffer.writeln("          const Divider(color: Color(0xFFE4E6F0), height: 1),");
  buffer.writeln("        ],");
  buffer.writeln("      ),");
  buffer.writeln("    );");
  buffer.writeln("  }");
  buffer.writeln();
}
