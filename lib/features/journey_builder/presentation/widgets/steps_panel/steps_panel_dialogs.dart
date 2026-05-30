import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/features/journey_builder/data/models.dart';
import 'package:revojourneytryone/features/journey_builder/presentation/providers/journey_provider.dart';

void showAddStepDialog(BuildContext context, WidgetRef ref) {
  final titleController = TextEditingController();
  final idController = TextEditingController();
  String? idError;

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setStateDialog) => AlertDialog(
        backgroundColor: RevoTheme.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: RevoTheme.cardBorder),
        ),
        title: const Text(
          "Add New Journey Step",
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Step Title",
                hintText: "e.g. Address Details",
              ),
              onChanged: (val) {
                setStateDialog(() {
                  idController.text = val.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
                  idError = null;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: idController,
              decoration: InputDecoration(
                labelText: "Step ID (Unique Key)",
                hintText: "e.g. address_details",
                errorText: idError,
              ),
              onChanged: (_) {
                if (idError != null) setStateDialog(() => idError = null);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: RevoTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              final id = idController.text.trim();
              if (title.isNotEmpty && id.isNotEmpty) {
                final currentConfig = ref.read(journeyConfigProvider);
                if (currentConfig.steps.any((s) => s.id == id)) {
                  setStateDialog(() => idError = "Step ID already exists.");
                  return;
                }
                final newStep = JourneyStep(
                  id: id,
                  title: title,
                  fields: [],
                );
                ref.read(journeyConfigProvider.notifier).addStep(newStep);
                ref.read(activeStepIdProvider.notifier).state = id;
                Navigator.pop(context);
              }
            },
            child: const Text("Create"),
          ),
        ],
      ),
    ),
  );
}
