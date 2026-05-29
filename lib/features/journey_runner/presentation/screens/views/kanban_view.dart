import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../journey_builder/data/models.dart';

class _IT {
  static const brand = Color(0xFF5B4FCF);
  static const brandSurface = Color(0xFFEEECFD);
  static const white = Color(0xFFFFFFFF);
  static const textDark = Color(0xFF1A1A2E);
  static const textMid = Color(0xFF6B7280);
  static const border = Color(0xFFE4E6F0);
  static const bg = Color(0xFFF7F8FC);
  static const success = Color(0xFF22C55E);
  static const textLight = Color(0xFFB0B4C8);
}

class KanbanRunnerView extends StatefulWidget {
  final JourneyConfig cfg;
  final JourneyStep activeStep;
  final int activeIdx;
  final Widget Function(BuildContext, {bool isMobile}) formContentBuilder;
  final Widget Function() bottomBarBuilder;
  final Function(int)? onStepTap;

  const KanbanRunnerView({
    super.key,
    required this.cfg,
    required this.activeStep,
    required this.activeIdx,
    required this.formContentBuilder,
    required this.bottomBarBuilder,
    this.onStepTap,
  });

  @override
  State<KanbanRunnerView> createState() => _KanbanRunnerViewState();
}

class _KanbanRunnerViewState extends State<KanbanRunnerView> with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    // Split steps by status
    final completedSteps = <Map<String, dynamic>>[];
    final inProgressSteps = <Map<String, dynamic>>[];
    final todoSteps = <Map<String, dynamic>>[];

    for (int i = 0; i < widget.cfg.steps.length; i++) {
      final s = widget.cfg.steps[i];
      final item = {'step': s, 'index': i};
      if (i < widget.activeIdx) {
        completedSteps.add(item);
      } else if (i == widget.activeIdx) {
        inProgressSteps.add(item);
      } else {
        todoSteps.add(item);
      }
    }

    return Column(
      children: [
        if (isMobile) ...[
          // Tab bar switcher for mobile Kanban
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: _IT.brand,
              unselectedLabelColor: _IT.textMid,
              indicatorColor: _IT.brand,
              labelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
              tabs: [
                Tab(text: 'Completed (${completedSteps.length})'),
                Tab(text: 'In Progress (${inProgressSteps.length})'),
                Tab(text: 'To Do (${todoSteps.length})'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildColumnContainer('Completed', completedSteps, Colors.green[50]!, _IT.success, isMobile, context),
                _buildColumnContainer('In Progress', inProgressSteps, _IT.brandSurface, _IT.brand, isMobile, context),
                _buildColumnContainer('To Do', todoSteps, Colors.grey[100]!, _IT.textMid, isMobile, context),
              ],
            ),
          ),
        ] else
          Expanded(
            child: Container(
              color: _IT.bg,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _buildColumnContainer('Completed', completedSteps, Colors.green[50]!, _IT.success, isMobile, context),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildColumnContainer('In Progress', inProgressSteps, _IT.brandSurface, _IT.brand, isMobile, context),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildColumnContainer('To Do', todoSteps, Colors.grey[100]!, _IT.textMid, isMobile, context),
                  ),
                ],
              ),
            ),
          ),
        widget.bottomBarBuilder(),
      ],
    );
  }

  Widget _buildColumnContainer(
    String title,
    List<Map<String, dynamic>> items,
    Color bgHeaderColor,
    Color accentColor,
    bool isMobile,
    BuildContext context,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _IT.border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bgHeaderColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: accentColor == _IT.textMid ? _IT.textDark : accentColor,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${items.length}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: accentColor == _IT.textMid ? _IT.textDark : accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Cards list
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'No steps in this column',
                      style: GoogleFonts.poppins(fontSize: 12, color: _IT.textLight),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    itemBuilder: (context, idx) {
                      final item = items[idx];
                      final step = item['step'] as JourneyStep;
                      final sIdx = item['index'] as int;

                      final isCompleted = sIdx < widget.activeIdx;
                      final isActive = sIdx == widget.activeIdx;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isActive ? _IT.brand : _IT.border,
                            width: isActive ? 1.5 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Row(
                                children: [
                                  Icon(
                                    isCompleted
                                        ? Icons.check_circle_rounded
                                        : (isActive ? Icons.pending_rounded : Icons.lock_rounded),
                                    color: accentColor,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      step.title,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _IT.textDark,
                                      ),
                                    ),
                                  ),
                                  if (isCompleted || isActive)
                                    IconButton(
                                      icon: const Icon(Icons.edit_rounded, size: 14, color: _IT.brand),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        if (widget.onStepTap != null) widget.onStepTap!(sIdx);
                                      },
                                    ),
                                ],
                              ),
                            ),
                            if (isActive) ...[
                              const Divider(color: _IT.border, height: 1),
                              Padding(
                                padding: const EdgeInsets.all(14.0),
                                child: widget.formContentBuilder(context, isMobile: isMobile),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
