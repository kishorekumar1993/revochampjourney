import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme.dart';
import '../../../journey_builder/data/models.dart';
import '../../../journey_builder/presentation/providers/journey_provider.dart';


class ComponentRenderer extends ConsumerWidget {
  final JourneyField field;
  final List<dynamic> path;
  final Map<String, dynamic> formValues;
  final Map<String, String> errors;
  
  const ComponentRenderer({
    super.key,
    required this.field,
    required this.path,
    required this.formValues,
    required this.errors,
  });

  dynamic _getValue(WidgetRef ref) {
    dynamic current = formValues;
    for (var key in path) {
      if (current == null) return null;
      if (current is Map && current.containsKey(key)) {
        current = current[key];
      } else if (current is List && key is int && current.length > key) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current;
  }

  void _updateValue(WidgetRef ref, dynamic val) {
    ref.read(formValuesProvider.notifier).updateValueByPath(path, val);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVisible = EngineHelper.isFieldVisible(field, formValues);
    if (!isVisible) return const SizedBox.shrink();

    final hasError = errors.containsKey(field.id);
    final errorMsg = errors[field.id];
    final currentVal = _getValue(ref);

    Widget content;

    if (field is LayoutComponent) {
      content = _buildLayout(context, ref, field as LayoutComponent);
    } else if (field is GridComponent) {
      content = _buildGrid(context, ref, field as GridComponent, currentVal);
    } else if (field is RepeaterComponent) {
      content = _buildRepeater(context, ref, field as RepeaterComponent, currentVal);
    } else if (field is OptionsComponent) {
      content = _buildOptions(context, ref, field as OptionsComponent, currentVal, hasError, errorMsg);
    } else {
      content = _buildInput(context, ref, field as InputComponent, currentVal, hasError, errorMsg);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: content,
    );
  }

  Widget _buildLayout(BuildContext context, WidgetRef ref, LayoutComponent layout) {
    final children = layout.nestedFields ?? [];
    
    // Simple Column layout for section/card
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RevoTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RevoTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.view_agenda_outlined, size: 18, color: RevoTheme.primaryLight),
              const SizedBox(width: 10),
              Expanded(child: Text(layout.label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: RevoTheme.textPrimary))),
            ],
          ),
          if (children.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...children.map((child) => ComponentRenderer(
              field: child,
              path: [...path, child.id],
              formValues: formValues,
              errors: errors,
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context, WidgetRef ref, GridComponent grid, dynamic currentVal) {
    // Implement proper grid using state
    return Text("Grid Rendering: ${grid.label} (Not implemented in renderer yet)");
  }

  Widget _buildRepeater(BuildContext context, WidgetRef ref, RepeaterComponent repeater, dynamic currentVal) {
    // Implement repeater
    return Text("Repeater Rendering: ${repeater.label}");
  }

  Widget _buildOptions(BuildContext context, WidgetRef ref, OptionsComponent options, dynamic currentVal, bool hasError, String? errorMsg) {
    if (options.type == 'radio') {
      final opts = options.getResolvedOptions();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(options.label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: opts.map((opt) {
              final isSelected = currentVal == opt;
              return ChoiceChip(
                label: Text(opt),
                selected: isSelected,
                selectedColor: RevoTheme.primary,
                backgroundColor: RevoTheme.cardBg,
                onSelected: (selected) {
                  if (selected) _updateValue(ref, opt);
                },
              );
            }).toList(),
          ),
        ],
      );
    }
    
    // Default to dropdown
    final opts = options.getResolvedOptions();
    final displayOptions = opts.isEmpty ? ["Select"] : opts;
    return DropdownButtonFormField<String>(
      value: displayOptions.contains(currentVal) ? currentVal : null,
      decoration: InputDecoration(
        labelText: options.label,
        errorText: hasError ? errorMsg : null,
      ),
      items: displayOptions.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
      onChanged: (val) {
        if (val != null) _updateValue(ref, val);
      },
    );
  }

  Widget _buildInput(BuildContext context, WidgetRef ref, InputComponent input, dynamic currentVal, bool hasError, String? errorMsg) {
    return TextField(
      controller: TextEditingController(text: currentVal?.toString() ?? ''),
      onChanged: (val) => _updateValue(ref, val),
      decoration: InputDecoration(
        labelText: input.label,
        hintText: input.placeholder,
        errorText: hasError ? errorMsg : null,
      ),
    );
  }
}
