import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revojourneytryone/features/journey_builder/domain/entities/journey_models.dart';
import 'journey_config_notifier.dart';
import 'initial_journey.dart';

class JourneysListNotifier extends StateNotifier<List<JourneyConfig>> {
  JourneysListNotifier(super.initial);

  void addJourney(JourneyConfig config) {
    if (!state.any((j) => j.journeyName == config.journeyName)) {
      state = [...state, config];
    }
  }

  void removeJourney(String name) {
    state = state.where((j) => j.journeyName != name).toList();
  }

  void saveJourney(JourneyConfig config) {
    final index = state.indexWhere((j) => j.journeyName == config.journeyName);
    if (index != -1) {
      final updatedList = List<JourneyConfig>.from(state);
      updatedList[index] = config;
      state = updatedList;
    } else {
      state = [...state, config];
    }
  }
}

final journeysListProvider =
    StateNotifierProvider<JourneysListNotifier, List<JourneyConfig>>((ref) {
      final notifier = JourneysListNotifier([getInitialJourney()]);
      Timer? debounceTimer;
      ref.listen<JourneyConfig>(journeyConfigProvider, (prev, next) {
        debounceTimer?.cancel();
        debounceTimer = Timer(const Duration(milliseconds: 500), () {
          notifier.saveJourney(next);
        });
      });
      ref.onDispose(() {
        debounceTimer?.cancel();
      });
      return notifier;
    });
