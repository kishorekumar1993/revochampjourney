import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/journey_models.dart';
import 'journey_controller.dart';

// History State for Undo/Redo operations
class HistoryState {
  final List<JourneyConfig> past;
  final JourneyConfig present;
  final List<JourneyConfig> future;

  HistoryState({
    required this.past,
    required this.present,
    required this.future,
  });
}

class HistoryNotifier extends StateNotifier<HistoryState> {
  final Ref _ref;
  static const int maxHistoryLength = 50;
  bool _isUndoing = false;

  HistoryNotifier(this._ref, JourneyConfig initial)
      : super(HistoryState(past: [], present: initial, future: []));

  void push(JourneyConfig nextConfig) {
    if (_isUndoing) return;
    var newPast = [...state.past, state.present.copyWith()];
    if (newPast.length > maxHistoryLength) {
      newPast = newPast.sublist(newPast.length - maxHistoryLength);
    }
    state = HistoryState(
      past: newPast,
      present: nextConfig,
      future: [],
    );
  }

  void undo() {
    if (state.past.isEmpty) return;
    final previous = state.past.last;
    final newPast = state.past.sublist(0, state.past.length - 1);
    state = HistoryState(
      past: newPast,
      present: previous,
      future: [state.present.copyWith(), ...state.future],
    );
    _applyToConfig(state.present);
  }

  void redo() {
    if (state.future.isEmpty) return;
    final next = state.future.first;
    final newFuture = state.future.sublist(1);
    state = HistoryState(
      past: [...state.past, state.present.copyWith()],
      present: next,
      future: newFuture,
    );
    _applyToConfig(state.present);
  }

  void reset(JourneyConfig config) {
    state = HistoryState(past: [], present: config, future: []);
    _applyToConfig(config);
  }

  void rollbackTo(int pastIndex) {
    if (pastIndex < 0 || pastIndex >= state.past.length) return;
    final target = state.past[pastIndex];
    final newPast = state.past.sublist(0, pastIndex);
    final newFuture = [
      ...state.past.sublist(pastIndex + 1),
      state.present.copyWith(),
      ...state.future
    ];
    state = HistoryState(
      past: newPast,
      present: target,
      future: newFuture,
    );
    _applyToConfig(state.present);
  }

  void _applyToConfig(JourneyConfig config) {
    _isUndoing = true;
    _ref.read(journeyConfigProvider.notifier).syncWithHistory(config);
    _isUndoing = false;
  }
}

final historyProvider = StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  final notifier = HistoryNotifier(ref, getInitialJourney());
  ref.listen<JourneyConfig>(journeyConfigProvider, (prev, next) {
    notifier.push(next);
  });
  return notifier;
});