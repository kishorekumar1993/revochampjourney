import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/features/journey_builder/domain/entities/journey_models.dart';
import 'package:revojourneytryone/features/journey_builder/application/controllers/journey_controller.dart';
import '../canvas_fields.dart';

class ApiTabSection extends ConsumerStatefulWidget {
  final JourneyStep step;

  const ApiTabSection({
    super.key,
    required this.step,
  });

  @override
  ConsumerState<ApiTabSection> createState() => _ApiTabSectionState();
}

class _ApiTabSectionState extends ConsumerState<ApiTabSection> {
  bool _testingStepApi = false;
  int? _testingStepApiIndex;
  String? _stepApiTestResult;
  bool _stepApiTestSuccess = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: RevoTheme.background,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Step API Integrations",
                    style: TextStyle(fontFamily: 'Outfit', fontSize: 20, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Configure background REST API actions executed on step initialization or submit.",
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: RevoTheme.textSecondary),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: RevoTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onPressed: () {
                  final newApi = StepAPI(
                    method: "GET",
                    url: "",
                    description: "New Step API Call",
                  );
                  ref.read(journeyConfigProvider.notifier).addApiCallToStep(widget.step.id, newApi);
                },
                icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                label: const Text("Add API Call"),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: widget.step.apiCalls.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.api_rounded, size: 48, color: RevoTheme.textSecondary.withValues(alpha:0.4)),
                        const SizedBox(height: 12),
                        Text(
                          "No background API calls configured for this step.",
                          style: TextStyle(fontFamily: 'Inter', color: RevoTheme.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: widget.step.apiCalls.length,
                    itemBuilder: (context, index) {
                      final api = widget.step.apiCalls[index];
                      final isTestingThis = _testingStepApi && _testingStepApiIndex == index;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: RevoTheme.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: RevoTheme.cardBorder, width: 1.2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "API Call #${index + 1}",
                                  style: TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.bold, color: RevoTheme.primaryLight),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                  onPressed: () {
                                    ref.read(journeyConfigProvider.notifier).removeApiCallFromStep(widget.step.id, index);
                                  },
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                // 1. Method selector
                                Expanded(
                                  flex: 2,
                                  child: CanvasDropdownField(
                                    label: "Method",
                                    value: api.method,
                                    items: const ["GET", "POST", "PUT", "DELETE"],
                                    fallback: "GET",
                                    onChanged: (val) {
                                      ref.read(journeyConfigProvider.notifier)
                                          .updateApiCallInStep(widget.step.id, index, api.copyWith(method: val));
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // 2. URL
                                Expanded(
                                  flex: 6,
                                  child: CanvasTextField(
                                    label: "Endpoint URL Path",
                                    initialValue: api.url,
                                    hint: "e.g. /api/v1/user/details or https://api.endpoint.com",
                                    onChanged: (val) {
                                      ref.read(journeyConfigProvider.notifier)
                                          .updateApiCallInStep(widget.step.id, index, api.copyWith(url: val.trim()));
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // 3. Description
                                Expanded(
                                  flex: 4,
                                  child: CanvasTextField(
                                    label: "Description / Action Label",
                                    initialValue: api.description,
                                    hint: "e.g. Fetch user balance",
                                    onChanged: (val) {
                                      ref.read(journeyConfigProvider.notifier)
                                          .updateApiCallInStep(widget.step.id, index, api.copyWith(description: val.trim()));
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: CanvasTextField(
                                    label: "Request Headers (JSON Map format)",
                                    initialValue: api.headers != null ? json.encode(api.headers) : "",
                                    hint: 'e.g. {"Authorization": "Bearer ..."}',
                                    onChanged: (val) {
                                      try {
                                        Map<String, dynamic>? newHeaders;
                                        if (val.trim().isEmpty) {
                                          newHeaders = null;
                                        } else {
                                          final decoded = json.decode(val);
                                          if (decoded is Map) newHeaders = Map<String, dynamic>.from(decoded);
                                        }
                                        ref.read(journeyConfigProvider.notifier)
                                            .updateApiCallInStep(widget.step.id, index, api.copyWith(headers: newHeaders));
                                      } catch (_) {}
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: CanvasTextField(
                                    label: "Request Body Payload (JSON string)",
                                    initialValue: api.body ?? "",
                                    hint: 'e.g. {"userId": 123}',
                                    onChanged: (val) {
                                      ref.read(journeyConfigProvider.notifier)
                                          .updateApiCallInStep(widget.step.id, index, api.copyWith(body: val.trim().isEmpty ? null : val.trim()));
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: RevoTheme.cardBg,
                                    foregroundColor: RevoTheme.textPrimary,
                                    side: BorderSide(color: RevoTheme.primaryLight.withValues(alpha:0.4)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  ),
                                  onPressed: isTestingThis ? null : () async {
                                    setState(() {
                                      _testingStepApi = true;
                                      _testingStepApiIndex = index;
                                      _stepApiTestResult = null;
                                    });

                                    if (api.url.isEmpty) {
                                      setState(() {
                                        _testingStepApi = false;
                                        _stepApiTestSuccess = false;
                                        _stepApiTestResult = "Error: Endpoint URL Path is required to test.";
                                      });
                                      return;
                                    }

                                    try {
                                      final headersStr = api.headers?.map((k, v) => MapEntry(k.toString(), v.toString())) ?? <String, String>{};
                                      final method = api.method.toUpperCase();
                                      final uri = Uri.parse(api.url);

                                      http.Response response;
                                      if (method == 'POST') {
                                        response = await http.post(uri, headers: headersStr, body: api.body).timeout(const Duration(seconds: 15));
                                      } else if (method == 'PUT') {
                                        response = await http.put(uri, headers: headersStr, body: api.body).timeout(const Duration(seconds: 15));
                                      } else if (method == 'DELETE') {
                                        response = await http.delete(uri, headers: headersStr, body: api.body).timeout(const Duration(seconds: 15));
                                      } else {
                                        response = await http.get(uri, headers: headersStr).timeout(const Duration(seconds: 15));
                                      }

                                      if (!mounted) return;

                                      final responseBody = response.body.length > 200
                                          ? '${response.body.substring(0, 200)}...'
                                          : response.body;

                                      setState(() {
                                        _testingStepApi = false;
                                        _stepApiTestSuccess = response.statusCode >= 200 && response.statusCode < 300;
                                        _stepApiTestResult = "Status: ${response.statusCode} ${response.reasonPhrase}\nResponse:\n$responseBody";
                                      });
                                    } catch (e) {
                                      if (!mounted) return;
                                      setState(() {
                                        _testingStepApi = false;
                                        _stepApiTestSuccess = false;
                                        _stepApiTestResult = "Error: Failed to connect.\n${e.toString()}";
                                      });
                                    }
                                  },
                                  icon: isTestingThis
                                      ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Icon(Icons.bolt_rounded, size: 14),
                                  label: const Text("Test Connection", style: TextStyle(fontFamily: 'Inter', fontSize: 11)),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: RevoTheme.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  ),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Step API #${index + 1} Configuration saved!"),
                                        backgroundColor: RevoTheme.secondary,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.check_circle_outline_rounded, size: 14),
                                  label: const Text("Submit Configuration", style: TextStyle(fontFamily: 'Inter', fontSize: 11)),
                                ),
                              ],
                            ),
                            if (_stepApiTestResult != null && _testingStepApiIndex == index) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: RevoTheme.background,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: _stepApiTestSuccess
                                        ? RevoTheme.success.withValues(alpha:0.3)
                                        : RevoTheme.error.withValues(alpha:0.3),
                                  ),
                                ),
                                child: Text(
                                  _stepApiTestResult!,
                                  style: TextStyle(fontFamily: 'Inter',
                                    fontSize: 10,
                                    color: _stepApiTestSuccess ? Colors.greenAccent : Colors.redAccent,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
