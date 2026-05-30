import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/journey_models.dart';
import 'journey_controller.dart';
import 'journey_history_manager.dart';

mixin JourneyImportManager on StateNotifier<JourneyConfig> {
  Ref get ref;

  bool updateFromJson(String jsonStr) {
    try {
      final rawDecoded = json.decode(jsonStr);
      final decoded = json.decode(json.encode(rawDecoded)) as Map<String, dynamic>;
      final newConfig = JourneyConfig.fromJson(decoded);
      state = newConfig;
      
      // Clear the history stack when a new JSON is completely loaded
      ref.read(historyProvider.notifier).reset(newConfig);

      // Reset active step to first step of the loaded configuration
      if (newConfig.steps.isNotEmpty) {
        ref.read(activeStepIdProvider.notifier).state = newConfig.steps.first.id;
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}