import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:revojourneytryone/features/journey_builder/domain/entities/journey_models.dart';
import 'package:revojourneytryone/features/journey_runner/presentation/screens/runner_screen/runner_theme.dart';

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
  ConsumerState<ApiDropdownWidget> createState() => _ApiDropdownState();
}

class _ApiDropdownState extends ConsumerState<ApiDropdownWidget> {
  List<String> _opts = [];
  bool _loading = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void didUpdateWidget(ApiDropdownWidget old) {
    super.didUpdateWidget(old);
    if (old.field.dropdownApiUrl != widget.field.dropdownApiUrl) _fetch();
  }

  Future<void> _fetch() async {
    final url = widget.field.dropdownApiUrl;
    if (url == null || url.trim().isEmpty) {
      setState(() {
        _opts = widget.field.options ?? ["Select"];
        _loading = false;
        _err = "No API URL";
      });
      return;
    }
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final res = await http.get(Uri.parse(url.trim())).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final dec = json.decode(res.body);
        final List<String> out = [];
        void ext(dynamic data) {
          if (data is! List) return;
          final dk = widget.field.dropdownValue ?? 'title';
          for (var item in data) {
            if (item is String) {
              out.add(item);
            } else if (item is num || item is bool) {
              out.add(item.toString());
            } else if (item is Map) {
              if (item[dk] != null) {
                out.add(item[dk].toString());
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
                String? f;
                for (var k in keys) {
                  if (item[k] != null) {
                    f = item[k].toString();
                    break;
                  }
                }
                f ??= item.isNotEmpty ? item.values.first.toString() : null;
                if (f != null) out.add(f);
              }
            }
          }
        }

        if (dec is List) {
          ext(dec);
        } else if (dec is Map) {
          final rk = widget.field.dropdownApiResponseKey;
          bool found = false;
          if (rk != null && rk.isNotEmpty && dec[rk] is List) {
            ext(dec[rk]);
            found = true;
          }
          if (!found) {
            for (var k in const ['data', 'results', 'items', 'users', 'options']) {
              if (dec[k] is List) {
                ext(dec[k]);
                found = true;
                break;
              }
            }
          }
          if (!found) {
            for (var v in dec.values) {
              if (v is List) {
                ext(v);
                found = true;
                break;
              }
            }
          }
          if (!found) _err = "List not found in response";
        }
        if (out.isEmpty && _err == null) _err = "No options found";
        setState(() {
          _opts = out.isNotEmpty ? out : ["Select"];
          _loading = false;
        });
      } else {
        setState(() {
          _err = "HTTP ${res.statusCode}";
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _err = "Connection failed";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: _opts.contains(widget.initialValue) ? widget.initialValue : null,
      decoration: buildRunnerInputDecoration(
        label: widget.field.label,
        hint: widget.field.placeholder ?? "Select option",
        error: (_err ?? widget.errorText),
        suffix: _loading
            ? const Padding(
                padding: EdgeInsets.all(13),
                child: SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(RunnerTheme.brand),
                  ),
                ),
              )
            : _err != null
                ? IconButton(
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.amber,
                      size: 18,
                    ),
                    onPressed: _fetch,
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  )
                : null,
      ),
      style: GoogleFonts.poppins(fontSize: 13, color: RunnerTheme.textDark),
      dropdownColor: RunnerTheme.white,
      borderRadius: BorderRadius.circular(14),
      items: _opts.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
      onChanged: _loading
          ? null
          : (v) {
              if (v != null) widget.onChanged(v);
            },
    );
  }
}
