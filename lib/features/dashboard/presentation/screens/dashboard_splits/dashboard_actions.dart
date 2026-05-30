import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/features/journey_builder/presentation/providers/journey_provider.dart';
import 'package:revojourneytryone/features/dashboard/presentation/screens/code_preview_dialog.dart';
import 'package:revojourneytryone/codegenerator/filegegnerator/revochamp_bloc_generator.dart' deferred as bloc_gen;

class DashboardActions {
  static void exportJson(BuildContext context, Map<String, dynamic> jsonMap) {
    final jsonStr = const JsonEncoder.withIndent('  ').convert(jsonMap);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: RevoTheme.cardBg,
        title: const Text("Exported JSON Configuration"),
        content: SizedBox(
          width: 500,
          height: 400,
          child: TextField(
            controller: TextEditingController(text: jsonStr),
            maxLines: null,
            readOnly: true,
            style: GoogleFonts.sourceCodePro(fontSize: 12, color: Colors.greenAccent),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Done"),
          ),
        ],
      ),
    );
  }

  static void importJsonDialog(BuildContext context, WidgetRef ref) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: RevoTheme.cardBg,
        title: const Text("Import Journey Config JSON"),
        content: SizedBox(
          width: 500,
          height: 350,
          child: Column(
            children: [
              Text(
                "Paste your Journey JSON structure here to generate screens dynamically.",
                style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TextField(
                  controller: textController,
                  maxLines: null,
                  decoration: const InputDecoration(
                    hintText: '{\n  "journeyName": "Insurance",\n  "steps": []\n}',
                  ),
                  style: GoogleFonts.sourceCodePro(fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final jsonStr = textController.text.trim();
              if (jsonStr.isNotEmpty) {
                final success = ref.read(journeyConfigProvider.notifier).updateFromJson(jsonStr);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: const Text("Journey Config Imported successfully!"), backgroundColor: RevoTheme.success),
                  );
                  Navigator.pop(dialogContext);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: const Text("Invalid JSON structure!"), backgroundColor: RevoTheme.error),
                  );
                }
              }
            },
            child: const Text("Import"),
          ),
        ],
      ),
    );
  }

  static void generateBlocCode(BuildContext context, WidgetRef ref, dynamic journeyConfig) {
    if (journeyConfig.steps == null || journeyConfig.steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No steps found in this journey!"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        bool blocSelected = true;
        bool getxSelected = true;
        bool riverpodSelected = true;
        String selectedLayout = 'split';

        return StatefulBuilder(
          builder: (sbContext, setStateDialog) {
            final textStyle = GoogleFonts.inter(color: RevoTheme.textPrimary);
            final hasSelection = blocSelected || getxSelected || riverpodSelected;

            return AlertDialog(
              backgroundColor: RevoTheme.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: RevoTheme.cardBorder),
              ),
              title: Text(
                "Generate Flutter Code",
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
              ),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Select target architectures to generate for your multi-step journey:",
                      style: GoogleFonts.inter(fontSize: 13, color: RevoTheme.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    Theme(
                      data: ThemeData(
                        unselectedWidgetColor: RevoTheme.textSecondary,
                      ),
                      child: Column(
                        children: [
                          CheckboxListTile(
                            title: Text("BLoC Architecture", style: textStyle.copyWith(fontSize: 13, fontWeight: FontWeight.bold)),
                            subtitle: Text("Clean Code, Repositories, Use Cases, Events, States & Screens", style: textStyle.copyWith(fontSize: 11, color: RevoTheme.textSecondary)),
                            value: blocSelected,
                            activeColor: RevoTheme.primaryLight,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) {
                              setStateDialog(() {
                                blocSelected = val ?? false;
                              });
                            },
                          ),
                          CheckboxListTile(
                            title: Text("GetX Architecture", style: textStyle.copyWith(fontSize: 13, fontWeight: FontWeight.bold)),
                            subtitle: Text("Bindings, Controllers, Repositories & View Screens", style: textStyle.copyWith(fontSize: 11, color: RevoTheme.textSecondary)),
                            value: getxSelected,
                            activeColor: RevoTheme.primaryLight,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) {
                              setStateDialog(() {
                                getxSelected = val ?? false;
                              });
                            },
                          ),
                          CheckboxListTile(
                            title: Text("Riverpod Architecture", style: textStyle.copyWith(fontSize: 13, fontWeight: FontWeight.bold)),
                            subtitle: Text("Notifier, Providers, Entities, Data Sources & Screens", style: textStyle.copyWith(fontSize: 11, color: RevoTheme.textSecondary)),
                            value: riverpodSelected,
                            activeColor: RevoTheme.primaryLight,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) {
                              setStateDialog(() {
                                riverpodSelected = val ?? false;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "GetX View Layout Style",
                      style: textStyle.copyWith(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: RevoTheme.cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: RevoTheme.cardBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedLayout,
                          dropdownColor: RevoTheme.cardBg,
                          isExpanded: true,
                          style: GoogleFonts.inter(color: RevoTheme.textPrimary, fontSize: 13),
                          items: const [
                            DropdownMenuItem(value: 'split', child: Text('Split Screen View')),
                            DropdownMenuItem(value: 'focus', child: Text('Conversational Focus View')),
                            DropdownMenuItem(value: 'timeline', child: Text('Vertical Timeline View')),
                            DropdownMenuItem(value: 'tabbed', child: Text('Tabbed Sidebar Navigation')),
                            DropdownMenuItem(value: 'carousel', child: Text('Carousel Card Slider')),
                            DropdownMenuItem(value: 'masterdetail', child: Text('Master Detail View')),
                            DropdownMenuItem(value: 'accordion', child: Text('Accordion List View')),
                            DropdownMenuItem(value: 'form', child: Text('Simple Scrollable Form')),
                          ],
                          onChanged: (val) {
                            setStateDialog(() {
                              if (val != null) selectedLayout = val;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text("Cancel", style: TextStyle(color: RevoTheme.textSecondary)),
                ),
                OutlinedButton(
                  onPressed: !hasSelection
                      ? null
                      : () async {
                          await bloc_gen.loadLibrary();
                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext);
                          final architectures = {
                            if (blocSelected) bloc_gen.Architecture.bloc,
                            if (getxSelected) bloc_gen.Architecture.getx,
                            if (riverpodSelected) bloc_gen.Architecture.riverpod,
                          };

                          try {
                            final files = await bloc_gen.generateAllFilesDataIsolate(
                              journeyConfig: journeyConfig,
                              architectures: architectures,
                              layoutStyle: selectedLayout,
                            );
                            
                            if (files.isEmpty) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("No files generated!"), backgroundColor: Colors.orange),
                              );
                              return;
                            }

                            if (!context.mounted) return;
                            showDialog(
                              context: context,
                              builder: (context) => CodePreviewDialog(files: files),
                            );
                          } catch (e, stack) {
                            debugPrint("Preview generation error: $e\n$stack");
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Preview error: $e"),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: RevoTheme.primary),
                  ),
                  child: Text("Preview Code", style: TextStyle(color: RevoTheme.primaryLight)),
                ),
                ElevatedButton(
                  onPressed: !hasSelection
                      ? null
                      : () async {
                          await bloc_gen.loadLibrary();
                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext);
                          final architectures = {
                            if (blocSelected) bloc_gen.Architecture.bloc,
                            if (getxSelected) bloc_gen.Architecture.getx,
                            if (riverpodSelected) bloc_gen.Architecture.riverpod,
                          };

                          try {
                            await bloc_gen.generateAndSaveAllFiles(
                              journeyConfig: journeyConfig,
                              architectures: architectures,
                              layoutStyle: selectedLayout,
                            );

                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("✅ Code generation started — select your project folder!"),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 4),
                              ),
                            );
                          } catch (e, stack) {
                            debugPrint("Generation error: $e\n$stack");
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Generation error: $e"),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RevoTheme.primary,
                  ),
                  child: const Text("Generate"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
