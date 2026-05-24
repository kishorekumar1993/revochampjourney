import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'core/navigation.dart';

void main() {
  runApp(
    const ProviderScope(
      child: RevoJourneyApp(),
    ),
  );
}

class RevoJourneyApp extends ConsumerWidget {
  const RevoJourneyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'RevoJourney Builder',
      debugShowCheckedModeBanner: false,
      theme: RevoTheme.getThemeData(false),
      darkTheme: RevoTheme.getThemeData(true),
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        RevoTheme.isDark = Theme.of(context).brightness == Brightness.dark;
        return child!;
      },
    );
  }
}
