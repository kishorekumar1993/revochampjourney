import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme.dart';
import '../../../journey_builder/presentation/providers/journey_provider.dart';

class RevoRunsScreen extends ConsumerStatefulWidget {
  const RevoRunsScreen({super.key});

  @override
  ConsumerState<RevoRunsScreen> createState() => _RevoRunsScreenState();
}

class _RevoRunsScreenState extends ConsumerState<RevoRunsScreen> {
  String _searchQuery = '';
  String _statusFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final runs = ref.watch(journeyRunsProvider);

    // Filter runs
    final filteredRuns = runs.where((run) {
      final matchesSearch = run['user'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          run['journeyName'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          run['id'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesStatus = _statusFilter == 'All' || run['status'] == _statusFilter;
      
      return matchesSearch && matchesStatus;
    }).toList();

    return Scaffold(
      backgroundColor: RevoTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Title Header
            Text(
              "Journey Runs Tracker",
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: RevoTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Monitor live customer form submissions, check validation states, and extract collected data.",
              style: GoogleFonts.inter(
                fontSize: 13,
                color: RevoTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 32),

            // 2. Filters & Search Bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search by Run ID, user email, or journey name...",
                      prefixIcon: Icon(Icons.search_rounded, size: 20, color: RevoTheme.textSecondary),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: RevoTheme.isDark ? const Color(0x12FFFFFF) : const Color(0x06000000),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: RevoTheme.cardBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _statusFilter,
                      dropdownColor: RevoTheme.cardBg,
                      style: GoogleFonts.inter(fontSize: 13, color: RevoTheme.textPrimary, fontWeight: FontWeight.w600),
                      items: ['All', 'Completed', 'In Progress', 'Draft', 'Failed Validation'].map((status) {
                        return DropdownMenuItem(value: status, child: Text(status));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _statusFilter = val;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 3. Runs List Table Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: RevoTheme.sidebarBackground,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Text("RUN ID", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: RevoTheme.textSecondary))),
                  Expanded(flex: 3, child: Text("JOURNEY", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: RevoTheme.textSecondary))),
                  Expanded(flex: 4, child: Text("USER / APPLICANT", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: RevoTheme.textSecondary))),
                  Expanded(flex: 3, child: Text("PROGRESS / STEP", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: RevoTheme.textSecondary))),
                  Expanded(flex: 2, child: Text("STATUS", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: RevoTheme.textSecondary))),
                  Expanded(flex: 2, child: Text("STARTED", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: RevoTheme.textSecondary))),
                  const SizedBox(width: 48), // Padding matching view button
                ],
              ),
            ),

            // 4. Table Body List
            Expanded(
              child: filteredRuns.isEmpty
                  ? Center(
                      child: Text(
                        "No runs match the filter query.",
                        style: GoogleFonts.inter(color: RevoTheme.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredRuns.length,
                      itemBuilder: (context, index) {
                        final run = filteredRuns[index];
                        final progress = run['progress'] as double;
                        final percentage = (progress * 100).round();
                        
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: RevoTheme.cardBg,
                            border: Border(
                              bottom: BorderSide(color: RevoTheme.cardBorder, width: 0.5),
                            ),
                          ),
                           child: Row(
                            children: [
                              // ID
                              Expanded(
                                flex: 2,
                                child: Text(
                                  run['id'],
                                  style: GoogleFonts.sourceCodePro(
                                    fontWeight: FontWeight.bold,
                                    color: RevoTheme.primaryLight,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Journey Name
                              Expanded(
                                flex: 3,
                                child: Text(
                                  run['journeyName'],
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    color: RevoTheme.textPrimary,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // User
                              Expanded(
                                flex: 4,
                                child: Text(
                                  run['user'],
                                  style: GoogleFonts.inter(
                                    color: RevoTheme.textSecondary,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Progress / Step
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: LinearProgressIndicator(
                                              value: progress,
                                              backgroundColor: RevoTheme.isDark ? const Color(0xFF2C2C4A) : const Color(0xFFE2E8F0),
                                              color: _getProgressColor(run['status']),
                                              minHeight: 5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "$percentage%",
                                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${run['currentStep']} (${run['stepsCount']})",
                                      style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              // Status
                              Expanded(
                                flex: 2,
                                child: Container(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusBgColor(run['status']),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: _getStatusTextColor(run['status']).withValues(alpha:0.4)),
                                    ),
                                    child: Text(
                                      run['status'],
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        color: _getStatusTextColor(run['status']),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Started
                              Expanded(
                                flex: 2,
                                child: Text(
                                  run['started'],
                                  style: GoogleFonts.inter(
                                    color: RevoTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Actions
                              IconButton(
                                icon: Icon(Icons.analytics_rounded, color: RevoTheme.primaryLight, size: 20),
                                tooltip: "Inspect Submitted Data",
                                onPressed: () => _showInspectDataDialog(context, run),
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

  Color _getProgressColor(String status) {
    switch (status) {
      case 'Completed':
        return RevoTheme.success;
      case 'Failed Validation':
        return RevoTheme.error;
      case 'Draft':
        return RevoTheme.textSecondary;
      case 'In Progress':
      default:
        return RevoTheme.primary;
    }
  }

  Color _getStatusBgColor(String status) {
    final color = _getStatusTextColor(status);
    return color.withValues(alpha:0.15);
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'Completed':
        return RevoTheme.success;
      case 'Failed Validation':
        return RevoTheme.error;
      case 'Draft':
        return RevoTheme.textSecondary;
      case 'In Progress':
      default:
        return RevoTheme.accent;
    }
  }

  void _showInspectDataDialog(BuildContext context, Map<String, dynamic> run) {
    final dataMap = Map<String, dynamic>.from(run['data'] as Map? ?? {});
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: RevoTheme.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: RevoTheme.cardBorder),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Inspect Run: ${run['id']}",
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusTextColor(run['status']).withValues(alpha:0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _getStatusTextColor(run['status']).withValues(alpha:0.4)),
              ),
              child: Text(
                run['status'],
                style: GoogleFonts.inter(fontSize: 10, color: _getStatusTextColor(run['status']), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Journey Name: ${run['journeyName']}",
                style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              Divider(color: RevoTheme.cardBorder),
              const SizedBox(height: 8),
              Text(
                "Captured Data Fields:",
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: RevoTheme.primaryLight),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: dataMap.length,
                  itemBuilder: (context, index) {
                    final key = dataMap.keys.elementAt(index);
                    final value = dataMap[key]?.toString() ?? '';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              key,
                              style: GoogleFonts.sourceCodePro(fontSize: 12, color: RevoTheme.textSecondary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: Text(
                              value,
                              style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textPrimary, fontWeight: FontWeight.w600),
                            ),
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
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }
}
