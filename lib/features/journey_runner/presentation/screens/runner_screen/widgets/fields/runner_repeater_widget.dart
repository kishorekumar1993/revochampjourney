import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:revojourneytryone/features/journey_builder/domain/entities/journey_models.dart';
import 'package:revojourneytryone/features/journey_builder/application/controllers/journey_controller.dart';
import 'package:revojourneytryone/features/journey_runner/presentation/screens/runner_screen/runner_theme.dart';

class RunnerRepeaterWidget extends ConsumerStatefulWidget {
  final JourneyField field;

  const RunnerRepeaterWidget({
    super.key,
    required this.field,
  });

  @override
  ConsumerState<RunnerRepeaterWidget> createState() => _RunnerRepeaterWidgetState();
}

class _RunnerRepeaterWidgetState extends ConsumerState<RunnerRepeaterWidget> {
  List<Map<String, dynamic>>? _localRows;

  @override
  void initState() {
    super.initState();
    _bootstrapRows();
  }

  void _bootstrapRows() {
    final nf = widget.field.nestedFields ?? <JourneyField>[];
    final val = ref.read(formValuesProvider)[widget.field.id];

    if (val != null && val is List) {
      try {
        _localRows = val.map((e) => Map<String, dynamic>.from(e)).toList();
        return;
      } catch (_) {}
    }

    _localRows = [_emptyRepRow(nf)];
    _syncFormState();
  }

  void _syncFormState() {
    if (_localRows != null) {
      ref.read(formValuesProvider.notifier).updateValue(
            widget.field.id,
            List<Map<String, dynamic>>.from(_localRows!),
          );
    }
  }

  Map<String, dynamic> _compConfig(JourneyField f) {
    final c = Map<String, dynamic>.from(f.componentConfig ?? {});
    return {
      'allowAdd': true,
      'allowRemove': true,
      'itemLabel': 'Item',
      'addButtonLabel': 'Add Item',
      'maxRows': 20,
      ...c,
    };
  }

  Map<String, dynamic> _emptyRepRow(List<JourneyField> fields) => {
        for (final f in fields) f.id: f.defaultValue ?? '',
      };

  void _addRow(List<JourneyField> nf) {
    setState(() {
      _localRows ??= [];
      _localRows!.add(_emptyRepRow(nf));
    });
    _syncFormState();
  }

  void _removeRow(int idx) {
    setState(() {
      if (_localRows != null && _localRows!.length > idx) {
        _localRows!.removeAt(idx);
      }
    });
    _syncFormState();
  }

  void _updateCell(int ri, String cfId, dynamic v) {
    setState(() {
      if (_localRows != null && _localRows!.length > ri) {
        _localRows![ri][cfId] = v;
      }
    });
    _syncFormState();
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _compConfig(widget.field);
    final nf = widget.field.nestedFields ?? <JourneyField>[];
    final allowAdd = cfg['allowAdd'] != false;
    final allowRem = cfg['allowRemove'] != false;
    final itemLabel = cfg['itemLabel']?.toString() ?? 'Item';
    final addLabel = cfg['addButtonLabel']?.toString() ?? 'Add $itemLabel';
    final maxR = int.tryParse(cfg['maxRows']?.toString() ?? '') ?? 20;

    final rows = _localRows ?? [];

    return Container(
      decoration: BoxDecoration(
        color: RunnerTheme.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: RunnerTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: const BoxDecoration(
              color: RunnerTheme.inputBg,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
              border: Border(bottom: BorderSide(color: RunnerTheme.border)),
            ),
            child: Text(
              widget.field.label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: RunnerTheme.textDark,
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
                          color: RunnerTheme.inputBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: RunnerTheme.border),
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
                                      color: RunnerTheme.textDark,
                                    ),
                                  ),
                                ),
                                if (allowRem && rows.length > 1)
                                  GestureDetector(
                                    onTap: () => _removeRow(e.key),
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: RunnerTheme.error.withValues(alpha: 0.08),
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
                                  child: _repCell(e.key, n, e.value),
                                ),
                              )
                            else
                              Text(
                                'No fields configured.',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: RunnerTheme.textLight,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                if (allowAdd && rows.length < maxR)
                  OutlinedButton.icon(
                    onPressed: () => _addRow(nf),
                    icon: const Icon(Icons.add_rounded, size: 13),
                    label: Text(
                      addLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: RunnerTheme.brand,
                      side: const BorderSide(color: RunnerTheme.brand),
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

  Widget _repCell(
    int ri,
    JourneyField cf,
    Map<String, dynamic> rv,
  ) {
    final cur = rv[cf.id]?.toString() ?? '';
    void upd(dynamic v) => _updateCell(ri, cf.id, v);

    switch (cf.type.toLowerCase()) {
      case 'dropdown':
        final opts = cf.getResolvedOptions();
        return DropdownButtonFormField<String>(
          initialValue: opts.contains(cur) ? cur : null,
          decoration: buildRunnerInputDecoration(label: cf.label, dense: true),
          dropdownColor: RunnerTheme.white,
          items: opts.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
          onChanged: (v) {
            if (v != null) upd(v);
          },
        );
      case 'checkbox':
      case 'switch':
        return CheckboxListTile(
          title: Text(cf.label, style: GoogleFonts.poppins(fontSize: 12)),
          value: cur == 'true',
          activeColor: RunnerTheme.brand,
          contentPadding: EdgeInsets.zero,
          onChanged: (v) => upd((v ?? false).toString()),
        );
      default:
        return TextFormField(
          initialValue: cur,
          decoration: buildRunnerInputDecoration(label: cf.label, dense: true),
          keyboardType: cf.type == 'number' ? TextInputType.number : TextInputType.text,
          style: GoogleFonts.poppins(fontSize: 12, color: RunnerTheme.textDark),
          onChanged: upd,
        );
    }
  }
}
