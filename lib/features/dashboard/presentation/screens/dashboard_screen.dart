import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revojourneytryone/features/visual_builder/application/studio_providers.dart';
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/features/builder_workspace/presentation/screen/builder_workspace_screen.dart';
import 'package:revojourneytryone/features/journey_builder/data/models.dart';
import 'package:revojourneytryone/features/journey_builder/presentation/providers/journey_provider.dart';
import 'package:revojourneytryone/features/journey_builder/presentation/widgets/sidebar.dart';
import 'templates_screen.dart';
import 'journeys_screen.dart';
import 'runs_screen.dart';
import 'misc_screens.dart';
import 'dashboard_splits/dashboard_header.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journeyConfig = ref.watch(journeyConfigProvider);
    final activeMenu = ref.watch(dashboardActiveMenuProvider);
    final isEditingJourney = ref.watch(dashboardIsEditingJourneyProvider);
    final isSidebarCollapsed = ref.watch(dashboardIsSidebarCollapsedProvider);

    return Scaffold(
      backgroundColor: RevoTheme.background,
      body: Row(
        children: [
          // 1. Sidebar Menu (Leftmost)
          RevoSidebar(
            activeMenu: activeMenu,
            isCollapsed: isSidebarCollapsed,
            onMenuChanged: (menu) {
              ref.read(dashboardActiveMenuProvider.notifier).state = menu;
              ref.read(dashboardIsEditingJourneyProvider.notifier).state = false;
            },
          ),

          // Main content container
          Expanded(
            child: Column(
              children: [
                // 2. Top Header Navigation Bar
                DashboardHeader(journeyConfig: journeyConfig),
                
                // 3. Lower Content Panels (3 columns layout or Templates Screen)
                Expanded(
                  child: activeMenu == 'templates'
                      ? RevoTemplatesScreen(
                          onTemplateLoaded: () {
                            ref.read(dashboardActiveMenuProvider.notifier).state = 'journeys';
                            ref.read(dashboardIsEditingJourneyProvider.notifier).state = true;
                            ref.read(dashboardIsSidebarCollapsedProvider.notifier).state = true;
                          },
                        )
                      : activeMenu == 'runs'
                          ? RevoRunsScreen()
                          : activeMenu == 'dashboard'
                              ? RevoDashboardOverviewScreen(
                                  onCreateNew: () {
                                    final blank = JourneyConfig(journeyName: "New Journey", version: "1.0.0", steps: []);
                                    ref.read(journeyConfigProvider.notifier).updateFromJson(json.encode(blank.toJson()));
                                    ref.read(dashboardActiveMenuProvider.notifier).state = 'journeys';
                                    ref.read(dashboardIsEditingJourneyProvider.notifier).state = true;
                                    ref.read(dashboardIsSidebarCollapsedProvider.notifier).state = true;
                                  },
                                  onEditJourney: (journey) {
                                    ref.read(journeyConfigProvider.notifier).updateFromJson(json.encode(journey.toJson()));
                                    ref.read(dashboardActiveMenuProvider.notifier).state = 'journeys';
                                    ref.read(dashboardIsEditingJourneyProvider.notifier).state = true;
                                    ref.read(dashboardIsSidebarCollapsedProvider.notifier).state = true;
                                  },
                                  onViewCatalog: () {
                                    ref.read(dashboardActiveMenuProvider.notifier).state = 'journeys';
                                    ref.read(dashboardIsEditingJourneyProvider.notifier).state = false;
                                  },
                                  onViewTemplates: () {
                                    ref.read(dashboardActiveMenuProvider.notifier).state = 'templates';
                                  },
                                  onViewRuns: () {
                                    ref.read(dashboardActiveMenuProvider.notifier).state = 'runs';
                                  },
                                )
                              : activeMenu == 'analytics'
                                  ? RevoAnalyticsScreen()
                                  : activeMenu == 'approvals'
                                      ? RevoApprovalsScreen()
                                      : activeMenu == 'users'
                                          ? RevoUsersScreen()
                                          : activeMenu == 'settings'
                                              ? RevoSettingsScreen()
                                              : activeMenu == 'api_hub'
                                                  ? RevoApiHubScreen()
                                                  : activeMenu == 'audit_logs'
                                                      ? RevoAuditLogsScreen()
                                                      : activeMenu == 'journeys' && !isEditingJourney
                                                          ? RevoJourneysScreen(
                                                              onEditJourney: (journey) {
                                                                ref.read(journeyConfigProvider.notifier).updateFromJson(json.encode(journey.toJson()));
                                                                ref.read(dashboardIsEditingJourneyProvider.notifier).state = true;
                                                                ref.read(dashboardIsSidebarCollapsedProvider.notifier).state = true;
                                                              },
                                                              onCreateNew: () {
                                                                final blank = JourneyConfig(journeyName: "New Journey", version: "1.0.0", steps: []);
                                                                ref.read(journeyConfigProvider.notifier).updateFromJson(json.encode(blank.toJson()));
                                                                ref.read(dashboardIsEditingJourneyProvider.notifier).state = true;
                                                                ref.read(dashboardIsSidebarCollapsedProvider.notifier).state = true;
                                                              },
                                                            )
                                                          : const BuilderWorkspaceScreen(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
