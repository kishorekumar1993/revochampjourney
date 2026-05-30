import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/core/component_engine/models/app_variable.dart';
import 'package:revojourneytryone/features/visual_builder/application/studio_providers.dart';
import 'variable_code_generator.dart';

class VariableDialogs {
  static void showGenerateCodeDialog(BuildContext context, List<AppVariable> list) {
    showDialog(
      context: context,
      builder: (context) {
        return DefaultTabController(
          length: 5,
          child: AlertDialog(
            backgroundColor: RevoTheme.sidebarBackground,
            title: Text(
              "Multi-Architecture Code Generator", 
              style: GoogleFonts.outfit(color: RevoTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)
            ),
            content: SizedBox(
              width: 600,
              height: 480,
              child: Column(
                children: [
                  TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: RevoTheme.primaryLight,
                    unselectedLabelColor: RevoTheme.textSecondary,
                    indicatorColor: RevoTheme.primary,
                    tabs: const [
                      Tab(text: "Riverpod"),
                      Tab(text: "GetX"),
                      Tab(text: "BLoC"),
                      Tab(text: "Provider"),
                      Tab(text: "MobX"),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildCodeViewer(context, VariableCodeGenerator.generateRiverpodCode(list)),
                        _buildCodeViewer(context, VariableCodeGenerator.generateGetXCode(list)),
                        _buildCodeViewer(context, VariableCodeGenerator.generateBlocCode(list)),
                        _buildCodeViewer(context, VariableCodeGenerator.generateProviderCode(list)),
                        _buildCodeViewer(context, VariableCodeGenerator.generateMobXCode(list)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close", style: TextStyle(color: Color(0xFF5B4FCF))),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildCodeViewer(BuildContext context, String code) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TextFormField(
              initialValue: code,
              maxLines: null,
              readOnly: true,
              style: GoogleFonts.sourceCodePro(fontSize: 10, color: Colors.greenAccent),
              decoration: const InputDecoration(
                border: InputBorder.none,
                fillColor: Colors.black,
                filled: true,
                contentPadding: EdgeInsets.all(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: code));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Code copied to clipboard!"), backgroundColor: Colors.green),
            );
          },
          icon: const Icon(Icons.copy_rounded, size: 14, color: Colors.white),
          label: const Text("Copy Code", style: TextStyle(fontSize: 11, color: Colors.white)),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B4FCF)),
        ),
      ],
    );
  }

  static void showInspectorDialog(BuildContext context, List<AppVariable> list) {
    bool showSecrets = false;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: RevoTheme.sidebarBackground,
              title: Row(
                children: [
                  const Icon(Icons.analytics_outlined, size: 18, color: Color(0xFF5B4FCF)),
                  const SizedBox(width: 8),
                  Text("Live State Inspector", style: GoogleFonts.outfit(color: RevoTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: Icon(showSecrets ? Icons.visibility : Icons.visibility_off, size: 16),
                    onPressed: () => setModalState(() => showSecrets = !showSecrets),
                  ),
                ],
              ),
              content: SizedBox(
                width: 400,
                height: 350,
                child: list.isEmpty
                    ? const Center(child: Text("No variables configured to inspect."))
                    : ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (ctx, idx) {
                          final v = list[idx];
                          final isSecret = v.isSecret && !showSecrets;
                          final displayVal = isSecret ? '******' : (v.currentValue ?? v.defaultValue ?? 'null').toString();

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(v.name, style: GoogleFonts.sourceCodePro(fontSize: 11, fontWeight: FontWeight.bold, color: RevoTheme.primaryLight)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 3,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(displayVal, style: GoogleFonts.sourceCodePro(fontSize: 10, color: Colors.greenAccent)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static void showImportExportDialog(BuildContext context, List<AppVariable> list, AppVariablesNotifier notifier) {
    final rawJson = json.encode(list.map((v) => v.toJson()).toList());
    final ctrl = TextEditingController(text: rawJson);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: RevoTheme.sidebarBackground,
          title: Text("JSON Import / Export", style: GoogleFonts.outfit(color: RevoTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 480,
            height: 380,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text("Copy the JSON schema below to backup or paste an array of Variable objects to import schema.", style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary)),
                const SizedBox(height: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: TextField(
                      controller: ctrl,
                      maxLines: null,
                      expands: true,
                      style: GoogleFonts.sourceCodePro(fontSize: 10, color: Colors.amberAccent),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        fillColor: Colors.black,
                        filled: true,
                        contentPadding: EdgeInsets.all(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B4FCF)),
              onPressed: () {
                try {
                  final decoded = json.decode(ctrl.text);
                  if (decoded is List) {
                    for (final item in decoded) {
                      if (item is Map<String, dynamic>) {
                        final v = AppVariable.fromJson(item);
                        notifier.addVariable(v);
                      }
                    }
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Variables imported successfully!"), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error parsing schema: $e"), backgroundColor: Colors.redAccent),
                  );
                }
              },
              child: const Text("Import Variables", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  static void showLogsDialog(BuildContext context, List<Map<String, dynamic>> changeLogs) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: RevoTheme.sidebarBackground,
          title: Text("Value Watcher Logs", style: GoogleFonts.outfit(color: RevoTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 420,
            height: 350,
            child: changeLogs.isEmpty
                ? const Center(child: Text("No value change updates tracked yet."))
                : ListView.builder(
                    itemCount: changeLogs.length,
                    itemBuilder: (ctx, idx) {
                      final log = changeLogs[idx];
                      final time = log['time'] as DateTime;
                      final timeStr = "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}";

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: RevoTheme.cardBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Text(log['name'] as String, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: RevoTheme.primaryLight)),
                                  const Spacer(),
                                  Text(timeStr, style: GoogleFonts.inter(fontSize: 9, color: RevoTheme.textSecondary)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(log['old'].toString(), style: GoogleFonts.sourceCodePro(fontSize: 9, color: Colors.grey)),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_right_alt_rounded, size: 12, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(log['new'].toString(), style: GoogleFonts.sourceCodePro(fontSize: 10, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }
}
