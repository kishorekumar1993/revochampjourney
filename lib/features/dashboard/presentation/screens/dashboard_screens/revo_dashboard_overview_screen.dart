import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/features/journey_builder/data/models.dart';
import 'package:revojourneytryone/features/journey_builder/presentation/providers/journey_provider.dart';

class RevoDashboardOverviewScreen extends ConsumerWidget {
  final VoidCallback? onCreateNew;
  final Function(JourneyConfig)? onEditJourney;
  final VoidCallback? onViewCatalog;
  final VoidCallback? onViewTemplates;
  final VoidCallback? onViewRuns;

  const RevoDashboardOverviewScreen({
    super.key,
    this.onCreateNew,
    this.onEditJourney,
    this.onViewCatalog,
    this.onViewTemplates,
    this.onViewRuns,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journeys = ref.watch(journeysListProvider);
    final runs = ref.watch(journeyRunsProvider);

    // Compute dynamic metrics
    final totalJourneys = journeys.length;
    final totalRuns = runs.length;
    final completedRuns = runs.where((r) => r['status'] == 'Completed').length;
    final successRate = totalRuns > 0 ? (completedRuns / totalRuns * 100).toStringAsFixed(0) : '100';
    
    final uniqueUsers = runs.map((r) => r['user'].toString()).toSet().length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Workspace Overview",
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: RevoTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Real-time overview of active journeys, simulation metrics, and workspace activity.",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: RevoTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: onCreateNew,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text("Create Journey"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  backgroundColor: RevoTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // 1. Dynamic System metrics
          _buildMetricsGrid(totalJourneys, totalRuns, successRate, uniqueUsers),
          const SizedBox(height: 32),

          // 2. Main Content Grid (Two-column layout: Active Journeys Catalog vs Quick Actions & Recent Logs)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column Left: Active Journeys Grid
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Active Journeys Catalog",
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: RevoTheme.textPrimary,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: onViewCatalog,
                          icon: const Icon(Icons.chevron_right_rounded, size: 16),
                          label: const Text("View Catalog", style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            foregroundColor: RevoTheme.primaryLight,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    journeys.isEmpty
                        ? _buildEmptyState(context)
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: journeys.length > 4 ? 4 : journeys.length,
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 360,
                              mainAxisExtent: 180,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemBuilder: (context, idx) {
                                final journey = journeys[idx];
                                return _buildJourneyCard(context, ref, journey);
                            },
                          ),
                  ],
                ),
              ),
              const SizedBox(width: 24),

              // Column Right: Quick Action Shortcuts & Runs History
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Quick Actions",
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: RevoTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildQuickActionCards(context),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Recent Runs Log",
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: RevoTheme.textPrimary,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: onViewRuns,
                          icon: const Icon(Icons.chevron_right_rounded, size: 16),
                          label: const Text("View Runs", style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            foregroundColor: RevoTheme.primaryLight,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildRecentRunsList(context, runs),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(int totalJourneys, int totalRuns, String successRate, int uniqueUsers) {
    final metrics = [
      {'label': 'Active Journeys', 'val': '$totalJourneys', 'change': 'Dynamic', 'icon': Icons.alt_route_rounded, 'color': RevoTheme.primaryLight},
      {'label': 'Simulations Run', 'val': '$totalRuns', 'change': 'Live Tracker', 'icon': Icons.play_circle_outline_rounded, 'color': RevoTheme.secondary},
      {'label': 'Avg Success Rate', 'val': '$successRate%', 'change': 'Pass Rate', 'icon': Icons.analytics_outlined, 'color': RevoTheme.accent},
      {'label': 'Active Users', 'val': '$uniqueUsers', 'change': 'Unique Profiles', 'icon': Icons.people_outline_rounded, 'color': Colors.amberAccent},
    ];

    return Row(
      children: metrics.map((m) {
        final color = m['color'] as Color;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: RevoTheme.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: RevoTheme.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      m['label'] as String,
                      style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary),
                    ),
                    Icon(m['icon'] as IconData, color: color, size: 16),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      m['val'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: RevoTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      m['change'] as String,
                      style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary),
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

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: RevoTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RevoTheme.cardBorder),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.art_track_rounded, size: 36, color: RevoTheme.textSecondary),
            const SizedBox(height: 12),
            Text(
              "No Active Journeys",
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              "Create a journey or load templates to get started.",
              style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJourneyCard(BuildContext context, WidgetRef ref, JourneyConfig journey) {
    final totalSteps = journey.steps.length;
    final totalFields = journey.steps.fold<int>(0, (sum, step) => sum + step.fields.length);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RevoTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RevoTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  journey.journeyName,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: RevoTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: RevoTheme.primary.withValues(alpha:0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: RevoTheme.primaryLight.withValues(alpha:0.3)),
                ),
                child: Text(
                  "v${journey.version}",
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: RevoTheme.primaryLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            journey.description.isNotEmpty ? journey.description : "No description provided.",
            style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            children: [
              Icon(Icons.layers_outlined, size: 12, color: RevoTheme.textSecondary),
              const SizedBox(width: 4),
              Text(
                "$totalSteps steps • $totalFields fields",
                style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onEditJourney != null ? () => onEditJourney!(journey) : null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: BorderSide(color: RevoTheme.cardBorder),
                  ),
                  child: const Text("Edit Builder", style: TextStyle(fontSize: 11)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(journeyConfigProvider.notifier).updateFromJson(json.encode(journey.toJson()));
                    context.push('/runner');
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    backgroundColor: RevoTheme.primary,
                  ),
                  child: const Text("Run Test", style: TextStyle(fontSize: 11, color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCards(BuildContext context) {
    final actions = [
      {
        'title': 'Explore Templates',
        'desc': 'Load pre-made configurations',
        'icon': Icons.collections_bookmark_outlined,
        'color': RevoTheme.secondary,
        'onTap': onViewTemplates,
      },
      {
        'title': 'Recent Simulation Logs',
        'desc': 'Inspect client execution states',
        'icon': Icons.play_circle_outline_rounded,
        'color': RevoTheme.accent,
        'onTap': onViewRuns,
      },
    ];

    return Row(
      children: actions.map((act) {
        final color = act['color'] as Color;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: act['onTap'] as VoidCallback?,
              borderRadius: BorderRadius.circular(12),
              child: Ink(
                padding: const EdgeInsets.all(16),
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
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(act['icon'] as IconData, color: color, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            act['title'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: RevoTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            act['desc'] as String,
                            style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentRunsList(BuildContext context, List<Map<String, dynamic>> runs) {
    if (runs.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: RevoTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: RevoTheme.cardBorder),
        ),
        child: const Center(
          child: Text("No runs simulation recorded yet."),
        ),
      );
    }

    final recentList = runs.take(3).toList();

    return Container(
      decoration: BoxDecoration(
        color: RevoTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RevoTheme.cardBorder),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: recentList.length,
        separatorBuilder: (context, idx) => Divider(color: RevoTheme.cardBorder, height: 1),
        itemBuilder: (context, index) {
          final run = recentList[index];
          final progress = run['progress'] as double;
          final isCompleted = run['status'] == 'Completed';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? RevoTheme.success.withValues(alpha:0.12)
                        : RevoTheme.accent.withValues(alpha:0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCompleted ? Icons.check_circle_outline : Icons.pending_outlined,
                    color: isCompleted ? RevoTheme.success : RevoTheme.accent,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 14),

                // Title details
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        run['journeyName'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: RevoTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${run['id']} • ${run['user']}",
                        style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Progress Bar
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: RevoTheme.isDark ? const Color(0xFF2C2C4A) : const Color(0xFFE2E8F0),
                          color: isCompleted ? RevoTheme.success : RevoTheme.primary,
                          minHeight: 4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${run['currentStep']} (${run['stepsCount']})",
                        style: GoogleFonts.inter(fontSize: 9, color: RevoTheme.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Started Time
                Text(
                  run['started'] as String,
                  style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
