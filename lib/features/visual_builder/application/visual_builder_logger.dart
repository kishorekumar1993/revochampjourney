// lib/features/visual_builder/application/visual_builder_logger.dart

import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

abstract final class VisualBuilderLogger {
  static void log(String category, String message, {LogLevel level = LogLevel.info, Object? error, StackTrace? stackTrace}) {
    final levelStr = level.name.toUpperCase();
    final logMessage = '[$levelStr][VisualBuilder][$category] $message';

    if (kDebugMode) {
      print(logMessage);
      if (error != null) print('  Error: $error');
      if (stackTrace != null) print('  StackTrace: $stackTrace');
    }

    dev.log(
      message,
      name: 'visual_builder.$category',
      error: error,
      stackTrace: stackTrace,
      level: _getDevLevel(level),
    );
  }

  static int _getDevLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug: return 500;
      case LogLevel.info: return 800;
      case LogLevel.warning: return 900;
      case LogLevel.error: return 1000;
    }
  }
}
