import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/features/journey_builder/domain/entities/journey_models.dart';
import 'package:revojourneytryone/features/journey_builder/application/controllers/journey_controller.dart';
import 'package:revojourneytryone/features/journey_builder/application/controllers/journey_validation_manager.dart';

class LivePreviewSection extends ConsumerStatefulWidget {
  final JourneyStep step;
  final Map<String, dynamic> formValues;
  final String? previousStepId;
  final String? nextStepId;
  final bool isMobilePreview;

  const LivePreviewSection({
    super.key,
    required this.step,
    required this.formValues,
    required this.previousStepId,
    required this.nextStepId,
    required this.isMobilePreview,
  });

  @override
  ConsumerState<LivePreviewSection> createState() => _LivePreviewSectionState();
}

class _LivePreviewSectionState extends ConsumerState<LivePreviewSection> {
  late final Map<String, Widget Function(JourneyField, Map<String, dynamic>)> _mockupRegistry;

  @override
  void initState() {
    super.initState();
    _mockupRegistry = {
      'divider': (f, _) => Divider(color: RevoTheme.cardBorder),
      'dropdown': _mockupDropdown,
      'api_dropdown': _mockupApiDropdown,
      'radio': _mockupRadio,
      'checkbox': _mockupCheckbox,
      'switch': _mockupSwitch,
      'date': _mockupDate,
      'time': _mockupDate,
      'datetime': _mockupDate,
      'file': _mockupFile,
      'image': _mockupFile,
      'otp': _mockupOtp,
      'phone': _mockupPhone,
      'table_grid': (f, _) => _buildCompactTablePreview(f),
      'repeater': (f, _) => _buildCompactRepeaterPreview(f),
      'timeline': (f, _) => _buildCompactTimelinePreview(f),
      'section': (f, values) => _buildCompactNestedPreview(f, Icons.view_agenda_outlined, values),
      'card': (f, values) => _buildCompactNestedPreview(f, Icons.crop_square_rounded, values),
      'tabs': (f, values) => _buildCompactNestedTabsPreview(f, values),
      'accordion': (f, values) => _buildCompactNestedPreview(f, Icons.unfold_more_rounded, values),
      'row': (f, values) => _buildCompactNestedRowPreview(f, values),
      'formula': (f, _) => _buildCompactComponentShell(Icons.functions_rounded, f.formula ?? "Calculated value"),
    };
  }

  Map<String, dynamic> _componentConfig(JourneyField field) {
    return Map<String, dynamic>.from(field.componentConfig ?? {});
  }

  List<Map<String, dynamic>> _configList(JourneyField field, String key, List<Map<String, dynamic>> fallback) {
    final value = _componentConfig(field)[key];
    if (value is List) {
      final parsed = value
          .map((item) => item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{})
          .where((item) => item.isNotEmpty)
          .toList();
      if (parsed.isNotEmpty) return parsed;
    }
    return fallback;
  }

  Widget _mockupDefault(JourneyField field, Map<String, dynamic> formValues) => SizedBox(height: field.type == 'textarea' ? 60 : 32, child: TextField(maxLines: field.type == 'textarea' ? 3 : 1, style: const TextStyle(fontSize: 10, color: Colors.white70), decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), hintText: field.placeholder ?? "Enter value", hintStyle: TextStyle(fontSize: 10, color: RevoTheme.textSecondary.withValues(alpha:0.5)), fillColor: RevoTheme.background, enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: RevoTheme.cardBorder)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: RevoTheme.primaryLight))), onChanged: (val) => ref.read(formValuesProvider.notifier).updateValue(field.id, val)));
  Widget _mockupPhone(JourneyField field, Map<String, dynamic> formValues) => Row(children: [Container(height: 32, padding: const EdgeInsets.symmetric(horizontal: 6), decoration: BoxDecoration(color: RevoTheme.background, borderRadius: BorderRadius.circular(6), border: Border.all(color: RevoTheme.cardBorder)), alignment: Alignment.center, child: Text("🇮🇳 +91", style: TextStyle(fontSize: 9, color: RevoTheme.textSecondary))), const SizedBox(width: 4), Expanded(child: SizedBox(height: 32, child: TextField(style: const TextStyle(fontSize: 10, color: Colors.white70), decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), hintText: field.placeholder ?? "Enter mobile", hintStyle: TextStyle(fontSize: 10, color: RevoTheme.textSecondary.withValues(alpha:0.5)), fillColor: RevoTheme.background, enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: RevoTheme.cardBorder)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: RevoTheme.primaryLight))), onChanged: (val) => ref.read(formValuesProvider.notifier).updateValue(field.id, val))))]);
  Widget _mockupOtp(JourneyField field, Map<String, dynamic> formValues) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(6, (_) => Container(width: 28, height: 32, alignment: Alignment.center, decoration: BoxDecoration(color: RevoTheme.background, borderRadius: BorderRadius.circular(6), border: Border.all(color: RevoTheme.cardBorder)), child: Text("-", style: TextStyle(fontSize: 10, color: RevoTheme.textSecondary.withValues(alpha: 0.6))))));
  Widget _mockupFile(JourneyField field, Map<String, dynamic> formValues) => Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: RevoTheme.background, borderRadius: BorderRadius.circular(6), border: Border.all(color: RevoTheme.cardBorder)), child: Column(children: [Icon(field.type == 'image' ? Icons.image_outlined : Icons.cloud_upload_outlined, size: 18, color: RevoTheme.primaryLight), const SizedBox(height: 4), Text(field.placeholder ?? 'Upload file', style: TextStyle(fontSize: 9, color: RevoTheme.textSecondary))]));
  Widget _mockupDate(JourneyField field, Map<String, dynamic> formValues) {
    final value = formValues[field.id]?.toString() ?? '';
    return InkWell(
      onTap: () async {
        if (field.type == 'time') {
          final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
          if (picked != null) {
            final hour = picked.hour.toString().padLeft(2, '0');
            final minute = picked.minute.toString().padLeft(2, '0');
            ref.read(formValuesProvider.notifier).updateValue(field.id, "$hour:$minute");
          }
          return;
        }
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          final formatted = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
          ref.read(formValuesProvider.notifier).updateValue(field.id, formatted);
        }
      },
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: RevoTheme.background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: RevoTheme.cardBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                value.isNotEmpty ? value : (field.placeholder ?? (field.type == 'time' ? "HH:MM" : "DD/MM/YYYY")),
                style: TextStyle(
                  fontSize: 10,
                  color: value.isNotEmpty ? RevoTheme.textPrimary : RevoTheme.textSecondary.withValues(alpha: 0.5),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.calendar_today_rounded,
              size: 10,
              color: RevoTheme.textSecondary.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
  Widget _mockupSwitch(JourneyField field, Map<String, dynamic> formValues) { final value = formValues[field.id]?.toString() ?? ''; final isSwitched = value == 'true'; return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(field.label, style: TextStyle(fontSize: 9, color: RevoTheme.textSecondary)), Transform.scale(scale: 0.6, child: Switch(value: isSwitched, onChanged: (val) => ref.read(formValuesProvider.notifier).updateValue(field.id, val.toString())))]); }
  Widget _mockupCheckbox(JourneyField field, Map<String, dynamic> formValues) { final value = formValues[field.id]?.toString() ?? ''; final isChecked = value == 'true'; return InkWell(onTap: () => ref.read(formValuesProvider.notifier).updateValue(field.id, (!isChecked).toString()), child: Row(children: [Icon(isChecked ? Icons.check_box : Icons.check_box_outline_blank, size: 14, color: isChecked ? RevoTheme.primaryLight : RevoTheme.textSecondary.withValues(alpha:0.5)), const SizedBox(width: 6), Expanded(child: Text(field.label, style: TextStyle(fontSize: 9, color: RevoTheme.textSecondary)))])); }
  Widget _mockupRadio(JourneyField field, Map<String, dynamic> formValues) { final value = formValues[field.id]?.toString() ?? ''; final options = field.getResolvedOptions(); final displayOptions = options.isEmpty ? ["Option 1", "Option 2"] : options; return Wrap(spacing: 6, children: displayOptions.map((opt) { final isSelected = value == opt; return InkWell(onTap: () => ref.read(formValuesProvider.notifier).updateValue(field.id, opt), child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: isSelected ? RevoTheme.primary : RevoTheme.background, borderRadius: BorderRadius.circular(4), border: Border.all(color: isSelected ? RevoTheme.primaryLight : RevoTheme.cardBorder)), child: Text(opt, style: TextStyle(fontSize: 8, color: isSelected ? Colors.white : RevoTheme.textSecondary, fontWeight: FontWeight.bold)))); }).toList()); }
  Widget _mockupApiDropdown(JourneyField field, Map<String, dynamic> formValues) => Container(height: 32, padding: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(color: RevoTheme.background, borderRadius: BorderRadius.circular(6), border: Border.all(color: RevoTheme.cardBorder)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(field.dropdownApiUrl != null && field.dropdownApiUrl!.isNotEmpty ? "API: ${field.dropdownApiUrl}" : (field.placeholder ?? field.hintText ?? "Select (API Loaded)"), style: TextStyle(fontSize: 9, color: RevoTheme.textSecondary.withValues(alpha:0.5), overflow: TextOverflow.ellipsis))), Icon(Icons.cloud_sync_outlined, size: 12, color: RevoTheme.primaryLight)]));
  Widget _mockupDropdown(JourneyField field, Map<String, dynamic> formValues) { final value = formValues[field.id]?.toString() ?? ''; final options = field.getResolvedOptions(); final displayOptions = options.isEmpty ? ["Option 1", "Option 2"] : options; return Container(height: 32, padding: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(color: RevoTheme.background, borderRadius: BorderRadius.circular(6), border: Border.all(color: RevoTheme.cardBorder)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: displayOptions.contains(value) ? value : null, hint: Text(field.placeholder ?? field.hintText ?? "Select", style: TextStyle(fontSize: 10, color: RevoTheme.textSecondary.withValues(alpha:0.5))), isExpanded: true, dropdownColor: RevoTheme.cardBg, style: TextStyle(fontSize: 10, color: RevoTheme.textPrimary), items: displayOptions.map((opt) => DropdownMenuItem(value: opt, child: Text(opt, style: const TextStyle(fontSize: 10)))).toList(), onChanged: (val) { if (val != null) ref.read(formValuesProvider.notifier).updateValue(field.id, val); }))); }

  Widget _buildCompactComponentShell(IconData icon, String label) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: RevoTheme.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: RevoTheme.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: RevoTheme.primaryLight),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 9, color: RevoTheme.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactNestedPreview(JourneyField field, IconData icon, Map<String, dynamic> formValues) {
    final children = field.nestedFields ?? const <JourneyField>[];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: RevoTheme.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: RevoTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: RevoTheme.primaryLight),
              const SizedBox(width: 8),
              Expanded(child: Text(field.label, style: TextStyle(fontSize: 9, color: RevoTheme.textPrimary), overflow: TextOverflow.ellipsis)),
            ],
          ),
          if (children.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...children.take(3).map((child) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _buildMobileFieldMockup(child, formValues),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactNestedRowPreview(JourneyField field, Map<String, dynamic> formValues) {
    final children = field.nestedFields ?? const <JourneyField>[];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: children.take(3).map((child) {
        return SizedBox(width: 120, child: _buildMobileFieldMockup(child, formValues));
      }).toList(),
    );
  }

  Widget _buildCompactNestedTabsPreview(JourneyField field, Map<String, dynamic> formValues) {
    final tabs = field.nestedFields ?? const <JourneyField>[];
    final labels = tabs.isEmpty ? ['Tab 1', 'Tab 2'] : tabs.map((tab) => tab.label).toList();
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: labels.map((tab) {
        final selected = tab == labels.first;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? RevoTheme.primary.withValues(alpha: 0.18) : RevoTheme.background,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: selected ? RevoTheme.primaryLight : RevoTheme.cardBorder),
          ),
          child: Text(tab, style: TextStyle(fontSize: 8, color: selected ? RevoTheme.primaryLight : RevoTheme.textSecondary)),
        );
      }).toList(),
    );
  }

  Widget _buildCompactTablePreview(JourneyField field) {
    final columns = _configList(field, 'columns', [
      if (field.nestedFields != null && field.nestedFields!.isNotEmpty)
        ...field.nestedFields!.map((nested) => {'label': nested.label, 'fieldId': nested.id})
      else ...[
        {'label': '#'},
        {'label': 'Label'},
        {'label': 'Act'},
      ],
    ]).take(3).toList();
    return Container(
      decoration: BoxDecoration(
        color: RevoTheme.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: RevoTheme.cardBorder),
      ),
      child: Column(
        children: List.generate(3, (row) {
          return Row(
            children: List.generate(columns.length, (col) {
              return Expanded(
                child: Container(
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      right: col < 2 ? BorderSide(color: RevoTheme.cardBorder) : BorderSide.none,
                      bottom: row < 2 ? BorderSide(color: RevoTheme.cardBorder) : BorderSide.none,
                    ),
                  ),
                  child: Text(
                    row == 0 ? (columns[col]['label']?.toString() ?? 'Col') : (col == 0 ? '1' : 'Value'),
                    style: TextStyle(fontSize: 8, color: row == 0 ? RevoTheme.textPrimary : RevoTheme.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            }),
          );
        }),
      ),
    );
  }

  Widget _buildCompactRepeaterPreview(JourneyField field) {
    final config = _componentConfig(field);
    final fields = _configList(field, 'fields', [
      if (field.nestedFields != null && field.nestedFields!.isNotEmpty)
        ...field.nestedFields!.map((nested) => {'label': nested.label, 'fieldId': nested.id})
      else ...[
        {'label': 'Name'},
        {'label': 'Value'},
      ],
    ]).take(2).toList();
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: RevoTheme.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: RevoTheme.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.view_week_outlined, size: 14, color: RevoTheme.primaryLight),
              const SizedBox(width: 6),
              Expanded(child: Text("${config['itemLabel'] ?? 'Item'} 1", style: TextStyle(fontSize: 9, color: RevoTheme.textPrimary))),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: fields
                .map((item) => Expanded(
                      child: Container(
                        height: 24,
                        margin: const EdgeInsets.only(right: 4),
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: RevoTheme.cardBg,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: RevoTheme.cardBorder),
                        ),
                        child: Text(item['label']?.toString() ?? 'Field', style: TextStyle(fontSize: 8, color: RevoTheme.textSecondary), overflow: TextOverflow.ellipsis),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTimelinePreview(JourneyField field) {
    final items = _configList(field, 'items', [
      {'title': 'Started', 'status': 'completed'},
      {'title': 'Current', 'status': 'active'},
      {'title': 'Done', 'status': 'pending'},
    ]).take(3).toList();
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: RevoTheme.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: RevoTheme.cardBorder),
      ),
      child: Column(
        children: items
            .map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 8, color: item['status'] == 'completed' ? RevoTheme.secondary : RevoTheme.primaryLight),
                      const SizedBox(width: 6),
                      Expanded(child: Text(item['title']?.toString() ?? 'Step', style: TextStyle(fontSize: 8, color: RevoTheme.textSecondary), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildMobileFieldMockup(JourneyField field, Map<String, dynamic> formValues) {
    final builder = _mockupRegistry[field.type.toLowerCase()];
    if (builder != null) return builder(field, formValues);
    return _mockupDefault(field, formValues);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isMobilePreview) {
      // Laptop / Desktop Preview
      return Expanded(
        flex: 4,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: RevoTheme.cardBorder, width: 1),
            ),
            color: RevoTheme.background,
          ),
          padding: const EdgeInsets.all(20.0),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.contain,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Laptop screen bezel
                Container(
                  width: 480,
                  height: 330,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: RevoTheme.cardBorder, width: 8),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 24,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Web browser window header
                      Container(
                        height: 28,
                        color: RevoTheme.sidebarBackground,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: [
                            // Dots
                            Row(
                              children: [
                                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
                                const SizedBox(width: 4),
                                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.amberAccent, shape: BoxShape.circle)),
                                const SizedBox(width: 4),
                                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
                              ],
                            ),
                            const SizedBox(width: 16),
                            // URL Address Bar
                            Expanded(
                              child: Container(
                                height: 18,
                                decoration: BoxDecoration(
                                  color: RevoTheme.background,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Row(
                                  children: [
                                    Icon(Icons.lock_outline_rounded, size: 10, color: RevoTheme.success),
                                    const SizedBox(width: 4),
                                    Text(
                                      "revojourneytryone.com/run/journey",
                                      style: TextStyle(fontSize: 9, color: RevoTheme.textSecondary.withValues(alpha:0.7)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Browser Web Viewport
                      Expanded(
                        child: Container(
                          color: RevoTheme.background,
                          padding: const EdgeInsets.all(12),
                          alignment: Alignment.center,
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 360,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: RevoTheme.cardBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: RevoTheme.cardBorder, width: 1),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x1F000000),
                                        blurRadius: 12,
                                      )
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        widget.step.title,
                                        style: TextStyle(fontFamily: 'Outfit',
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: RevoTheme.textPrimary,
                                        ),
                                      ),
                                      if (widget.step.description.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          widget.step.description,
                                          style: TextStyle(fontFamily: 'Inter',
                                            fontSize: 9,
                                            color: RevoTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 12),

                                      // Fields Mockups
                                      ...widget.step.fields.map((field) {
                                        final isVisible = EngineHelper.isFieldVisible(field, widget.formValues);
                                        if (!isVisible) return const SizedBox.shrink();

                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 10.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              if (field.type != 'divider') ...[
                                                Row(
                                                  children: [
                                                    Text(
                                                      field.label,
                                                      style: TextStyle(fontFamily: 'Inter',
                                                        fontSize: 9,
                                                        color: RevoTheme.textSecondary,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                    if (field.required)
                                                      const Text(" *", style: TextStyle(color: Colors.red, fontSize: 9)),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                              ],
                                              _buildMobileFieldMockup(field, widget.formValues),
                                            ],
                                          ),
                                        );
                                      }),

                                      const SizedBox(height: 12),
                                      // Navigation Actions Mockup
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          if (widget.previousStepId != null)
                                            OutlinedButton(
                                              onPressed: () {
                                                ref.read(activeStepIdProvider.notifier).state = widget.previousStepId!;
                                                ref.read(selectedFieldIdProvider.notifier).state = null;
                                              },
                                              style: OutlinedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                minimumSize: Size.zero,
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                              child: const Text("Back", style: TextStyle(fontSize: 9)),
                                            )
                                          else
                                            const SizedBox.shrink(),
                                          ElevatedButton(
                                            onPressed: () {
                                              if (widget.nextStepId != null) {
                                                ref.read(activeStepIdProvider.notifier).state = widget.nextStepId!;
                                                ref.read(selectedFieldIdProvider.notifier).state = null;
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                            child: Text(
                                              widget.nextStepId == null ? "Submit" : "Next",
                                              style: const TextStyle(fontSize: 9),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Laptop Hinge and base plate
                Container(
                  width: 500,
                  height: 8,
                  decoration: BoxDecoration(
                    color: RevoTheme.isDark ? const Color(0xFF3A3A4E) : const Color(0xFFCBD5E1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                ),
                Container(
                  width: 530,
                  height: 10,
                  decoration: BoxDecoration(
                    color: RevoTheme.isDark ? const Color(0xFF222234) : const Color(0xFF94A3B8),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 50,
                    height: 4,
                    decoration: BoxDecoration(
                      color: RevoTheme.isDark ? Colors.black38 : Colors.white60,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Default Mobile View
    return Expanded(
      flex: 2,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: RevoTheme.cardBorder, width: 1),
          ),
          color: RevoTheme.background,
        ),
        padding: const EdgeInsets.all(24.0),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.contain,
          child: Container(
            width: 250,
            height: 520,
            decoration: BoxDecoration(
              color: RevoTheme.isDark ? Colors.black : const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: RevoTheme.isDark ? RevoTheme.cardBorder : const Color(0xFF334155), width: 8),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                color: RevoTheme.background,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  children: [
                    // Mobile status indicator bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "9:41",
                          style: TextStyle(fontFamily: 'Inter',
                            fontSize: 10,
                            color: RevoTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.wifi, size: 10, color: RevoTheme.textPrimary),
                            const SizedBox(width: 4),
                            Icon(Icons.signal_cellular_4_bar_rounded, size: 10, color: RevoTheme.textPrimary),
                            const SizedBox(width: 4),
                            Icon(Icons.battery_5_bar_rounded, size: 10, color: RevoTheme.textPrimary),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Screen Title
                    Text(
                      widget.step.title,
                      style: TextStyle(fontFamily: 'Outfit',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: RevoTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (widget.step.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.step.description,
                        style: TextStyle(fontFamily: 'Inter',
                          fontSize: 9,
                          color: RevoTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 12),

                    // Fields Renders inside Simulator
                    Expanded(
                      child: ListView.builder(
                        itemCount: widget.step.fields.length,
                        itemBuilder: (context, index) {
                          final field = widget.step.fields[index];
                          final isVisible = EngineHelper.isFieldVisible(field, widget.formValues);
                          if (!isVisible) return const SizedBox.shrink();

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (field.type != 'divider') ...[
                                  Row(
                                    children: [
                                      Text(
                                        field.label,
                                        style: TextStyle(fontFamily: 'Inter',
                                          fontSize: 10,
                                          color: RevoTheme.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (field.required)
                                        const Text(" *", style: TextStyle(color: Colors.red, fontSize: 10)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                ],
                                _buildMobileFieldMockup(field, widget.formValues),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    // Button actions inside simulator
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (widget.nextStepId != null) {
                            ref.read(activeStepIdProvider.notifier).state = widget.nextStepId!;
                            ref.read(selectedFieldIdProvider.notifier).state = null;
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          widget.nextStepId == null ? "Submit" : "Next",
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
