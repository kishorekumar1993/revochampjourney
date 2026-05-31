import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/features/journey_builder/domain/entities/journey_models.dart';
import 'package:revojourneytryone/features/journey_builder/application/controllers/journey_controller.dart';
import '../property_fields.dart';
import 'options_api/static_options_builder.dart';
import 'options_api/api_integration_builder.dart';
import 'options_api/response_parser_preview.dart';

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
          StaticOptionsBuilder(field: widget.field, activeStepId: widget.activeStepId),
        ] else ...[
          _buildApiTabBar(),
          if (_apiTabIndex < 2) ...[
            ApiIntegrationBuilder(
              field: widget.field,
              activeStepId: widget.activeStepId,
              apiTabIndex: _apiTabIndex,
              headersError: _headersError,
              onHeadersErrorChanged: (val) => setState(() => _headersError = val),
            ),
          ] else ...[
            ResponseParserPreview(
              field: widget.field,
              activeStepId: widget.activeStepId,
              testDataError: _testDataError,
              onTestDataErrorChanged: (val) => setState(() => _testDataError = val),
            ),
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
