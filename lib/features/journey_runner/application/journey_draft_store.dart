import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/journey_execution_models.dart';

/// In-memory draft storage keyed by journey name (session-scoped).
class JourneyDraftStore extends StateNotifier<Map<String, JourneyDraft>> {
  JourneyDraftStore() : super({});

  JourneyDraft? getDraft(String journeyName) => state[journeyName];

  void saveDraft(JourneyDraft draft) {
    state = {...state, draft.journeyName: draft};
  }

  void clearDraft(String journeyName) {
    if (!state.containsKey(journeyName)) return;
    final next = Map<String, JourneyDraft>.from(state)..remove(journeyName);
    state = next;
  }
}

final journeyDraftStoreProvider =
    StateNotifierProvider<JourneyDraftStore, Map<String, JourneyDraft>>((ref) {
  return JourneyDraftStore();
});
