// lib/features/journey_builder/presentation/widgets/canvas_panel/sections/live_preview_mockups.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/features/journey_builder/domain/entities/journey_models.dart';
import 'package:revojourneytryone/features/journey_builder/application/controllers/journey_controller.dart';
import 'live_preview_section.dart';

mixin LivePreviewMockups on ConsumerState<LivePreviewSection> {
  late final Map<String, Widget Function(JourneyField, Map<String, dynamic>)> mockupRegistry;

  void initMockupRegistry() {
    mockupRegistry = {
      'divider': (f, _) => Divider(color: RevoTheme.cardBorder),
      'dropdown': mockupDropdown,
      'api_dropdown': mockupApiDropdown,
      'radio': mockupRadio,
      'checkbox': mockupCheckbox,
      'switch': mockupSwitch,
      'date': mockupDate,
      'time': mockupDate,
      'datetime': mockupDate,
      'file': mockupFile,
      'image': mockupFile,
      'otp': mockupOtp,
      'phone': mockupPhone,
      'table_grid': (f, _) => buildCompactTablePreview(f),
      'repeater': (f, _) => buildCompactRepeaterPreview(f),
      'timeline': (f, _) => buildCompactTimelinePreview(f),
      'section': (f, values) => buildCompactNestedPreview(f, Icons.view_agenda_outlined, values),
      'card': (f, values) => buildCompactNestedPreview(f, Icons.crop_square_rounded, values),
      'tabs': (f, values) => buildCompactNestedTabsPreview(f, values),
      'accordion': (f, values) => buildCompactNestedPreview(f, Icons.unfold_more_rounded, values),
      'row': (f, values) => buildCompactNestedRowPreview(f, values),
      'formula': (f, _) => buildCompactComponentShell(Icons.functions_rounded, f.formula ?? "Calculated value"),
    };
  }

  Map<String, dynamic> componentConfig(JourneyField field) {
    return Map<String, dynamic>.from(field.componentConfig ?? {});
  }

  List<Map<String, dynamic>> configList(JourneyField field, String key, List<Map<String, dynamic>> fallback) {
    final value = componentConfig(field)[key];
    if (value is List) {
      final parsed = value
          .map((item) => item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{})
          .where((item) => item.isNotEmpty)
          .toList();
      if (parsed.isNotEmpty) return parsed;
    }
    return fallback;
  }

  Widget mockupDefault(JourneyField field, Map<String, dynamic> formValues) => SizedBox(height: field.type == 'textarea' ? 60 : 32, child: TextField(maxLines: field.type == 'textarea' ? 3 : 1, style: const TextStyle(fontSize: 10, color: Colors.white70), decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), hintText: field.placeholder ?? "Enter value", hintStyle: TextStyle(fontSize: 10, color: RevoTheme.textSecondary.withValues(alpha:0.5)), fillColor: RevoTheme.background, enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: RevoTheme.cardBorder)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: RevoTheme.primaryLight))), onChanged: (val) => ref.read(formValuesProvider.notifier).updateValue(field.id, val)));
  
  Widget mockupPhone(JourneyField field, Map<String, dynamic> formValues) => Row(children: [Container(height: 32, padding: const EdgeInsets.symmetric(horizontal: 6), decoration: BoxDecoration(color: RevoTheme.background, borderRadius: BorderRadius.circular(6), border: Border.all(color: RevoTheme.cardBorder)), alignment: Alignment.center, child: Text("🇮🇳 +91", style: TextStyle(fontSize: 9, color: RevoTheme.textSecondary))), const SizedBox(width: 4), Expanded(child: SizedBox(height: 32, child: TextField(style: const TextStyle(fontSize: 10, color: Colors.white70), decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), hintText: field.placeholder ?? "Enter mobile", hintStyle: TextStyle(fontSize: 10, color: RevoTheme.textSecondary.withValues(alpha:0.5)), fillColor: RevoTheme.background, enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: RevoTheme.cardBorder)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: RevoTheme.primaryLight))), onChanged: (val) => ref.read(formValuesProvider.notifier).updateValue(field.id, val))))]);
  
  Widget mockupOtp(JourneyField field, Map<String, dynamic> formValues) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(6, (_) => Container(width: 28, height: 32, alignment: Alignment.center, decoration: BoxDecoration(color: RevoTheme.background, borderRadius: BorderRadius.circular(6), border: Border.all(color: RevoTheme.cardBorder)), child: Text("-", style: TextStyle(fontSize: 10, color: RevoTheme.textSecondary.withValues(alpha: 0.6))))));
  
  Widget mockupFile(JourneyField field, Map<String, dynamic> formValues) => Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: RevoTheme.background, borderRadius: BorderRadius.circular(6), border: Border.all(color: RevoTheme.cardBorder)), child: Column(children: [Icon(field.type == 'image' ? Icons.image_outlined : Icons.cloud_upload_outlined, size: 18, color: RevoTheme.primaryLight), const SizedBox(height: 4), Text(field.placeholder ?? 'Upload file', style: TextStyle(fontSize: 9, color: RevoTheme.textSecondary))]));
  
  Widget mockupDate(JourneyField field, Map<String, dynamic> formValues) {
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
  
  Widget mockupSwitch(JourneyField field, Map<String, dynamic> formValues) {
    final value = formValues[field.id]?.toString() ?? '';
    final isSwitched = value == 'true';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(field.label, style: TextStyle(fontSize: 9, color: RevoTheme.textSecondary)),
        Transform.scale(
          scale: 0.6,
          child: Switch(
            value: isSwitched,
            onChanged: (val) => ref.read(formValuesProvider.notifier).updateValue(field.id, val.toString()),
          ),
        ),
      ],
    );
  }
  
  Widget mockupCheckbox(JourneyField field, Map<String, dynamic> formValues) {
    final value = formValues[field.id]?.toString() ?? '';
    final isChecked = value == 'true';
    return InkWell(
      onTap: () => ref.read(formValuesProvider.notifier).updateValue(field.id, (!isChecked).toString()),
      child: Row(
        children: [
          Icon(isChecked ? Icons.check_box : Icons.check_box_outline_blank, size: 14, color: isChecked ? RevoTheme.primaryLight : RevoTheme.textSecondary.withValues(alpha:0.5)),
          const SizedBox(width: 6),
          Expanded(child: Text(field.label, style: TextStyle(fontSize: 9, color: RevoTheme.textSecondary))),
        ],
      ),
    );
  }
  
  Widget mockupRadio(JourneyField field, Map<String, dynamic> formValues) {
    final value = formValues[field.id]?.toString() ?? '';
    final options = field.getResolvedOptions();
    final displayOptions = options.isEmpty ? ["Option 1", "Option 2"] : options;
    return Wrap(
      spacing: 6,
      children: displayOptions.map((opt) {
        final isSelected = value == opt;
        return InkWell(
          onTap: () => ref.read(formValuesProvider.notifier).updateValue(field.id, opt),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected ? RevoTheme.primary : RevoTheme.background,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: isSelected ? RevoTheme.primaryLight : RevoTheme.cardBorder),
            ),
            child: Text(opt, style: TextStyle(fontSize: 8, color: isSelected ? Colors.white : RevoTheme.textSecondary, fontWeight: FontWeight.bold)),
          ),
        );
      }).toList(),
    );
  }
  
  Widget mockupApiDropdown(JourneyField field, Map<String, dynamic> formValues) => Container(
    height: 32,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(color: RevoTheme.background, borderRadius: BorderRadius.circular(6), border: Border.all(color: RevoTheme.cardBorder)),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            field.dropdownApiUrl != null && field.dropdownApiUrl!.isNotEmpty ? "API: ${field.dropdownApiUrl}" : (field.placeholder ?? field.hintText ?? "Select (API Loaded)"),
            style: TextStyle(fontSize: 9, color: RevoTheme.textSecondary.withValues(alpha:0.5), overflow: TextOverflow.ellipsis),
          ),
        ),
        Icon(Icons.cloud_sync_outlined, size: 12, color: RevoTheme.primaryLight),
      ],
    ),
  );
  
  Widget mockupDropdown(JourneyField field, Map<String, dynamic> formValues) {
    final value = formValues[field.id]?.toString() ?? '';
    final options = field.getResolvedOptions();
    final displayOptions = options.isEmpty ? ["Option 1", "Option 2"] : options;
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: RevoTheme.background, borderRadius: BorderRadius.circular(6), border: Border.all(color: RevoTheme.cardBorder)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: displayOptions.contains(value) ? value : null,
          hint: Text(field.placeholder ?? field.hintText ?? "Select", style: TextStyle(fontSize: 10, color: RevoTheme.textSecondary.withValues(alpha:0.5))),
          isExpanded: true,
          dropdownColor: RevoTheme.cardBg,
          style: TextStyle(fontSize: 10, color: RevoTheme.textPrimary),
          items: displayOptions.map((opt) => DropdownMenuItem(value: opt, child: Text(opt, style: const TextStyle(fontSize: 10)))).toList(),
          onChanged: (val) {
            if (val != null) ref.read(formValuesProvider.notifier).updateValue(field.id, val);
          },
        ),
      ),
    );
  }

  Widget buildCompactComponentShell(IconData icon, String label) {
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

  Widget buildCompactNestedPreview(JourneyField field, IconData icon, Map<String, dynamic> formValues) {
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
                  child: buildMobileFieldMockup(child, formValues),
                )),
          ],
        ],
      ),
    );
  }

  Widget buildCompactNestedRowPreview(JourneyField field, Map<String, dynamic> formValues) {
    final children = field.nestedFields ?? const <JourneyField>[];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: children.take(3).map((child) {
        return SizedBox(width: 120, child: buildMobileFieldMockup(child, formValues));
      }).toList(),
    );
  }

  Widget buildCompactNestedTabsPreview(JourneyField field, Map<String, dynamic> formValues) {
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

  Widget buildCompactTablePreview(JourneyField field) {
    final columns = configList(field, 'columns', [
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

  Widget buildCompactRepeaterPreview(JourneyField field) {
    final config = componentConfig(field);
    final fields = configList(field, 'fields', [
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

  Widget buildCompactTimelinePreview(JourneyField field) {
    final items = configList(field, 'items', [
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

  Widget buildMobileFieldMockup(JourneyField field, Map<String, dynamic> formValues) {
    final builder = mockupRegistry[field.type.toLowerCase()];
    if (builder != null) return builder(field, formValues);
    return mockupDefault(field, formValues);
  }
}
