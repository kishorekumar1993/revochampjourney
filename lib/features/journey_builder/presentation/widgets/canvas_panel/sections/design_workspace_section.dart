import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/features/journey_builder/domain/entities/journey_models.dart';
import 'package:revojourneytryone/features/journey_builder/application/controllers/journey_controller.dart';
import 'canvas_config_helper.dart';

class DesignWorkspaceSection extends ConsumerStatefulWidget {
  final JourneyStep step;
  final String? selectedFieldId;

  const DesignWorkspaceSection({
    super.key,
    required this.step,
    required this.selectedFieldId,
  });

  @override
  ConsumerState<DesignWorkspaceSection> createState() => _DesignWorkspaceSectionState();
}

class _DesignWorkspaceSectionState extends ConsumerState<DesignWorkspaceSection> {
  late final Map<String, Widget Function(JourneyField, String)> _previewRegistry;

  @override
  void initState() {
    super.initState();
    _previewRegistry = {
      'dropdown': _previewDropdown,
      'api_dropdown': _previewDropdown,
      'radio': _previewRadio,
      'checkbox': _previewCheckbox,
      'switch': _previewSwitch,
      'date': _previewDate,
      'time': _previewDate,
      'datetime': _previewDate,
      'file': _previewFile,
      'image': _previewFile,
      'textarea': _previewTextarea,
      'number': _previewNumber,
      'table_grid': (f, _) => _buildTableGridPreview(f),
      'repeater': (f, _) => _buildRepeaterPreview(f),
      'timeline': (f, _) => _buildTimelinePreview(f),
      'section': (f, sid) => _buildNestedCanvasPreview(f, Icons.view_agenda_outlined, sid),
      'card': (f, sid) => _buildNestedCanvasPreview(f, Icons.crop_square_rounded, sid),
      'tabs': (f, sid) => _buildNestedTabsCanvasPreview(f, sid),
      'accordion': (f, sid) => _buildNestedCanvasPreview(f, Icons.unfold_more_rounded, sid),
      'row': (f, sid) => _buildNestedRowCanvasPreview(f, sid),
      'formula': (f, _) => _buildPreviewBox(child: Text(f.formula ?? f.defaultValue ?? 'Calculated value', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: RevoTheme.primaryLight))),
      'divider': (f, _) => Divider(color: RevoTheme.cardBorder),
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

  Widget _buildCanvasComponentPreview(JourneyField field, String stepId) {
    final builder = _previewRegistry[field.type.toLowerCase()];
    if (builder != null) return builder(field, stepId);
    return _previewDefault(field, stepId);
  }

  Widget _previewDefault(JourneyField field, String stepId) => _buildPreviewBox(child: Text(field.placeholder ?? 'Enter value', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: RevoTheme.textSecondary)));
  Widget _previewTextarea(JourneyField field, String stepId) => _buildPreviewBox(height: 72, child: Align(alignment: Alignment.topLeft, child: Text(field.placeholder ?? 'Enter details', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: RevoTheme.textSecondary))));
  Widget _previewNumber(JourneyField field, String stepId) => _buildPreviewBox(child: Text(field.placeholder ?? 'Enter number', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: RevoTheme.textSecondary)));
  Widget _previewDate(JourneyField field, String stepId) => _buildPreviewBox(child: Row(children: [Expanded(child: Text(field.placeholder ?? (field.type == 'time' ? 'HH:MM' : 'DD/MM/YYYY'), style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: RevoTheme.textSecondary))), Icon(Icons.calendar_today_rounded, size: 16, color: RevoTheme.textSecondary)]));
  Widget _previewFile(JourneyField field, String stepId) => _buildPreviewBox(height: 68, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(field.type == 'image' ? Icons.image_outlined : Icons.cloud_upload_outlined, size: 20, color: RevoTheme.primaryLight), const SizedBox(height: 4), Text(field.placeholder ?? 'Upload file', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: RevoTheme.textSecondary))]));
  Widget _previewCheckbox(JourneyField field, String stepId) => Row(children: [Icon(Icons.check_box_outline_blank_rounded, size: 18, color: RevoTheme.textSecondary), const SizedBox(width: 8), Expanded(child: Text(field.label, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: RevoTheme.textSecondary)))]);
  Widget _previewSwitch(JourneyField field, String stepId) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(field.label, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: RevoTheme.textSecondary))), Switch(value: field.defaultValue == 'true', onChanged: null)]);
  Widget _previewDropdown(JourneyField field, String stepId) => _buildPreviewBox(child: Row(children: [Expanded(child: Text(field.placeholder ?? 'Select an option', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: RevoTheme.textSecondary), overflow: TextOverflow.ellipsis)), Icon(field.type == 'api_dropdown' ? Icons.cloud_sync_outlined : Icons.keyboard_arrow_down_rounded, size: 16, color: RevoTheme.textSecondary)]));
  Widget _previewRadio(JourneyField field, String stepId) => Wrap(spacing: 8, runSpacing: 8, children: (field.getResolvedOptions().isEmpty ? ['Option 1', 'Option 2'] : field.getResolvedOptions()).map((option) => Chip(label: Text(option, style: TextStyle(fontFamily: 'Inter', fontSize: 11)), avatar: Icon(Icons.radio_button_unchecked_rounded, size: 14, color: RevoTheme.primaryLight), backgroundColor: RevoTheme.background, side: BorderSide(color: RevoTheme.cardBorder))).toList());

  Widget _buildPreviewBox({required Widget child, double height = 42}) {
    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: RevoTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RevoTheme.cardBorder),
      ),
      child: child,
    );
  }

  Widget _buildTabsPreview() {
    return Row(
      children: ['Tab 1', 'Tab 2', 'Tab 3'].map((label) {
        final selected = label == 'Tab 1';
        return Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? RevoTheme.primary.withValues(alpha: 0.15) : RevoTheme.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? RevoTheme.primaryLight : RevoTheme.cardBorder),
          ),
          child: Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: selected ? RevoTheme.primaryLight : RevoTheme.textSecondary)),
        );
      }).toList(),
    );
  }

  Widget _buildNestedCanvasPreview(JourneyField field, IconData icon, String stepId) {
    final children = field.nestedFields ?? const <JourneyField>[];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: RevoTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RevoTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: RevoTheme.primaryLight),
              const SizedBox(width: 8),
              Expanded(child: Text(field.label, style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700, color: RevoTheme.textPrimary))),
            ],
          ),
          if (children.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...children.take(6).map((child) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => ref.read(selectedFieldIdProvider.notifier).state = child.id,
                          child: _buildCanvasComponentPreview(child, stepId),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 13, color: Colors.redAccent),
                        onPressed: () => ref.read(journeyConfigProvider.notifier)
                            .removeFieldFromNestedContainer(stepId, child.id),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                )),
          ],
          DragTarget<String>(
            onAcceptWithDetails: (details) {
              final newFieldId = "field_${DateTime.now().millisecondsSinceEpoch}";
              final defaults = componentDefaults(details.data);
              final newField = JourneyField.fromJson({
                'id': newFieldId,
                'label': defaults['label'],
                'type': details.data,
                'required': false,
                'placeholder': defaults['placeholder'],
                'options': defaults['options'],
                'defaultValue': defaults['defaultValue'],
                'componentConfig': defaults['componentConfig'],
              });
              ref.read(journeyConfigProvider.notifier)
                  .addFieldToNestedContainer(stepId, field.id, newField);
            },
            builder: (context, candidateData, _) {
              final isOver = candidateData.isNotEmpty;
              return Container(
                height: 28,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: isOver
                      ? RevoTheme.primary.withValues(alpha: 0.12)
                      : RevoTheme.cardBg.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isOver ? RevoTheme.primaryLight : RevoTheme.cardBorder,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  isOver ? 'Drop here' : '+ drop field inside',
                  style: TextStyle(fontFamily: 'Inter',
                    fontSize: 9,
                    color: isOver ? RevoTheme.primaryLight : RevoTheme.textSecondary,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNestedRowCanvasPreview(JourneyField field, String stepId) {
    final children = field.nestedFields ?? const <JourneyField>[];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: children.take(4).map((child) {
        return SizedBox(
          width: 180,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(child.label, style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: RevoTheme.textSecondary)),
              const SizedBox(height: 4),
              InkWell(
                onTap: () => ref.read(selectedFieldIdProvider.notifier).state = child.id,
                child: _buildCanvasComponentPreview(child, stepId),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNestedTabsCanvasPreview(JourneyField field, String stepId) {
    final tabs = field.nestedFields ?? const <JourneyField>[];
    if (tabs.isEmpty) return _buildTabsPreview();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          children: tabs.map((tab) {
            final selected = tab == tabs.first;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? RevoTheme.primary.withValues(alpha: 0.15) : RevoTheme.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? RevoTheme.primaryLight : RevoTheme.cardBorder),
              ),
              child: Text(tab.label, style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: selected ? RevoTheme.primaryLight : RevoTheme.textSecondary)),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        if (tabs.first.nestedFields != null)
          ...tabs.first.nestedFields!.take(3).map((child) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: InkWell(
                  onTap: () => ref.read(selectedFieldIdProvider.notifier).state = child.id,
                  child: _buildCanvasComponentPreview(child, stepId),
                ),
              )),
      ],
    );
  }

  Widget _buildTableGridPreview(JourneyField field) {
    final columns = _configList(field, 'columns', [
      if (field.nestedFields != null && field.nestedFields!.isNotEmpty)
        ...field.nestedFields!.map((nested) => {'label': nested.label, 'fieldId': nested.id})
      else ...[
        {'label': '#'},
        {'label': 'Column A'},
        {'label': 'Action'},
      ],
    ]).take(4).toList();
    return Container(
      decoration: BoxDecoration(
        color: RevoTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RevoTheme.cardBorder),
      ),
      child: Column(
        children: List.generate(3, (row) {
          return Row(
            children: List.generate(columns.length, (col) {
              return Expanded(
                child: Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    border: Border(
                      right: col < 2 ? BorderSide(color: RevoTheme.cardBorder) : BorderSide.none,
                      bottom: row < 2 ? BorderSide(color: RevoTheme.cardBorder) : BorderSide.none,
                    ),
                  ),
                  child: Text(
                    row == 0 ? (columns[col]['label']?.toString() ?? 'Column') : (col == columns.length - 1 ? 'Edit' : 'Value'),
                    style: TextStyle(fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: row == 0 ? FontWeight.w700 : FontWeight.w400,
                      color: row == 0 ? RevoTheme.textPrimary : RevoTheme.textSecondary,
                    ),
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

  Widget _buildRepeaterPreview(JourneyField field) {
    final config = _componentConfig(field);
    final fields = _configList(field, 'fields', [
      if (field.nestedFields != null && field.nestedFields!.isNotEmpty)
        ...field.nestedFields!.map((nested) => {'label': nested.label, 'fieldId': nested.id})
      else ...[
        {'label': 'Name'},
        {'label': 'Value'},
      ],
    ]).take(3).toList();
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: RevoTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RevoTheme.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.view_week_outlined, size: 16, color: RevoTheme.primaryLight),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "${config['itemLabel'] ?? 'Item'} 1",
                  style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: RevoTheme.textPrimary),
                ),
              ),
              if (config['allowRemove'] != false) Icon(Icons.delete_outline_rounded, size: 14, color: Colors.redAccent),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: fields
                .map(
                  (item) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                      decoration: BoxDecoration(
                        color: RevoTheme.cardBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: RevoTheme.cardBorder),
                      ),
                      child: Text(item['label']?.toString() ?? 'Field', style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: RevoTheme.textSecondary), overflow: TextOverflow.ellipsis),
                    ),
                  ),
                )
                .toList(),
          ),
          if (config['allowAdd'] != false) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text("+ ${config['addButtonLabel'] ?? 'Add Item'}", style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: RevoTheme.primaryLight, fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelinePreview(JourneyField field) {
    final items = _configList(field, 'items', [
      {'title': 'Started', 'status': 'completed'},
      {'title': 'In Progress', 'status': 'active'},
      {'title': 'Completed', 'status': 'pending'},
    ]).take(4).toList();
    Color statusColor(String? status) {
      switch (status) {
        case 'completed':
          return RevoTheme.secondary;
        case 'active':
          return RevoTheme.primaryLight;
        case 'failed':
          return Colors.redAccent;
        default:
          return RevoTheme.textSecondary;
      }
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: RevoTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RevoTheme.cardBorder),
      ),
      child: Column(
        children: items.map((item) {
          final color = statusColor(item['status']?.toString());
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.circle, size: 10, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(item['title']?.toString() ?? 'Timeline item', style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: RevoTheme.textPrimary), overflow: TextOverflow.ellipsis),
                ),
                Text(item['status']?.toString() ?? 'pending', style: TextStyle(fontFamily: 'Inter', fontSize: 9, color: color)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 3,
      child: DragTarget<String>(
        onAcceptWithDetails: (details) {
          addField(ref, details.data);
        },
        builder: (context, candidateData, rejectedData) {
          final isOver = candidateData.isNotEmpty;

          return Container(
            color: isOver ? RevoTheme.primary.withValues(alpha:0.08) : RevoTheme.background,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.step.title,
                        style: const TextStyle(fontFamily: 'Outfit', fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.step.description.isNotEmpty ? widget.step.description : "Drag widgets here to build details",
                        style: TextStyle(fontFamily: 'Inter', color: RevoTheme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: widget.step.fields.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.art_track_rounded, size: 48, color: RevoTheme.cardBorder),
                              const SizedBox(height: 12),
                              Text(
                                "Drag tools here or click items to insert field",
                                style: TextStyle(fontFamily: 'Inter', color: RevoTheme.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      : Theme(
                          data: Theme.of(context).copyWith(canvasColor: Colors.transparent),
                          child: ReorderableListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: widget.step.fields.length,
                            onReorder: (oldIndex, newIndex) {
                              ref.read(journeyConfigProvider.notifier)
                                  .reorderFieldsInStep(widget.step.id, oldIndex, newIndex);
                            },
                            itemBuilder: (context, index) {
                              final field = widget.step.fields[index];
                              final isSelected = field.id == widget.selectedFieldId;

                              return InkWell(
                                key: ValueKey(field.id),
                                onTap: () {
                                  ref.read(selectedFieldIdProvider.notifier).state = field.id;
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: RevoTheme.cardBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: isSelected
                                        ? Border.all(color: RevoTheme.primary, width: 1.5)
                                        : Border.all(color: RevoTheme.cardBorder),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          ReorderableDragStartListener(
                                            index: index,
                                            child: Icon(Icons.drag_indicator_rounded, color: RevoTheme.textSecondary),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        field.label,
                                                        style: const TextStyle(fontFamily: 'Inter',
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    if (field.required)
                                                      const Text(" *", style: TextStyle(color: Colors.red)),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  field.placeholder ?? "No placeholder configured",
                                                  style: TextStyle(fontFamily: 'Inter',
                                                    fontSize: 12,
                                                    color: RevoTheme.textSecondary,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      _buildCanvasComponentPreview(field, widget.step.id),
                                      if (isSelected) ...[
                                        const SizedBox(height: 12),
                                        Divider(color: RevoTheme.cardBorder, height: 1),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: RevoTheme.primary.withValues(alpha:0.15),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: RevoTheme.primary.withValues(alpha:0.3)),
                                              ),
                                              child: Text(
                                                field.type.toUpperCase(),
                                                style: TextStyle(fontFamily: 'Inter',
                                                  fontSize: 9,
                                                  color: RevoTheme.primaryLight,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: Icon(Icons.copy_rounded, size: 16, color: RevoTheme.primaryLight),
                                                  onPressed: () => duplicateField(ref, field),
                                                  constraints: const BoxConstraints(),
                                                  padding: const EdgeInsets.all(8),
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                                                  onPressed: () {
                                                    ref.read(journeyConfigProvider.notifier)
                                                        .removeFieldFromStep(widget.step.id, field.id);
                                                  },
                                                  constraints: const BoxConstraints(),
                                                  padding: const EdgeInsets.all(8),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
