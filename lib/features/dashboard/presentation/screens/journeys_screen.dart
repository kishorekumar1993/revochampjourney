import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme.dart';
import '../../../journey_builder/data/models.dart';
import '../../../journey_builder/presentation/providers/journey_provider.dart';

class RevoJourneysScreen extends ConsumerWidget {
  final Function(JourneyConfig) onEditJourney;
  final VoidCallback onCreateNew;

  const RevoJourneysScreen({
    super.key,
    required this.onEditJourney,
    required this.onCreateNew,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journeys = ref.watch(journeysListProvider);

    return Scaffold(
      backgroundColor: RevoTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Title and New Journey Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Journeys Catalog",
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: RevoTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Manage, configure, and monitor your dynamic multi-step application journeys.",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: RevoTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showCreateJourneyDialog(context, ref),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text("Create Journey"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    backgroundColor: RevoTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 2. Journey Stats row
            _buildStatsRow(journeys.length),
            const SizedBox(height: 32),

            // 3. Catalog Title
            Text(
              "All Journeys (${journeys.length})",
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: RevoTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // 4. Journeys Table / List
            Expanded(
              child: journeys.isEmpty
                  ? _buildEmptyState(context, ref)
                  : ListView.builder(
                      itemCount: journeys.length,
                      itemBuilder: (context, index) {
                        final journey = journeys[index];
                        final totalSteps = journey.steps.length;
                        final isDefault = journey.journeyName == "Motor Insurance Journey";

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: RevoTheme.cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: RevoTheme.cardBorder),
                          ),
                          child: Row(
                            children: [
                              // Icon avatar
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: RevoTheme.primary.withValues(alpha:0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.alt_route_rounded,
                                  color: RevoTheme.primaryLight,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Name and Version
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      journey.journeyName,
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: RevoTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Version ${journey.version}",
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: RevoTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Steps Count
                              Expanded(
                                flex: 2,
                                child: Row(
                                  children: [
                                    Icon(Icons.layers_outlined, size: 14, color: RevoTheme.textSecondary),
                                    const SizedBox(width: 6),
                                    Text(
                                      "$totalSteps steps",
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: RevoTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Status Badge
                              Expanded(
                                flex: 2,
                                child: Container(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isDefault 
                                          ? RevoTheme.success.withValues(alpha: 0.15) 
                                          : RevoTheme.primaryLight.withValues(alpha:0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isDefault 
                                            ? RevoTheme.success.withValues(alpha:0.4) 
                                            : RevoTheme.primaryLight.withValues(alpha:0.4),
                                      ),
                                    ),
                                    child: Text(
                                      isDefault ? "Published" : "Draft",
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: isDefault ? RevoTheme.success : RevoTheme.primaryLight,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Last Modified Mockup
                              Expanded(
                                flex: 2,
                                child: Text(
                                  "Just now",
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: RevoTheme.textSecondary,
                                  ),
                                ),
                              ),

                              // Action Buttons
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit_rounded, color: RevoTheme.primaryLight, size: 18),
                                    tooltip: "Open in Builder",
                                    onPressed: () => onEditJourney(journey),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                    tooltip: "Delete Journey",
                                    onPressed: isDefault
                                        ? null // Don't delete default
                                        : () {
                                            ref.read(journeysListProvider.notifier).removeJourney(journey.journeyName);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text("Journey deleted successfully.")),
                                            );
                                          },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(int total) {
    final stats = [
      {'label': 'Total Journeys', 'value': '$total', 'icon': Icons.alt_route_rounded, 'color': RevoTheme.primaryLight},
      {'label': 'Active Runs', 'value': '124', 'icon': Icons.play_circle_outline_rounded, 'color': RevoTheme.secondary},
      {'label': 'Avg Completion', 'value': '84%', 'icon': Icons.analytics_outlined, 'color': RevoTheme.accent},
      {'label': 'Failed Submissions', 'value': '1.2%', 'icon': Icons.error_outline_rounded, 'color': RevoTheme.warning},
    ];

    return Row(
      children: stats.map((s) {
        final color = s['color'] as Color;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: RevoTheme.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: RevoTheme.cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha:0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(s['icon'] as IconData, color: color, size: 20),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s['label'] as String,
                      style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s['value'] as String,
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.art_track_rounded, size: 48, color: RevoTheme.textSecondary),
          const SizedBox(height: 16),
          Text(
            "No journeys created yet",
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Create a new journey to design dynamic workflows.",
            style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _showCreateJourneyDialog(context, ref),
            child: const Text("Create Journey"),
          ),
        ],
      ),
    );
  }

  void _showCreateJourneyDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: RevoTheme.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: RevoTheme.cardBorder),
        ),
        title: Text(
          "Create New Journey Workflow",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Journey Name",
                hintText: "e.g. Credit Card Application",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                final newJourney = JourneyConfig(
                  journeyName: name,
                  version: "1.0.0",
                  steps: [],
                );
                // Save to journeys list
                ref.read(journeysListProvider.notifier).addJourney(newJourney);
                // Close dialog and load into active builder config
                Navigator.pop(context);
                onEditJourney(newJourney);
              }
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }
}
