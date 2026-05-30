import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:revojourneytryone/features/journey_builder/domain/entities/journey_models.dart';
import 'package:revojourneytryone/features/journey_builder/application/controllers/journey_controller.dart';
import 'package:revojourneytryone/features/journey_runner/presentation/screens/runner_screen/runner_theme.dart';

class RunnerGridWidget extends ConsumerStatefulWidget {
  final JourneyField field;
  final Function(StringMsg, {bool isError}) showSnack;

  const RunnerGridWidget({
    super.key,
    required this.field,
    required this.showSnack,
  });

  @override
  ConsumerState<RunnerGridWidget> createState() => _RunnerGridWidgetState();
}

typedef StringMsg = String;

class _RunnerGridWidgetState extends ConsumerState<RunnerGridWidget> {
  List<Map<String, dynamic>>? _localRows;
  final Set<int> _gridSelections = {};
  String _gridSearch = '';
  String? _gridSortField;
  bool _gridSortAsc = true;
  bool _apiLoading = false;
  String? _apiError;

  @override
  void initState() {
    super.initState();
    _bootstrapRows();
  }

  void _bootstrapRows() {
    final cfg = _compConfig(widget.field);
    final cols = _getCols();
    final val = ref.read(formValuesProvider)[widget.field.id];

    if (val != null && val.toString().isNotEmpty) {
      try {
        final decoded = jsonDecode(val.toString());
        if (decoded is List) {
          _localRows = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
          return;
        }
      } catch (_) {}
    }

    final src = cfg['dataSource']?.toString() ?? 'manual';
    if (src == 'api') {
      _localRows = [];
      _loadGridApi(cols, cfg);
    } else {
      final min = int.tryParse(cfg['minRows']?.toString() ?? '') ?? 0;
      _localRows = List.generate(min > 0 ? min : 1, (_) => _emptyRow(cols));
      _syncFormState();
    }
  }

  void _syncFormState() {
    if (_localRows != null) {
      ref.read(formValuesProvider.notifier).updateValue(widget.field.id, jsonEncode(_localRows));
    }
  }

  Map<String, dynamic> _compConfig(JourneyField f) {
    final c = Map<String, dynamic>.from(f.componentConfig ?? {});
    return {
      'columns': const [
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
      'rowActions': const ['edit', 'delete'],
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
      'gridApiHeaders': const {},
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

  List<Map<String, dynamic>> _getCols() {
    final v = _compConfig(widget.field)['columns'];
    if (v is List) {
      final p = v
          .map((i) => i is Map ? Map<String, dynamic>.from(i) : <String, dynamic>{})
          .where((i) => i.isNotEmpty)
          .toList();
      if (p.isNotEmpty) return p;
    }
    if (widget.field.nestedFields != null && widget.field.nestedFields!.isNotEmpty) {
      return widget.field.nestedFields!
          .map((n) => {
                'label': n.label,
                'fieldId': n.id,
                'type': n.type,
                'required': n.required,
              })
          .toList();
    }
    return const [
      {'label': '#', 'fieldId': 'rowIndex'},
      {'label': 'Name', 'fieldId': 'name', 'required': true},
      {'label': 'Age', 'fieldId': 'age'},
    ];
  }

  Map<String, dynamic> _emptyRow(List<Map<String, dynamic>> cols) => {
        for (final c in cols) _colId(c): '',
      };

  String _colId(Map<String, dynamic> c) =>
      (c['fieldId'] ?? c['key'] ?? c['label'] ?? 'col').toString();

  Future<void> _loadGridApi(List<Map<String, dynamic>> cols, Map<String, dynamic> cfg, {bool force = false}) async {
    if (!force && _apiLoading) return;
    final url = cfg['gridApiUrl']?.toString().trim() ?? '';
    if (url.isEmpty) {
      setState(() {
        _apiError = 'Grid API URL required.';
      });
      return;
    }
    setState(() {
      _apiLoading = true;
      _apiError = null;
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
        _localRows = rows;
        _gridSelections.clear();
        _apiLoading = false;
      });
      _syncFormState();
    } catch (e) {
      setState(() {
        _apiLoading = false;
        _apiError = e.toString();
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
      for (final k in const ['data', 'items', 'results', 'rows']) {
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

  void _exportCsv(List<Map<String, dynamic>> cols) {
    final rows = _localRows ?? [];
    final hdrs = cols.map((c) => c['label']?.toString() ?? _colId(c)).toList();
    final keys = cols.map(_colId).toList();
    final csv = [
      hdrs.map(_esc).join(','),
      ...rows.map((r) => keys.map((k) => _esc(r[k]?.toString() ?? '')).join(',')),
    ].join('\n');
    Clipboard.setData(ClipboardData(text: csv));
    widget.showSnack('CSV copied to clipboard');
  }

  String _esc(String v) {
    final e = v.replaceAll('"', '""');
    return v.contains(',') || v.contains('"') || v.contains('\n') ? '"$e"' : e;
  }

  void _addRow(List<Map<String, dynamic>> cols) {
    setState(() {
      _localRows ??= [];
      _localRows!.add(_emptyRow(cols));
    });
    _syncFormState();
  }

  void _delRow(int ri) {
    setState(() {
      if (_localRows != null && ri >= 0 && ri < _localRows!.length) {
        _localRows!.removeAt(ri);
        _gridSelections.remove(ri);
      }
    });
    _syncFormState();
  }

  void _dupRow(List<Map<String, dynamic>> cols, Map<String, dynamic> row) {
    setState(() {
      _localRows ??= [];
      _localRows!.add({..._emptyRow(cols), ...row});
    });
    _syncFormState();
  }

  void _updCell(int ri, String fid, String v) {
    setState(() {
      if (_localRows != null && ri >= 0 && ri < _localRows!.length) {
        _localRows![ri][fid] = v;
      }
    });
    _syncFormState();
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _compConfig(widget.field);
    final cols = _getCols();
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
        ? List<String>.from((cfg['rowActions'] as List).map((i) => i.toString()))
        : const <String>['edit', 'delete'];
    final rpp = int.tryParse(cfg['rowsPerPage']?.toString() ?? '') ?? 10;
    final maxR = int.tryParse(cfg['maxRows']?.toString() ?? '') ?? 10;

    final rows = _localRows ?? [];
    var vis = rows.asMap().entries.where((e) {
      if (_gridSearch.trim().isEmpty) return true;
      final q = _gridSearch.toLowerCase();
      return e.value.values.any((v) => v.toString().toLowerCase().contains(q));
    }).toList();

    if (_gridSortField != null) {
      vis.sort((a, b) {
        final l = a.value[_gridSortField!]?.toString() ?? '';
        final r = b.value[_gridSortField!]?.toString() ?? '';
        return _gridSortAsc ? l.compareTo(r) : r.compareTo(l);
      });
    }

    final pgd = paged ? vis.take(rpp).toList() : vis;
    final srtIdx = _gridSortField == null ? -1 : cols.indexWhere((c) => _colId(c) == _gridSortField);

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
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.field.label,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: RunnerTheme.textDark,
                    ),
                  ),
                ),
                if (src == 'api')
                  IconButton(
                    tooltip: "Reload",
                    onPressed: _apiLoading ? null : () => _loadGridApi(cols, cfg, force: true),
                    icon: _apiLoading
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: RunnerTheme.brand,
                            ),
                          )
                        : const Icon(
                            Icons.refresh_rounded,
                            size: 17,
                            color: RunnerTheme.textMid,
                          ),
                  ),
                if (expCsv)
                  IconButton(
                    tooltip: "CSV",
                    onPressed: () => _exportCsv(cols),
                    icon: const Icon(
                      Icons.download_rounded,
                      size: 17,
                      color: RunnerTheme.textMid,
                    ),
                  ),
                if (allowAdd)
                  ElevatedButton.icon(
                    onPressed: rows.length >= maxR ? null : () => _addRow(cols),
                    icon: const Icon(Icons.add_rounded, size: 13),
                    label: Text(
                      "Add Row",
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RunnerTheme.brand,
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
          if (_apiError != null)
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                _apiError!,
                style: GoogleFonts.poppins(fontSize: 11, color: RunnerTheme.error),
              ),
            ),
          if (srch)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: TextField(
                decoration: buildRunnerInputDecoration(
                  label: '',
                  hint: 'Search rows...',
                  prefix: const Icon(
                    Icons.search_rounded,
                    size: 15,
                    color: RunnerTheme.textMid,
                  ),
                  dense: true,
                ),
                style: GoogleFonts.poppins(fontSize: 12),
                onChanged: (v) => setState(() => _gridSearch = v),
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(14),
            child: DataTable(
              showCheckboxColumn: bulk,
              headingRowColor: const WidgetStatePropertyAll(RunnerTheme.inputBg),
              headingTextStyle: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: RunnerTheme.textMid,
              ),
              dataTextStyle: GoogleFonts.poppins(
                fontSize: 12,
                color: RunnerTheme.textDark,
              ),
              dataRowMinHeight: 46,
              dataRowMaxHeight: 60,
              sortColumnIndex: srtIdx < 0 ? null : srtIdx,
              sortAscending: _gridSortAsc,
              columns: [
                ...cols.map(
                  (c) => DataColumn(
                    label: Text(c['label']?.toString() ?? 'Col'),
                    onSort: srtg
                        ? (_, asc) => setState(() {
                             _gridSortField = _colId(c);
                             _gridSortAsc = asc;
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
                      selected: _gridSelections.contains(e.key),
                      onSelectChanged: bulk
                          ? (c) => setState(() {
                                c == true ? _gridSelections.add(e.key) : _gridSelections.remove(e.key);
                              })
                          : null,
                      cells: [
                        ...cols.map(
                          (c) => DataCell(
                            _gridCell(c, e.value, e.key, inline, valid),
                          ),
                        ),
                        DataCell(
                          _gridActions(
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
                style: GoogleFonts.poppins(fontSize: 10, color: RunnerTheme.textLight),
              ),
            ),
        ],
      ),
    );
  }

  Widget _gridCell(
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
          color: err ? RunnerTheme.error : RunnerTheme.textMid,
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
          fillColor: RunnerTheme.inputBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: RunnerTheme.border),
          ),
        ),
        keyboardType: col['type'] == 'number' ? TextInputType.number : TextInputType.text,
        style: GoogleFonts.poppins(fontSize: 11, color: RunnerTheme.textDark),
        onChanged: (v) => _updCell(ri, fid, v),
      ),
    );
  }

  Widget _gridActions(
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
                    onPressed: () => _delRow(ri),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: Colors.redAccent,
                    ),
                  )
                : const SizedBox.shrink();
          case 'duplicate':
            return IconButton(
              onPressed: () => _dupRow(cols, row),
              icon: const Icon(
                Icons.copy_rounded,
                size: 14,
                color: RunnerTheme.textMid,
              ),
            );
          case 'edit':
            return const Icon(Icons.edit_outlined, size: 14, color: RunnerTheme.brand);
          default:
            return const SizedBox.shrink();
        }
      }).toList(),
    );
  }
}
