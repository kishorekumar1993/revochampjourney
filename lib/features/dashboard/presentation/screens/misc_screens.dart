import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme.dart';
import '../../../journey_builder/data/models.dart';
import '../../../journey_builder/presentation/providers/journey_provider.dart';

// ==========================================
// 1. REVO DASHBOARD OVERVIEW SCREEN
// ==========================================
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

    final theme = Theme.of(context);

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

// ==========================================
// 2. REVO ANALYTICS SCREEN
// ==========================================
class RevoAnalyticsScreen extends StatelessWidget {
  const RevoAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Conversions & Funnels",
            style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            "Examine completion funnels, dropout steps, and durations to optimize performance.",
            style: GoogleFonts.inter(fontSize: 13, color: RevoTheme.textSecondary),
          ),
          const SizedBox(height: 32),

          // Funnel design mockup
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: RevoTheme.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: RevoTheme.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "KYC Funnel Drop-off Rate Analysis",
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                _buildFunnelRow("Step 1: Identity Profile", 1.00, "1,200 entered (100%)"),
                _buildFunnelRow("Step 2: Upload Documents", 0.82, "984 reached (82%)"),
                _buildFunnelRow("Step 3: Facial Selfie Capture", 0.68, "816 reached (68%)"),
                _buildFunnelRow("Step 4: Confirm & Checkout", 0.55, "660 completed (55%)"),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Average durations list
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: RevoTheme.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: RevoTheme.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Average User Session Durations",
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildDurationItem("Upload Documents Page", "4m 42s", "Slow document scanning validation"),
                _buildDurationItem("Identity Profile Info", "1m 18s", "Standard typing inputs"),
                _buildDurationItem("Premium Payment Gateway", "2m 05s", "Awaiting OTP validation code"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFunnelRow(String stepName, double value, String details) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(stepName, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: RevoTheme.isDark ? const Color(0xFF2C2C4A) : const Color(0xFFE2E8F0),
                color: RevoTheme.accent,
                minHeight: 12,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(details, style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationItem(String step, String time, String reason) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 16, color: RevoTheme.textSecondary),
              const SizedBox(width: 12),
              Text(step, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          Text(time, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
          Text(reason, style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textSecondary)),
        ],
      ),
    );
  }
}

// ==========================================
// 3. REVO APPROVALS SCREEN
// ==========================================
class RevoApprovalsScreen extends StatelessWidget {
  const RevoApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final approvals = [
      {'title': 'Publish Motor Insurance v1.2.0', 'user': 'sarah.k@revo.com', 'date': '2 hours ago', 'status': 'Pending Approval'},
      {'title': 'Add PAN verification API endpoint', 'user': 'john.d@revo.com', 'date': '1 day ago', 'status': 'Approved'},
      {'title': 'Deploy Loan App to Production environment', 'user': 'alice.s@revo.com', 'date': '3 days ago', 'status': 'Approved'},
    ];

    return Scaffold(
      backgroundColor: RevoTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Approval Board",
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              "Review publication changes and REST endpoint setups before going live.",
              style: GoogleFonts.inter(fontSize: 13, color: RevoTheme.textSecondary),
            ),
            const SizedBox(height: 32),

            Expanded(
              child: ListView.builder(
                itemCount: approvals.length,
                itemBuilder: (context, index) {
                  final app = approvals[index];
                  final isPending = app['status'] == 'Pending Approval';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: RevoTheme.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: RevoTheme.cardBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(app['title']!, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 6),
                            Text("Requested by ${app['user']} • ${app['date']}", style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary)),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isPending ? RevoTheme.warning.withValues(alpha:0.15) : RevoTheme.success.withValues(alpha:0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: isPending ? RevoTheme.warning.withValues(alpha:0.4) : RevoTheme.success.withValues(alpha:0.4)),
                              ),
                              child: Text(
                                app['status']!,
                                style: GoogleFonts.inter(fontSize: 10, color: isPending ? RevoTheme.warning : RevoTheme.success, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 16),
                            if (isPending) ...[
                              ElevatedButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: const Text("Request Approved successfully!"), backgroundColor: RevoTheme.success),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  backgroundColor: RevoTheme.primary,
                                ),
                                child: const Text("Approve", style: TextStyle(fontSize: 11)),
                              ),
                            ],
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
}

// ==========================================
// 4. REVO USERS SCREEN
// ==========================================
class RevoUsersScreen extends StatelessWidget {
  const RevoUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final users = [
      {'name': 'Admin User', 'email': 'admin@revojourneytryone.com', 'role': 'Super Admin', 'status': 'Active'},
      {'name': 'Sarah Kerigan', 'email': 'sarah.k@revo.com', 'role': 'Journey Editor', 'status': 'Active'},
      {'name': 'Alice Smith', 'email': 'alice.s@revo.com', 'role': 'Designer', 'status': 'Invited'},
    ];

    return Scaffold(
      backgroundColor: RevoTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
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
                      "Workspace Team Members",
                      style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Manage team roles, access levels, and invite collaborators.",
                      style: GoogleFonts.inter(fontSize: 13, color: RevoTheme.textSecondary),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.person_add_rounded, size: 16),
                  label: const Text("Invite Member"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    backgroundColor: RevoTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            Expanded(
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final u = users[index];
                  final isActive = u['status'] == 'Active';

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
                        CircleAvatar(
                          backgroundColor: RevoTheme.primary.withValues(alpha:0.12),
                          child: Text(u['name']!.substring(0, 2).toUpperCase(), style: TextStyle(color: RevoTheme.primaryLight)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(u['name']!, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(u['email']!, style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary)),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(u['role']!, style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textSecondary)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isActive ? RevoTheme.success.withValues(alpha:0.15) : RevoTheme.warning.withValues(alpha:0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isActive ? RevoTheme.success.withValues(alpha:0.4) : RevoTheme.warning.withValues(alpha:0.4)),
                          ),
                          child: Text(
                            u['status']!,
                            style: GoogleFonts.inter(fontSize: 10, color: isActive ? RevoTheme.success : RevoTheme.warning, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 32),
                        IconButton(
                          icon: Icon(Icons.more_vert_rounded, color: RevoTheme.textSecondary, size: 16),
                          onPressed: () {},
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
}

// ==========================================
// 5. REVO SYSTEM SETTINGS SCREEN
// ==========================================
class RevoSettingsScreen extends StatefulWidget {
  const RevoSettingsScreen({super.key});

  @override
  State<RevoSettingsScreen> createState() => _RevoSettingsScreenState();
}

class _RevoSettingsScreenState extends State<RevoSettingsScreen> {
  bool _autosave = true;
  bool _enableLogs = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "System Settings",
            style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            "Configure workspace preferences, REST webhook secrets, and general configurations.",
            style: GoogleFonts.inter(fontSize: 13, color: RevoTheme.textSecondary),
          ),
          const SizedBox(height: 32),

          // Workspace Settings Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: RevoTheme.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: RevoTheme.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("General Settings", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildTextField("Workspace Domain Name", "revojourneytryone-admin-prod"),
                const SizedBox(height: 16),
                _buildSwitchRow("Automatic Step Auto-Save", _autosave, (val) => setState(() => _autosave = val)),
                const SizedBox(height: 8),
                _buildSwitchRow("Enable Verbose Application Logs", _enableLogs, (val) => setState(() => _enableLogs = val)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // API & Secrets Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: RevoTheme.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: RevoTheme.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Secrets & Security Keys", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildTextField("Global Secret Webhook Key", "shsec_9821_revo_champ_verification_jwt"),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: const Text("Settings updated successfully!"), backgroundColor: RevoTheme.success),
                    );
                  },
                  child: const Text("Save System Configuration"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String initial) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: TextEditingController(text: initial),
          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
          style: GoogleFonts.inter(fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildSwitchRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13)),
        Switch(value: value, activeColor: RevoTheme.primaryLight, onChanged: onChanged),
      ],
    );
  }
}

// ==========================================
// 6. REVO API HUB SCREEN
// ==========================================
class RevoApiHubScreen extends StatelessWidget {
  const RevoApiHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final connectors = [
      {'name': 'Get Vehicle Manufacturers', 'method': 'GET', 'url': 'https://api.revojourneytryone.com/v1/vehicles', 'status': 'Connected'},
      {'name': 'Verify PAN Card Number', 'method': 'POST', 'url': 'https://api.kycprovider.org/v1/pan-verify', 'status': 'Connected'},
      {'name': 'Calculate Policy Premium', 'method': 'POST', 'url': 'https://api.insuranceengine.net/premium', 'status': 'Testing'},
      {'name': 'Payment Processing Webhook', 'method': 'POST', 'url': 'https://api.stripe.com/v3/charges', 'status': 'Disconnected'},
    ];

    return Scaffold(
      backgroundColor: RevoTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
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
                      "API Connectors Hub",
                      style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Setup endpoint connectors that power your async dropdown selections and onSubmit validation actions.",
                      style: GoogleFonts.inter(fontSize: 13, color: RevoTheme.textSecondary),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_link_rounded, size: 16),
                  label: const Text("New Connector"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    backgroundColor: RevoTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            Expanded(
              child: ListView.builder(
                itemCount: connectors.length,
                itemBuilder: (context, index) {
                  final conn = connectors[index];
                  final isGET = conn['method'] == 'GET';
                  
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
                        // Method tag
                        Container(
                          width: 54,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: isGET ? RevoTheme.secondary.withValues(alpha:0.15) : RevoTheme.accent.withValues(alpha:0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            conn['method']!,
                            style: GoogleFonts.sourceCodePro(
                              fontSize: 11, 
                              color: isGET ? RevoTheme.secondary : RevoTheme.accent, 
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Name & Endpoint
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(conn['name']!, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(conn['url']!, style: GoogleFonts.sourceCodePro(fontSize: 10, color: RevoTheme.textSecondary)),
                            ],
                          ),
                        ),

                        // Status
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getConnStatusColor(conn['status']!).withValues(alpha:0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _getConnStatusColor(conn['status']!).withValues(alpha:0.4)),
                          ),
                          child: Text(
                            conn['status']!,
                            style: GoogleFonts.inter(fontSize: 10, color: _getConnStatusColor(conn['status']!), fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 24),

                        IconButton(
                          icon: Icon(Icons.settings_input_component_outlined, color: RevoTheme.primaryLight, size: 16),
                          onPressed: () {},
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

  Color _getConnStatusColor(String status) {
    if (status == 'Connected') return RevoTheme.success;
    if (status == 'Testing') return RevoTheme.warning;
    return RevoTheme.error;
  }
}

// ==========================================
// 7. REVO AUDIT LOGS SCREEN
// ==========================================
class RevoAuditLogsScreen extends StatelessWidget {
  const RevoAuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final logs = [
      {'user': 'admin@revojourneytryone.com', 'action': 'Published Motor Insurance v1.0.0', 'ip': '192.168.1.12', 'time': '10 mins ago'},
      {'user': 'sarah.k@revo.com', 'action': 'Created step: Nominee Details', 'ip': '192.168.1.48', 'time': '2 hours ago'},
      {'user': 'admin@revojourneytryone.com', 'action': 'Imported template ' 'User KYC Onboarding', 'ip': '192.168.1.12', 'time': '1 day ago'},
    ];

    return Scaffold(
      backgroundColor: RevoTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "System Audit Logs",
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              "Activity history tracking configuration updates, deployments, and access logs.",
              style: GoogleFonts.inter(fontSize: 13, color: RevoTheme.textSecondary),
            ),
            const SizedBox(height: 32),

            Expanded(
              child: ListView.builder(
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];

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
                        Icon(Icons.history_edu_outlined, color: RevoTheme.primaryLight, size: 20),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(log['action']!, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text("By ${log['user']} • IP: ${log['ip']}", style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary)),
                            ],
                          ),
                        ),
                        Text(log['time']!, style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textSecondary)),
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
}
