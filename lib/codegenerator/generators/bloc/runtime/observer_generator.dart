// lib/bloc/generators/observer/observer_generator.dart
//
// Generates AppBlocObserver — logs every event, transition, and error.
// Written once into core/observer/ and shared by every feature.

class ObserverGenerator {
  const ObserverGenerator();

  String generate() => r"""
import 'package:flutter_bloc/flutter_bloc.dart';

/// Global BLoC observer — logs all events, transitions, and errors.
/// Registered in main.dart:  Bloc.observer = AppBlocObserver();
class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    _log('onCreate', '${bloc.runtimeType}');
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    _log('onEvent', '${bloc.runtimeType} ← ${event.runtimeType}\n  $event');
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    _log('onChange', '${bloc.runtimeType}\n'
        '  current : ${change.currentState}\n'
        '  next    : ${change.nextState}');
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    _log('onTransition', '${bloc.runtimeType} via ${transition.event.runtimeType}');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    _log('onError', '${bloc.runtimeType}\n  $error', isError: true);
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    _log('onClose', '${bloc.runtimeType}');
  }

  void _log(String label, String message, {bool isError = false}) {
    // ignore: avoid_print
    print('[BLoC][$label] $message');
  }
}
""";
}
