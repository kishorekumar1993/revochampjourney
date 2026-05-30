import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/features/visual_builder/application/studio_providers.dart';
import 'package:revojourneytryone/features/builder_workspace/presentation/provider/builder_mode_provider.dart';
import 'dashboard_actions.dart';

class DashboardHeader extends ConsumerWidget implements PreferredSizeWidget {
  final dynamic journeyConfig;

  const DashboardHeader({super.key, required this.journeyConfig});

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 1350;
    final showSteps = ref.watch(showStepsPanelProvider);
    final showProps = ref.watch(showPropertiesPanelProvider);
    final isSidebarCollapsed = ref.watch(dashboardIsSidebarCollapsedProvider);
    final activeMenu = ref.watch(dashboardActiveMenuProvider);
    final isEditingJourney = ref.watch(dashboardIsEditingJourneyProvider);
    final environment = ref.watch(dashboardEnvironmentProvider);

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: RevoTheme.sidebarBackground,
        border: Border(
          bottom: BorderSide(color: RevoTheme.cardBorder, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left breadcrumb / Environment indicator
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    isSidebarCollapsed ? Icons.menu_rounded : Icons.menu_open_rounded,
                    color: RevoTheme.textPrimary,
                    size: 20,
                  ),
                  tooltip: isSidebarCollapsed ? "Expand Sidebar" : "Collapse Sidebar",
                  onPressed: () {
                    ref.read(dashboardIsSidebarCollapsedProvider.notifier).state = !isSidebarCollapsed;
                  },
                ),
                const SizedBox(width: 8),
                if (activeMenu == 'journeys' && isEditingJourney) ...[
                  IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: RevoTheme.textPrimary, size: 20),
                    tooltip: "Back to Catalog",
                    onPressed: () {
                      ref.read(dashboardIsEditingJourneyProvider.notifier).state = false;
                      ref.read(dashboardIsSidebarCollapsedProvider.notifier).state = false;
                    },
                  ),
                  const SizedBox(width: 8),
                ] else ...[
                  Icon(Icons.settings_outlined, color: RevoTheme.textSecondary, size: 20),
                ],
                const SizedBox(width: 24),
                // Environment Switcher dropdown mockup
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: RevoTheme.cardBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: RevoTheme.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: RevoTheme.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isCompact ? "Prod" : "Environment: $environment",
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: RevoTheme.textSecondary),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Action buttons & Icons
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isEditingJourney) ...[
                    if (isCompact) ...[
                      IconButton(
                        icon: Icon(
                          showSteps ? Icons.format_list_bulleted_rounded : Icons.list_rounded,
                          color: showSteps ? RevoTheme.primaryLight : RevoTheme.textSecondary,
                          size: 20,
                        ),
                        tooltip: showSteps ? "Hide Steps Panel" : "Show Steps Panel",
                        onPressed: () {
                          ref.read(showStepsPanelProvider.notifier).state = !showSteps;
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          showProps ? Icons.tune_rounded : Icons.tune_outlined,
                          color: showProps ? RevoTheme.primaryLight : RevoTheme.textSecondary,
                          size: 20,
                        ),
                        tooltip: showProps ? "Hide Properties Panel" : "Show Properties Panel",
                        onPressed: () {
                          ref.read(showPropertiesPanelProvider.notifier).state = !showProps;
                        },
                      ),
                    ] else ...[
                      OutlinedButton.icon(
                        onPressed: () {
                          ref.read(showStepsPanelProvider.notifier).state = !showSteps;
                        },
                        icon: Icon(
                          showSteps ? Icons.format_list_bulleted_rounded : Icons.list_rounded,
                          size: 16,
                          color: showSteps ? RevoTheme.primaryLight : RevoTheme.textSecondary,
                        ),
                        label: Text(
                          showSteps ? "Hide Steps" : "Show Steps",
                          style: TextStyle(
                            fontSize: 11,
                            color: showSteps ? RevoTheme.textPrimary : RevoTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          side: BorderSide(
                            color: showSteps ? RevoTheme.primary.withValues(alpha:0.5) : RevoTheme.cardBorder,
                          ),
                          backgroundColor: showSteps ? RevoTheme.primary.withValues(alpha:0.08) : Colors.transparent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          ref.read(showPropertiesPanelProvider.notifier).state = !showProps;
                        },
                        icon: Icon(
                          showProps ? Icons.tune_rounded : Icons.tune_outlined,
                          size: 16,
                          color: showProps ? RevoTheme.primaryLight : RevoTheme.textSecondary,
                        ),
                        label: Text(
                          showProps ? "Hide Props" : "Show Props",
                          style: TextStyle(
                            fontSize: 11,
                            color: showProps ? RevoTheme.textPrimary : RevoTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          side: BorderSide(
                            color: showProps ? RevoTheme.primary.withValues(alpha:0.5) : RevoTheme.cardBorder,
                          ),
                          backgroundColor: showProps ? RevoTheme.primary.withValues(alpha:0.08) : Colors.transparent,
                        ),
                      ),
                    ],
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 24,
                      child: VerticalDivider(color: RevoTheme.cardBorder, width: 1),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (isCompact) ...[
                    Tooltip(
                      message: "Export JSON",
                      child: OutlinedButton(
                        onPressed: () => DashboardActions.exportJson(context, journeyConfig.toJson()),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(12),
                          minimumSize: Size.zero,
                        ),
                        child: const Icon(Icons.download_rounded, size: 16),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: "Import JSON",
                      child: OutlinedButton(
                        onPressed: () => DashboardActions.importJsonDialog(context, ref),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(12),
                          minimumSize: Size.zero,
                        ),
                        child: const Icon(Icons.upload_file_rounded, size: 16),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: "Generate Code",
                      child: OutlinedButton(
                        onPressed: () => DashboardActions.generateBlocCode(context, ref, journeyConfig),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(12),
                          minimumSize: Size.zero,
                        ),
                        child: const Icon(Icons.code_rounded, size: 16),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: "Run Journey",
                      child: ElevatedButton(
                        onPressed: () {
                          context.push('/runner');
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(12),
                          minimumSize: Size.zero,
                          backgroundColor: RevoTheme.primary,
                        ),
                        child: const Icon(Icons.play_arrow_rounded, size: 16),
                      ),
                    ),
                  ] else ...[
                    OutlinedButton.icon(
                      onPressed: () => DashboardActions.exportJson(context, journeyConfig.toJson()),
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: const Text("Export JSON"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () => DashboardActions.importJsonDialog(context, ref),
                      icon: const Icon(Icons.upload_file_rounded, size: 16),
                      label: const Text("Import JSON"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () => DashboardActions.generateBlocCode(context, ref, journeyConfig),
                      icon: const Icon(Icons.code_rounded, size: 16),
                      label: const Text("Generate Code"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.push('/runner');
                      },
                      icon: const Icon(Icons.play_arrow_rounded, size: 16),
                      label: const Text("Run Journey"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        backgroundColor: RevoTheme.primary,
                      ),
                    ),
                  ],
                  const SizedBox(width: 24),
                  // Profile icons
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      IconButton(
                        icon: Icon(Icons.notifications_none_rounded, color: RevoTheme.textSecondary),
                        onPressed: () {},
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Text(
                            "3",
                            style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: Icon(
                      ref.watch(themeModeProvider) == ThemeMode.dark
                          ? Icons.wb_sunny_outlined
                          : Icons.dark_mode_outlined,
                      color: RevoTheme.textSecondary,
                    ),
                    onPressed: () {
                      final themeNotifier = ref.read(themeModeProvider.notifier);
                      themeNotifier.state = themeNotifier.state == ThemeMode.dark
                          ? ThemeMode.light
                          : ThemeMode.dark;
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
