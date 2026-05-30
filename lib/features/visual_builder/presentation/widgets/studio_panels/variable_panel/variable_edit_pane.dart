import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/core/component_engine/models/app_variable.dart';
import 'package:revojourneytryone/features/visual_builder/application/studio_providers.dart';
import '../studio_panel_wrapper.dart';

final variableChangeLogsProvider = StateProvider<List<Map<String, dynamic>>>((ref) => []);

class VariableEditPane extends ConsumerWidget {
  final AppVariable variable;

  const VariableEditPane({super.key, required this.variable});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(appVariablesProvider.notifier);
    final v = variable;

    return SizedBox(
      width: 300,
      child: RevoStudioPanelWrapper(
        title: "Edit Variable",
        subtitle: v.name,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            onPressed: () {
              ref.read(selectedVariableIdProvider.notifier).state = null;
            },
          ),
        ],
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTextField(
              label: "Variable Name",
              value: v.name,
              onChanged: (val) {
                final upd = v.copyWith(name: val);
                notifier.updateVariable(v.id, upd);
              },
            ),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: "Data Type",
                    value: v.type,
                    options: const ['String', 'int', 'double', 'bool', 'List', 'Map'],
                    onChanged: (val) {
                      final upd = v.copyWith(type: val ?? 'String');
                      notifier.updateVariable(v.id, upd);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDropdown(
                    label: "Variable Scope",
                    value: v.scope.toString().split('.').last,
                    options: const ['app', 'page', 'component', 'session'],
                    onChanged: (val) {
                      final sc = VariableScope.values.firstWhere((e) => e.toString().split('.').last == val);
                      final upd = v.copyWith(scope: sc);
                      notifier.updateVariable(v.id, upd);
                    },
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text("Value Settings", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: RevoTheme.textSecondary)),
            const SizedBox(height: 8),
            _buildTextField(
              label: "Default Value",
              value: (v.defaultValue ?? '').toString(),
              onChanged: (val) {
                final dynamic typedVal = _parseTypedValue(val, v.type);
                final upd = v.copyWith(defaultValue: typedVal);
                notifier.updateVariable(v.id, upd);
              },
            ),
            _buildTextField(
              label: "Current Value",
              value: (v.currentValue ?? '').toString(),
              onChanged: (val) {
                final dynamic typedVal = _parseTypedValue(val, v.type);
                ref.read(variableChangeLogsProvider.notifier).update((state) => [
                  {
                    'name': v.name,
                    'old': v.currentValue,
                    'new': typedVal,
                    'time': DateTime.now(),
                  },
                  ...state,
                ]);
                final upd = v.copyWith(currentValue: typedVal);
                notifier.updateVariable(v.id, upd);
              },
            ),
            SwitchListTile(
              title: Text("Secret / Masked", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: RevoTheme.textPrimary)),
              subtitle: Text("Hide value in logs and inspector", style: GoogleFonts.inter(fontSize: 9, color: RevoTheme.textSecondary)),
              value: v.isSecret,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) {
                final upd = v.copyWith(isSecret: val);
                notifier.updateVariable(v.id, upd);
              },
            ),
            SwitchListTile(
              title: Text("Computed Variable", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: RevoTheme.textPrimary)),
              value: v.isComputed,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) {
                final upd = v.copyWith(isComputed: val);
                notifier.updateVariable(v.id, upd);
              },
            ),
            if (v.isComputed) ...[
              _buildTextField(
                label: "Formula Expression",
                value: v.computedExpression,
                onChanged: (val) {
                  final upd = v.copyWith(computedExpression: val);
                  notifier.updateVariable(v.id, upd);
                },
              ),
            ],
            const Divider(height: 24),
            ExpansionTile(
              title: Text("Validation Rules", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
              tilePadding: EdgeInsets.zero,
              children: [
                SwitchListTile(
                  title: Text("Value Required", style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textPrimary)),
                  value: v.validationRequired,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    final upd = v.copyWith(validationRequired: val);
                    notifier.updateVariable(v.id, upd);
                  },
                ),
                if (v.type == 'int' || v.type == 'double') ...[
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          label: "Min Value",
                          value: v.validationMin != null ? v.validationMin.toString() : '',
                          onChanged: (val) {
                            final double? minVal = double.tryParse(val);
                            final upd = v.copyWith(validationMin: minVal);
                            notifier.updateVariable(v.id, upd);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTextField(
                          label: "Max Value",
                          value: v.validationMax != null ? v.validationMax.toString() : '',
                          onChanged: (val) {
                            final double? maxVal = double.tryParse(val);
                            final upd = v.copyWith(validationMax: maxVal);
                            notifier.updateVariable(v.id, upd);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            const Divider(height: 12),
            ExpansionTile(
              title: Text("State Persistence", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
              tilePadding: EdgeInsets.zero,
              children: [
                SwitchListTile(
                  title: Text("Persist state locally", style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textPrimary)),
                  value: v.isPersistent,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    final upd = v.copyWith(isPersistent: val);
                    notifier.updateVariable(v.id, upd);
                  },
                ),
                if (v.isPersistent) ...[
                  _buildDropdown(
                    label: "Storage Engine",
                    value: v.persistenceType,
                    options: const ['none', 'shared_preferences', 'hive', 'secure_storage'],
                    onChanged: (val) {
                      final upd = v.copyWith(persistenceType: val ?? 'none');
                      notifier.updateVariable(v.id, upd);
                    },
                  ),
                ],
              ],
            ),
            const Divider(height: 12),
            ExpansionTile(
              title: Text("Visual Bindings Manager", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
              tilePadding: EdgeInsets.zero,
              children: [
                _buildDropdown(
                  label: "Bind to Widget Property",
                  value: v.boundWidgetId ?? 'None',
                  options: const ['None', 'username_input', 'password_input', 'submit_button', 'profile_header', 'amount_field'],
                  onChanged: (val) {
                    final upd = v.copyWith(boundWidgetId: val == 'None' ? null : val);
                    notifier.updateVariable(v.id, upd);
                  },
                ),
                if (v.boundWidgetId != null) ...[
                  _buildDropdown(
                    label: "Target Property",
                    value: v.boundProperty ?? 'text',
                    options: const ['text', 'value', 'visibility', 'isEnabled', 'color'],
                    onChanged: (val) {
                      final upd = v.copyWith(boundProperty: val);
                      notifier.updateVariable(v.id, upd);
                    },
                  ),
                ],
                _buildDropdown(
                  label: "Bind to API Action Field",
                  value: v.boundApiId ?? 'None',
                  options: const ['None', 'User Login API', 'Get User Profile'],
                  onChanged: (val) {
                    final upd = v.copyWith(boundApiId: val == 'None' ? null : val);
                    notifier.updateVariable(v.id, upd);
                  },
                ),
                if (v.boundApiId != null) ...[
                  _buildTextField(
                    label: "Target API Payload Field",
                    value: v.boundApiField ?? '',
                    onChanged: (val) {
                      final upd = v.copyWith(boundApiField: val.trim().isEmpty ? null : val.trim());
                      notifier.updateVariable(v.id, upd);
                    },
                  ),
                ],
              ],
            ),
            const Divider(height: 12),
            ExpansionTile(
              title: Text("Variable Usage Tracking", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
              tilePadding: EdgeInsets.zero,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _getVariableUsages(v).map((usage) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Row(
                          children: [
                            const Icon(Icons.link_rounded, size: 12, color: Colors.tealAccent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                usage,
                                style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  dynamic _parseTypedValue(String val, String type) {
    if (type == 'int') {
      return int.tryParse(val) ?? 0;
    } else if (type == 'double') {
      return double.tryParse(val) ?? 0.0;
    } else if (type == 'bool') {
      return val.toLowerCase() == 'true';
    } else if (type == 'List') {
      try {
        return json.decode(val) as List;
      } catch (_) {
        return [];
      }
    } else if (type == 'Map') {
      try {
        return json.decode(val) as Map;
      } catch (_) {
        return {};
      }
    }
    return val;
  }

  List<String> _getVariableUsages(AppVariable v) {
    final usages = <String>[];
    if (v.boundWidgetId != null) {
      usages.add("Bound to widget '${v.boundWidgetId}' property '${v.boundProperty}'");
    }
    if (v.boundApiId != null) {
      usages.add("Bound to API '${v.boundApiId}' payload field '${v.boundApiField}'");
    }
    if (v.name == 'userName') {
      usages.add("Referenced in 'LoginScreen' onSubmit Action");
      usages.add("Referenced in 'DashboardScreen' user greeting header");
    }
    if (v.name == 'isLoggedIn') {
      usages.add("Used in Auth Guard routing conditional check");
    }
    if (usages.isEmpty) {
      usages.add("No usages recorded. Bind to components or endpoints.");
    }
    return usages;
  }

  Widget _buildTextField({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          TextFormField(
            key: ValueKey(value),
            initialValue: value,
            onChanged: onChanged,
            style: GoogleFonts.inter(fontSize: 12),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: options.contains(value) ? value : options.first,
            onChanged: onChanged,
            isDense: true,
            style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textPrimary),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            items: options
                .map((opt) => DropdownMenuItem(
                      value: opt,
                      child: Text(opt),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
