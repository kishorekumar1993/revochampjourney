import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/core/component_engine/models/app_variable.dart';
import 'package:revojourneytryone/features/visual_builder/application/studio_providers.dart';
import 'studio_panel_wrapper.dart';
import 'variable_panel/variable_dialogs.dart';
import 'variable_panel/variable_edit_pane.dart';

class RevoVariablesPanel extends ConsumerWidget {
  const RevoVariablesPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(appVariablesProvider);
    final notifier = ref.read(appVariablesProvider.notifier);
    final selectedVar = ref.watch(selectedVariableProvider);
    final searchQuery = ref.watch(variableSearchQueryProvider);
    final changeLogs = ref.watch(variableChangeLogsProvider);

    final filteredList = list.where((v) {
      if (searchQuery.trim().isEmpty) return true;
      return v.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          v.type.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    if (selectedVar != null) {
      return VariableEditPane(variable: selectedVar);
    }

    // Collapsible Categorized groups builder
    final Map<VariableScope, List<AppVariable>> groupedVars = {
      VariableScope.app: [],
      VariableScope.page: [],
      VariableScope.component: [],
      VariableScope.session: [],
    };
    for (final v in filteredList) {
      groupedVars[v.scope]?.add(v);
    }

    return SizedBox(
      width: 300,
      child: RevoStudioPanelWrapper(
        title: "State Variables",
        subtitle: "Manage reactive low-code variables",
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined, size: 16),
            tooltip: "State Inspector",
            onPressed: () => VariableDialogs.showInspectorDialog(context, list),
          ),
          IconButton(
            icon: const Icon(Icons.history_toggle_off_rounded, size: 16),
            tooltip: "Value Change Logs",
            onPressed: () => VariableDialogs.showLogsDialog(context, changeLogs),
          ),
          IconButton(
            icon: const Icon(Icons.import_export_rounded, size: 16),
            tooltip: "Import/Export JSON",
            onPressed: () => VariableDialogs.showImportExportDialog(context, list, notifier),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 18),
            tooltip: "Add Variable",
            onPressed: () {
              final id = 'var_${DateTime.now().millisecondsSinceEpoch}';
              final newVar = AppVariable(
                id: id,
                name: 'newVariable',
                type: 'String',
                defaultValue: 'Default',
                currentValue: 'Default',
                scope: VariableScope.app,
              );
              notifier.addVariable(newVar);
              ref.read(selectedVariableIdProvider.notifier).state = id;
            },
          ),
        ],
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
              child: TextFormField(
                initialValue: searchQuery,
                style: GoogleFonts.inter(fontSize: 11),
                decoration: InputDecoration(
                  hintText: "Search variables...",
                  prefixIcon: const Icon(Icons.search_rounded, size: 14),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onChanged: (val) {
                  ref.read(variableSearchQueryProvider.notifier).state = val;
                },
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(8),
                children: groupedVars.entries.map((group) {
                  final scopeName = group.key.toString().split('.').last.toUpperCase();
                  final groupList = group.value;
                  if (groupList.isEmpty && searchQuery.isNotEmpty) {
                    return const SizedBox();
                  }

                  return ExpansionTile(
                    title: Text("$scopeName VARIABLES", style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: RevoTheme.primaryLight)),
                    leading: const Icon(Icons.folder_open_rounded, size: 14, color: Colors.amber),
                    initiallyExpanded: true,
                    children: groupList.isEmpty
                        ? [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                "No variables in $scopeName scope",
                                style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary, fontStyle: FontStyle.italic),
                              ),
                            )
                          ]
                        : groupList.map((v) {
                            final isBound = v.boundWidgetId != null || v.boundApiId != null;
                            final displayVal = v.isSecret ? '******' : (v.currentValue ?? v.defaultValue ?? '').toString();

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                              child: ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                onTap: () => ref.read(selectedVariableIdProvider.notifier).state = v.id,
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(v.name, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                    Text(
                                      v.type,
                                      style: GoogleFonts.inter(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 2),
                                    Text(
                                      "Value: $displayVal",
                                      style: GoogleFonts.sourceCodePro(fontSize: 9, color: Colors.greenAccent),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (isBound) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.link_rounded, size: 10, color: Colors.tealAccent),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              v.boundWidgetId != null ? "Widget: [${v.boundWidgetId}]" : "API: [${v.boundApiId}]",
                                              style: GoogleFonts.inter(fontSize: 9, color: Colors.tealAccent, fontWeight: FontWeight.bold),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 14, color: Colors.redAccent),
                                  onPressed: () => notifier.deleteVariable(v.id),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                            );
                          }).toList(),
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: ElevatedButton.icon(
                onPressed: () => VariableDialogs.showGenerateCodeDialog(context, list),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                  backgroundColor: const Color(0xFF5B4FCF),
                ),
                icon: const Icon(Icons.code_rounded, color: Colors.white, size: 16),
                label: const Text("Generate State Classes", style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
