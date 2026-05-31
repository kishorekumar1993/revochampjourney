// lib/codegenerator/generators/bloc/generators/widget_sources_inputs.dart

const String appDatePickerFieldSource = r"""
// lib/bloc/core/widgets/app_date_picker_field.dart
import 'package:flutter/material.dart';
import 'form_field_wrapper.dart';

class AppDatePickerField extends StatelessWidget {
  const AppDatePickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
    this.errorText,
    this.enabled = true,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final String? hint;
  final String? errorText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final display = value == null 
      ? (hint ?? 'Select date')
      : '${value!.day.toString().padLeft(2, '0')}/${value!.month.toString().padLeft(2, '0')}/${value!.year}';

    return FormFieldWrapper(
      label: label,
      errorText: errorText,
      child: GestureDetector(
        onTap: enabled ? () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime(2100),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Color(0xFF6366F1), // header background color
                    onPrimary: Colors.white, // header text color
                    onSurface: Color(0xFF1E293B), // body text color
                  ),
                ),
                child: child!,
              );
            },
          );
          if (picked != null) {
            onChanged(picked);
          }
        } : null,
        child: InputDecorator(
          decoration: InputDecoration(
            hintText: hint,
            errorText: null, // error handled by wrapper
            border: _border(),
            enabledBorder: _border(),
            focusedBorder: _border(focused: true),
            errorBorder: _border(error: true),
            filled: true,
            fillColor: !enabled ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                display,
                style: TextStyle(
                  fontSize: 15,
                  color: value == null ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
                ),
              ),
              const Icon(Icons.calendar_today_outlined, size: 20, color: Color(0xFF64748B)),
            ],
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _border({bool focused = false, bool error = false}) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(
      color: error 
          ? const Color(0xFFEF4444)
          : focused 
              ? const Color(0xFF6366F1) 
              : const Color(0xFFE2E8F0),
      width: focused ? 2.0 : 1.0,
    ),
  );
}
""";

const String appRadioGroupFieldSource = r"""
// lib/bloc/core/widgets/app_radio_group_field.dart
import 'package:flutter/material.dart';
import 'form_field_wrapper.dart';

class AppRadioGroupField extends StatelessWidget {
  const AppRadioGroupField({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.errorText,
    this.enabled = true,
  });

  final String label;
  final List<String> options;
  final String? value;
  final ValueChanged<String?> onChanged;
  final String? errorText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return FormFieldWrapper(
      label: label,
      errorText: errorText,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: errorText != null ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          children: options.map((opt) => RadioListTile<String>(
            value: opt,
            groupValue: value,
            title: Text(opt, style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B))),
            dense: true,
            activeColor: const Color(0xFF6366F1),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            onChanged: enabled ? onChanged : null,
          )).toList(),
        ),
      ),
    );
  }
}
""";

const String appFileUploadFieldSource = r"""
// lib/bloc/core/widgets/app_file_upload_field.dart
import 'package:flutter/material.dart';
import 'form_field_wrapper.dart';

class AppFileUploadField extends StatelessWidget {
  const AppFileUploadField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
    this.errorText,
    this.enabled = true,
  });

  final String label;
  final String? value;
  final ValueChanged<String?> onChanged;
  final String? hint;
  final String? errorText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final display = value?.isNotEmpty == true ? value!.split('/').last : 'No file selected';

    return FormFieldWrapper(
      label: label,
      errorText: errorText,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: errorText != null ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0)
              ),
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFFF8FAFC),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    display,
                    style: TextStyle(
                      color: value == null ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE0E7FF),
                    foregroundColor: const Color(0xFF4338CA),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('Browse', style: TextStyle(fontWeight: FontWeight.w600)),
                  onPressed: enabled ? () async {
                    // Placeholder logic: You would integrate file_picker here.
                    // final result = await FilePicker.platform.pickFiles();
                    // if (result != null) onChanged(result.files.single.path);
                    onChanged('mock_file_path/document.pdf');
                  } : null,
                ),
              ],
            ),
          ),
          if (hint != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                hint!,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
""";

const String appMultiSelectFieldSource = r"""
// lib/bloc/core/widgets/app_multi_select_field.dart
import 'package:flutter/material.dart';
import 'form_field_wrapper.dart';

class AppMultiSelectField extends StatelessWidget {
  const AppMultiSelectField({
    super.key,
    required this.label,
    required this.options,
    required this.selectedValues,
    required this.onChanged,
    this.errorText,
    this.enabled = true,
  });

  final String label;
  final List<String> options;
  final List<String> selectedValues;
  final ValueChanged<List<String>> onChanged;
  final String? errorText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return FormFieldWrapper(
      label: label,
      errorText: errorText,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.map((opt) {
          final isSelected = selectedValues.contains(opt);
          return FilterChip(
            label: Text(opt, style: TextStyle(
              color: isSelected ? const Color(0xFF4338CA) : const Color(0xFF475569),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            )),
            selected: isSelected,
            showCheckmark: false,
            selectedColor: const Color(0xFFE0E7FF),
            backgroundColor: const Color(0xFFF1F5F9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: isSelected ? const Color(0xFF818CF8) : const Color(0xFFE2E8F0),
              ),
            ),
            onSelected: enabled ? (_) {
              final current = List<String>.from(selectedValues);
              if (isSelected) {
                current.remove(opt);
              } else {
                current.add(opt);
              }
              onChanged(current);
            } : null,
          );
        }).toList(),
      ),
    );
  }
}
""";

const String appCheckboxFieldSource = r"""
// lib/bloc/core/widgets/app_checkbox_field.dart
import 'package:flutter/material.dart';

class AppCheckboxField extends StatelessWidget {
  const AppCheckboxField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.errorText,
    this.enabled = true,
  });

  final String         label;
  final bool           value;
  final ValueChanged<bool?> onChanged;
  final String?        subtitle;
  final String?        errorText;
  final bool           enabled;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      CheckboxListTile(
        value:       value,
        onChanged:   enabled ? onChanged : null,
        title:       Text(label, style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B))),
        subtitle:    subtitle != null ? Text(subtitle!, style: const TextStyle(color: Color(0xFF64748B))) : null,
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: const Color(0xFF6366F1),
        dense:       true,
      ),
      if (errorText != null)
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 2),
          child: Text(errorText!,
              style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444))),
        ),
      const SizedBox(height: 8),
    ],
  );
}
""";

const String appDataGridSource = r"""
// lib/bloc/core/widgets/app_data_grid.dart
import 'package:flutter/material.dart';
import 'form_field_wrapper.dart';

class AppDataGridColumn {
  const AppDataGridColumn({
    required this.keyName,
    required this.label,
    this.flex = 1,
    this.readOnly = false,
  });

  final String keyName;
  final String label;
  final int flex;
  final bool readOnly;
}

class AppDataGrid extends StatelessWidget {
  const AppDataGrid({
    super.key,
    required this.label,
    required this.columns,
    required this.rows,
    required this.onRowsChanged,
    this.errorText,
    this.enabled = true,
    this.maxRows = 100,
  });

  final String label;
  final List<AppDataGridColumn> columns;
  final List<Map<String, dynamic>> rows;
  final ValueChanged<List<Map<String, dynamic>>> onRowsChanged;
  final String? errorText;
  final bool enabled;
  final int maxRows;

  @override
  Widget build(BuildContext context) {
    return FormFieldWrapper(
      label: label,
      errorText: errorText,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: columns
                  .map((c) => DataColumn(label: Text(c.label)))
                  .toList(growable: false),
              rows: List<DataRow>.generate(rows.length, (rowIndex) {
                final row = rows[rowIndex];
                return DataRow(
                  cells: columns.map((col) {
                    final value = row[col.keyName]?.toString() ?? '';
                    if (col.readOnly || !enabled) {
                      return DataCell(Text(value));
                    }
                    return DataCell(
                      SizedBox(
                        width: 160,
                        child: TextFormField(
                          initialValue: value,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (newVal) {
                            final copy = rows
                                .map((e) => Map<String, dynamic>.from(e))
                                .toList(growable: true);
                            copy[rowIndex][col.keyName] = newVal;
                            onRowsChanged(copy);
                          },
                        ),
                      ),
                    );
                  }).toList(growable: false),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: enabled && rows.length < maxRows
                    ? () {
                        final newRow = <String, dynamic>{
                          for (final c in columns) c.keyName: null,
                        };
                        onRowsChanged([
                          ...rows.map((e) => Map<String, dynamic>.from(e)),
                          newRow,
                        ]);
                      }
                    : null,
                icon: const Icon(Icons.add),
                label: const Text('Add row'),
              ),
              OutlinedButton.icon(
                onPressed: enabled && rows.isNotEmpty
                    ? () {
                        final copy = rows
                            .map((e) => Map<String, dynamic>.from(e))
                            .toList(growable: true);
                        copy.removeLast();
                        onRowsChanged(copy);
                      }
                    : null,
                icon: const Icon(Icons.remove),
                label: const Text('Remove row'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
""";
