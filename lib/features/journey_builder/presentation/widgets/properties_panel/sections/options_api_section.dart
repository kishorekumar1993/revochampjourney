import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/features/journey_builder/domain/entities/journey_models.dart';
import 'package:revojourneytryone/features/journey_builder/application/controllers/journey_controller.dart';
import '../property_fields.dart';

class OptionsApiSection extends ConsumerStatefulWidget {
  final JourneyField field;
  final String activeStepId;

  const OptionsApiSection({
    super.key,
    required this.field,
    required this.activeStepId,
  });

  @override
  ConsumerState<OptionsApiSection> createState() => _OptionsApiSectionState();
}

class _OptionsApiSectionState extends ConsumerState<OptionsApiSection> {
  bool _showDataOptions = false;
  int _apiTabIndex = 0;
  String? _headersError;
  String? _testDataError;
  bool _testingDropdownApi = false;
  String? _dropdownApiTestResult;
  bool _dropdownApiTestSuccess = false;

  String? _validateJsonMap(String val) {
    if (val.trim().isEmpty) return null;
    try {
      final decoded = json.decode(val);
      if (decoded is! Map) return "Must be a valid JSON Object (e.g. {\"key\": \"value\"})";
      return null;
    } catch (e) {
      return "Invalid JSON syntax: ${e.toString()}";
    }
  }

  String? _validateJsonResponseData(String val) {
    if (val.trim().isEmpty) return null;
    try {
      final decoded = json.decode(val);
      if (decoded is! List && decoded is! Map) {
        return "Must be a valid JSON Array or Object response.";
      }
      return null;
    } catch (e) {
      return "Invalid JSON syntax: ${e.toString()}";
    }
  }

  Widget _buildDataSourceSelector(JourneyField field, String activeStepId) {
    final useStatic = field.useStaticOptions;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: RevoTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RevoTheme.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                final updated = field.copyWith()..useStaticOptions = true;
                ref.read(journeyConfigProvider.notifier)
                    .updateFieldInStep(activeStepId, field.id, updated);
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: useStatic ? RevoTheme.primary.withValues(alpha: 0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: useStatic ? RevoTheme.primaryLight.withValues(alpha: 0.5) : Colors.transparent,
                  ),
                ),
                child: Center(
                  child: Text(
                    "Static Options",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: useStatic ? RevoTheme.primaryLight : RevoTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                final updated = field.copyWith()..useStaticOptions = false;
                ref.read(journeyConfigProvider.notifier)
                    .updateFieldInStep(activeStepId, field.id, updated);
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: !useStatic ? RevoTheme.primary.withValues(alpha: 0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: !useStatic ? RevoTheme.primaryLight.withValues(alpha: 0.5) : Colors.transparent,
                  ),
                ),
                child: Center(
                  child: Text(
                    "API Integration",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: !useStatic ? RevoTheme.primaryLight : RevoTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaticOptionsList(JourneyField field, String activeStepId) {
    final options = field.staticOptions ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Static Options Builder",
          style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.bold, color: RevoTheme.textSecondary),
        ),
        const SizedBox(height: 6),
        ...options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final keyStr = option['key'] ?? '';
          final valStr = option['value'] ?? '';

          return Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: PropertyTextField(
                    label: "Key",
                    initialValue: keyStr,
                    onChanged: (newKey) {
                      final updatedList = List<Map<String, String>>.from(options);
                      updatedList[index] = {'key': newKey.trim(), 'value': valStr};
                      final updated = field.copyWith()..staticOptions = updatedList;
                      ref.read(journeyConfigProvider.notifier)
                          .updateFieldInStep(activeStepId, field.id, updated);
                    },
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 5,
                  child: PropertyTextField(
                    label: "Value",
                    initialValue: valStr,
                    onChanged: (newVal) {
                      final updatedList = List<Map<String, String>>.from(options);
                      updatedList[index] = {'key': keyStr, 'value': newVal};
                      final updated = field.copyWith()..staticOptions = updatedList;
                      ref.read(journeyConfigProvider.notifier)
                          .updateFieldInStep(activeStepId, field.id, updated);
                    },
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                    onPressed: () {
                      final updatedList = List<Map<String, String>>.from(options)..removeAt(index);
                      final updated = field.copyWith()..staticOptions = updatedList;
                      ref.read(journeyConfigProvider.notifier)
                          .updateFieldInStep(activeStepId, field.id, updated);
                    },
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 6),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: RevoTheme.cardBg,
            minimumSize: const Size(double.infinity, 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: RevoTheme.cardBorder),
            ),
          ),
          onPressed: () {
            final updatedList = List<Map<String, String>>.from(options);
            final newIdx = updatedList.length + 1;
            updatedList.add({'key': newIdx.toString(), 'value': 'Option $newIdx'});
            final updated = field.copyWith()..staticOptions = updatedList;
            ref.read(journeyConfigProvider.notifier)
                .updateFieldInStep(activeStepId, field.id, updated);
          },
          icon: const Icon(Icons.add_rounded, size: 12),
          label: const Text("Add New Option", style: TextStyle(fontFamily: 'Inter', fontSize: 10)),
        ),
      ],
    );
  }

  Widget _buildApiTabBar() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: RevoTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RevoTheme.cardBorder),
      ),
      child: Row(
        children: [
          _buildApiTabButton("Endpoint", 0),
          _buildApiTabButton("Payload", 1),
          _buildApiTabButton("Response Map", 2),
        ],
      ),
    );
  }

  Widget _buildApiTabButton(String label, int index) {
    final isSelected = _apiTabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _apiTabIndex = index),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? RevoTheme.primary.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? RevoTheme.primaryLight.withValues(alpha: 0.3) : Colors.transparent,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: isSelected ? RevoTheme.primaryLight : RevoTheme.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMethodSelector(JourneyField field, String activeStepId) {
    final methods = ["GET", "POST", "PUT", "DELETE"];
    final currentMethod = field.dropdownApiMethod ?? "GET";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("API HTTP Method", style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: RevoTheme.textSecondary)),
        const SizedBox(height: 4),
        Row(
          children: methods.map((method) {
            final isSelected = currentMethod.toUpperCase() == method;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: InkWell(
                  onTap: () {
                    final updated = field.copyWith()..dropdownApiMethod = method;
                    ref.read(journeyConfigProvider.notifier)
                        .updateFieldInStep(activeStepId, field.id, updated);
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? RevoTheme.primary.withValues(alpha: 0.15) : RevoTheme.background,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected ? RevoTheme.primaryLight : RevoTheme.cardBorder,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        method,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? RevoTheme.primaryLight : RevoTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildResponsePreview(JourneyField field) {
    final data = field.dropdowndata;
    final displayKey = field.dropdownValue ?? 'title';

    if (data == null || data.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: RevoTheme.background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: RevoTheme.cardBorder),
        ),
        child: Text(
          "Enter mock/test response JSON array in the field above to see live dropdown parse preview.",
          style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: RevoTheme.textSecondary, fontStyle: FontStyle.italic),
        ),
      );
    }

    try {
      final parsedOptions = field.getResolvedOptions();
      if (parsedOptions.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.orangeAccent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.25)),
          ),
          child: Text(
            "Parsed 0 options. Double-check if the Display Key '$displayKey' matches properties in your JSON.",
            style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: Colors.orangeAccent),
          ),
        );
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.greenAccent.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 12),
                const SizedBox(width: 4),
                Text(
                  "Parsed ${parsedOptions.length} option(s) successfully:",
                  style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: Colors.greenAccent, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: parsedOptions.map((opt) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: RevoTheme.background,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: RevoTheme.cardBorder),
                  ),
                  child: Text(
                    opt,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 9, color: Colors.white70),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    } catch (e) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.25)),
        ),
        child: Text(
          "Parsing error: ${e.toString()}",
          style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: Colors.redAccent),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CollapsibleSection(
      title: "Options & API Config",
      accentColor: RevoTheme.accent,
      icon: Icons.api_rounded,
      isExpanded: _showDataOptions,
      onToggle: () => setState(() => _showDataOptions = !_showDataOptions),
      children: [
        _buildDataSourceSelector(widget.field, widget.activeStepId),
        if (widget.field.useStaticOptions) ...[
          _buildStaticOptionsList(widget.field, widget.activeStepId),
        ] else ...[
          _buildApiTabBar(),
          if (_apiTabIndex == 0) ...[
            PropertyTextField(
              label: "API URL Path",
              initialValue: widget.field.dropdownApiUrl ?? '',
              hint: "https://api.example.com/dropdown-data",
              onChanged: (val) {
                final updated = widget.field.copyWith()..dropdownApiUrl = val.trim().isEmpty ? null : val.trim();
                ref.read(journeyConfigProvider.notifier)
                    .updateFieldInStep(widget.activeStepId, widget.field.id, updated);
              },
            ),
            const SizedBox(height: 10),
            _buildMethodSelector(widget.field, widget.activeStepId),
            const SizedBox(height: 10),
            PropertyTextField(
              label: "URL / Query Parameter Key",
              initialValue: widget.field.apiParam ?? '',
              hint: "e.g. tenantId or searchKey",
              onChanged: (val) {
                final updated = widget.field.copyWith()..apiParam = val.trim().isEmpty ? null : val.trim();
                ref.read(journeyConfigProvider.notifier)
                    .updateFieldInStep(widget.activeStepId, widget.field.id, updated);
              },
            ),
          ] else if (_apiTabIndex == 1) ...[
            PropertyTextField(
              label: "API Headers (JSON Map)",
              initialValue: widget.field.dropdownApiHeaders != null ? json.encode(widget.field.dropdownApiHeaders) : '',
              hint: '{"Authorization": "Bearer token", "Accept": "application/json"}',
              maxLines: 3,
              onChanged: (val) {
                setState(() {
                  _headersError = _validateJsonMap(val);
                });
                if (_headersError == null) {
                  try {
                    if (val.trim().isEmpty) {
                      final updated = widget.field.copyWith()..dropdownApiHeaders = null;
                      ref.read(journeyConfigProvider.notifier)
                          .updateFieldInStep(widget.activeStepId, widget.field.id, updated);
                    } else {
                      final decoded = json.decode(val);
                      if (decoded is Map) {
                        final updatedMap = Map<String, dynamic>.from(decoded);
                        final updated = widget.field.copyWith()..dropdownApiHeaders = updatedMap;
                        ref.read(journeyConfigProvider.notifier)
                            .updateFieldInStep(widget.activeStepId, widget.field.id, updated);
                      }
                    }
                  } catch (_) {}
                }
              },
            ),
            if (_headersError != null) ...[
              const SizedBox(height: 4),
              Text(_headersError!, style: const TextStyle(fontFamily: 'Inter', color: Colors.redAccent, fontSize: 10)),
            ],
            const SizedBox(height: 10),
            PropertyTextField(
              label: "Request Body (JSON String)",
              initialValue: widget.field.dropdownApiBody ?? '',
              hint: '{"status": "active", "filter": "users"}',
              maxLines: 3,
              onChanged: (val) {
                final updated = widget.field.copyWith()..dropdownApiBody = val.trim().isEmpty ? null : val.trim();
                ref.read(journeyConfigProvider.notifier)
                    .updateFieldInStep(widget.activeStepId, widget.field.id, updated);
              },
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: PropertyTextField(
                    label: "Value Key",
                    initialValue: widget.field.dropdownkey ?? 'id',
                    hint: "e.g. id, code",
                    onChanged: (val) {
                      final updated = widget.field.copyWith()..dropdownkey = val.trim().isEmpty ? null : val.trim();
                      ref.read(journeyConfigProvider.notifier)
                          .updateFieldInStep(widget.activeStepId, widget.field.id, updated);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PropertyTextField(
                    label: "Display Value Key",
                    initialValue: widget.field.dropdownValue ?? 'title',
                    hint: "e.g. title, name",
                    onChanged: (val) {
                      final updated = widget.field.copyWith()..dropdownValue = val.trim().isEmpty ? null : val.trim();
                      ref.read(journeyConfigProvider.notifier)
                          .updateFieldInStep(widget.activeStepId, widget.field.id, updated);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            PropertyTextField(
              label: "List Key (optional)",
              initialValue: widget.field.dropdownListKey ?? '',
              hint: "e.g. data.items, result",
              onChanged: (val) {
                final updated = widget.field.copyWith()..dropdownListKey = val.trim().isEmpty ? null : val.trim();
                ref.read(journeyConfigProvider.notifier)
                    .updateFieldInStep(widget.activeStepId, widget.field.id, updated);
              },
            ),
            const SizedBox(height: 10),
            PropertyTextField(
              label: "Response JSON Data (Test/Preloaded)",
              initialValue: widget.field.dropdowndata != null ? json.encode(widget.field.dropdowndata) : '',
              hint: '[{"id": 1, "title": "Option One"}, {"id": 2, "title": "Option Two"}]',
              maxLines: 4,
              onChanged: (val) {
                setState(() {
                  _testDataError = _validateJsonResponseData(val);
                });
                if (_testDataError == null) {
                  try {
                    if (val.trim().isEmpty) {
                      final updated = widget.field.copyWith()..dropdowndata = null;
                      ref.read(journeyConfigProvider.notifier)
                          .updateFieldInStep(widget.activeStepId, widget.field.id, updated);
                    } else {
                      final decoded = json.decode(val);
                      if (decoded is List) {
                        final updatedList = decoded.map((item) {
                          return item is Map ? Map<String, dynamic>.from(item) : item;
                        }).toList();
                        final updated = widget.field.copyWith()..dropdowndata = updatedList;
                        ref.read(journeyConfigProvider.notifier)
                            .updateFieldInStep(widget.activeStepId, widget.field.id, updated);
                      } else if (decoded is Map) {
                        final updatedMap = Map<String, dynamic>.from(decoded);
                        final updated = widget.field.copyWith()..dropdowndata = updatedMap;
                        ref.read(journeyConfigProvider.notifier)
                            .updateFieldInStep(widget.activeStepId, widget.field.id, updated);
                      }
                    }
                  } catch (_) {}
                }
              },
            ),
            if (_testDataError != null) ...[
              const SizedBox(height: 4),
              Text(_testDataError!, style: const TextStyle(fontFamily: 'Inter', color: Colors.redAccent, fontSize: 10)),
            ],
            const SizedBox(height: 10),
            Text(
              "Live Response Parsing Preview:",
              style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.bold, color: RevoTheme.textSecondary),
            ),
            const SizedBox(height: 6),
            _buildResponsePreview(widget.field),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RevoTheme.cardBg,
                    foregroundColor: RevoTheme.textPrimary,
                    side: BorderSide(color: RevoTheme.primaryLight.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _testingDropdownApi ? null : () async {
                    setState(() {
                      _testingDropdownApi = true;
                      _dropdownApiTestResult = null;
                    });

                    final hasUrl = widget.field.dropdownApiUrl != null && widget.field.dropdownApiUrl!.isNotEmpty;
                    if (!hasUrl) {
                      setState(() {
                        _testingDropdownApi = false;
                        _dropdownApiTestSuccess = false;
                        _dropdownApiTestResult = "Error: API URL Path is required to test.";
                      });
                      return;
                    }

                    try {
                      final url = Uri.parse(widget.field.dropdownApiUrl!);
                      final method = (widget.field.dropdownApiMethod ?? 'GET').toUpperCase();

                      final Map<String, String> headers = {};
                      if (widget.field.dropdownApiHeaders != null) {
                        widget.field.dropdownApiHeaders!.forEach((k, v) {
                          headers[k] = v.toString();
                        });
                      }
                      if (!headers.containsKey('Content-Type') && method != 'GET') {
                        headers['Content-Type'] = 'application/json';
                      }

                      final body = widget.field.dropdownApiBody;

                      http.Response response;
                      if (method == 'POST') {
                        response = await http.post(url, headers: headers, body: body).timeout(const Duration(seconds: 15));
                      } else if (method == 'PUT') {
                        response = await http.put(url, headers: headers, body: body).timeout(const Duration(seconds: 15));
                      } else if (method == 'DELETE') {
                        response = await http.delete(url, headers: headers, body: body).timeout(const Duration(seconds: 15));
                      } else {
                        response = await http.get(url, headers: headers).timeout(const Duration(seconds: 15));
                      }

                      if (!mounted) return;

                      if (response.statusCode >= 200 && response.statusCode < 300) {
                        final decoded = json.decode(response.body);

                        dynamic normalizedData;
                        if (decoded is List) {
                          normalizedData = decoded.map((e) => e is Map ? Map<String, dynamic>.from(e) : e).toList();
                        } else if (decoded is Map) {
                          normalizedData = Map<String, dynamic>.from(decoded);
                        } else {
                          normalizedData = decoded;
                        }

                        final updated = widget.field.copyWith()..dropdowndata = normalizedData;
                        ref.read(journeyConfigProvider.notifier)
                            .updateFieldInStep(widget.activeStepId, widget.field.id, updated);

                        final options = updated.getResolvedOptions();
                        setState(() {
                          _testingDropdownApi = false;
                          _dropdownApiTestSuccess = true;
                          _dropdownApiTestResult = "Connection successful!\nStatus: ${response.statusCode}\nParsed ${options.length} option(s) successfully and saved to state.";
                        });
                      } else {
                        setState(() {
                          _testingDropdownApi = false;
                          _dropdownApiTestSuccess = false;
                          _dropdownApiTestResult = "HTTP Error: Status ${response.statusCode}\nResponse: ${response.body}";
                        });
                      }
                    } catch (e) {
                      if (!mounted) return;
                      setState(() {
                        _testingDropdownApi = false;
                        _dropdownApiTestSuccess = false;
                        _dropdownApiTestResult = "API Test failed: ${e.toString()}";
                      });
                    }
                  },
                  icon: _testingDropdownApi
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.bolt_rounded, size: 14),
                  label: const Text("Test Connection", style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RevoTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("API config for '${widget.field.label}' saved successfully!"),
                        backgroundColor: RevoTheme.secondary,
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 14),
                  label: const Text("Submit Config", style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          if (_dropdownApiTestResult != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _dropdownApiTestSuccess
                    ? Colors.greenAccent.withValues(alpha: 0.08)
                    : Colors.redAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _dropdownApiTestSuccess
                      ? Colors.greenAccent.withValues(alpha: 0.3)
                      : Colors.redAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                _dropdownApiTestResult!,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  color: _dropdownApiTestSuccess ? Colors.greenAccent : Colors.redAccent,
                  height: 1.4,
                ),
              ),
            ),
          ]
        ],
      ],
    );
  }
}
