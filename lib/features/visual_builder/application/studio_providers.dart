// lib/features/visual_builder/application/studio_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'variables_provider.dart';
export 'api_studio_provider.dart';
export 'database_studio_provider.dart';
export 'theme_studio_provider.dart';

// ─── Dashboard & Visual Builder Selection Providers ───────────────────────────

final dashboardActiveMenuProvider = StateProvider<String>((ref) => 'dashboard');
final dashboardEnvironmentProvider = StateProvider<String>((ref) => 'Production');
final dashboardIsEditingJourneyProvider = StateProvider<bool>((ref) => false);
final dashboardIsSidebarCollapsedProvider = StateProvider<bool>((ref) => false);

final activeSidebarTabProvider = StateProvider<String>((ref) => 'Journey Flow');

final selectedApiConfigIdProvider = StateProvider<String?>((ref) => null);

final canvasIsDraggingProvider = StateProvider<bool>((ref) => false);

