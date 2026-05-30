import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/features/visual_builder/application/studio_providers.dart';

class RevoEnvSelector extends ConsumerWidget {
  const RevoEnvSelector({super.key});

  // Helper validation to find missing variables in active environment
  static List<String> findMissingVariables({
    required String text,
    required String activeEnv,
    required Map<String, Map<String, String>> envVariables,
    required List<dynamic> appVariables,
  }) {
    final missing = <String>[];
    final regExp = RegExp(r'\{\{([^}]+)\}\}');
    final matches = regExp.allMatches(text);
    
    final envKeys = envVariables[activeEnv]?.keys.toSet() ?? {};
    final appKeys = appVariables.map((v) => v.name as String).toSet();

    for (final match in matches) {
      final key = match.group(1)?.trim() ?? '';
      if (key.isNotEmpty && !envKeys.contains(key) && !appKeys.contains(key)) {
        missing.add(key);
      }
    }
    return missing;
  }

  void _showEnvVariablesDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final envVars = ref.watch(envVariablesProvider);
            final notifier = ref.read(envVariablesProvider.notifier);

            // Extract all unique keys across all environments
            final allKeys = <String>{};
            envVars.forEach((_, vars) => allKeys.addAll(vars.keys));
            final sortedKeys = allKeys.toList()..sort();

            return AlertDialog(
              backgroundColor: RevoTheme.sidebarBackground,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Environment Variables Table",
                    style: GoogleFonts.outfit(
                      color: RevoTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.add_rounded, size: 14),
                    label: const Text("New Key", style: TextStyle(fontSize: 10)),
                    onPressed: () {
                      _showAddVariableDialog(context, ref, () {
                        setState(() {});
                      });
                    },
                  ),
                ],
              ),
              content: SizedBox(
                width: 750,
                height: 400,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Manage keys globally. Access them using {{variableName}} syntax in endpoints, headers, or query parameters.",
                      style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    Expanded(
                      child: sortedKeys.isEmpty
                          ? Center(
                              child: Text(
                                "No environment variables created yet.",
                                style: GoogleFonts.inter(fontSize: 11, fontStyle: FontStyle.italic),
                              ),
                            )
                          : SingleChildScrollView(
                              child: Table(
                                border: TableBorder.all(
                                  color: RevoTheme.cardBorder,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                columnWidths: const {
                                  0: FlexColumnWidth(1.5), // Key name
                                  1: FlexColumnWidth(2),   // DEV
                                  2: FlexColumnWidth(2),   // UAT
                                  3: FlexColumnWidth(2),   // PROD
                                  4: FlexColumnWidth(2),   // LOCAL
                                  5: FixedColumnWidth(40),  // Actions
                                },
                                children: [
                                  TableRow(
                                    decoration: BoxDecoration(color: RevoTheme.cardBorder.withValues(alpha: 0.2)),
                                    children: [
                                      _buildHeaderCell("Variable Key"),
                                      _buildHeaderCell("DEV"),
                                      _buildHeaderCell("UAT"),
                                      _buildHeaderCell("PROD"),
                                      _buildHeaderCell("LOCAL"),
                                      _buildHeaderCell(""),
                                    ],
                                  ),
                                  ...sortedKeys.map((key) {
                                    return TableRow(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                          child: Text(
                                            key,
                                            style: GoogleFonts.sourceCodePro(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: RevoTheme.primary,
                                            ),
                                          ),
                                        ),
                                        _buildCellEditor(ref, 'DEV', key, envVars['DEV']?[key] ?? ''),
                                        _buildCellEditor(ref, 'UAT', key, envVars['UAT']?[key] ?? ''),
                                        _buildCellEditor(ref, 'PROD', key, envVars['PROD']?[key] ?? ''),
                                        _buildCellEditor(ref, 'LOCAL', key, envVars['LOCAL']?[key] ?? ''),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, size: 14, color: Colors.redAccent),
                                          onPressed: () {
                                            notifier.removeVariable(key);
                                            setState(() {});
                                          },
                                        ),
                                      ],
                                    );
                                  }),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Close", style: TextStyle(fontSize: 11)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddVariableDialog(BuildContext parentCtx, WidgetRef ref, VoidCallback onAdded) {
    final ctrl = TextEditingController();
    showDialog(
      context: parentCtx,
      builder: (ctx) => AlertDialog(
        backgroundColor: RevoTheme.sidebarBackground,
        title: const Text("Add New Environment Key", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(fontSize: 11),
          decoration: const InputDecoration(hintText: "e.g. baseUrl", isDense: true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(fontSize: 11))),
          ElevatedButton(
            onPressed: () {
              final key = ctrl.text.trim();
              if (key.isNotEmpty) {
                ref.read(envVariablesProvider.notifier).addVariable(key);
                Navigator.pop(ctx);
                onAdded();
              }
            },
            child: const Text("Add", style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: RevoTheme.textSecondary),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCellEditor(WidgetRef ref, String env, String key, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
      child: TextFormField(
        initialValue: val,
        key: ValueKey('${env}_${key}_field'),
        onChanged: (newVal) {
          ref.read(envVariablesProvider.notifier).updateVariable(env, key, newVal);
        },
        style: GoogleFonts.inter(fontSize: 10),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          border: OutlineInputBorder(borderSide: BorderSide.none),
          filled: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeEnv = ref.watch(activeEnvironmentProvider);
    final envNotifier = ref.read(activeEnvironmentProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: RevoTheme.sidebarBackground,
        border: Border(bottom: BorderSide(color: RevoTheme.cardBorder)),
      ),
      child: Row(
        children: [
          Text(
            "Environment: ",
            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: RevoTheme.textSecondary),
          ),
          const SizedBox(width: 4),
          DropdownButton<String>(
            value: activeEnv,
            onChanged: (val) {
              if (val != null) envNotifier.state = val;
            },
            isDense: true,
            style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.primary, fontWeight: FontWeight.bold),
            underline: const SizedBox(),
            items: ['DEV', 'UAT', 'PROD', 'LOCAL'].map((e) {
              return DropdownMenuItem(value: e, child: Text(e));
            }).toList(),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 14),
            onPressed: () => _showEnvVariablesDialog(context, ref),
            tooltip: "Manage Environment Variables",
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
