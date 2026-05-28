// lib/bloc/generators/runtime_sources.dart
// All core runtime files emitted verbatim into lib/bloc/core/runtime/

abstract final class RuntimeSources {
  // ─────────────────────────────────────────────────────────────────────────
  // failure.dart  — replaces the old bare Failure inside async_state
  // ─────────────────────────────────────────────────────────────────────────
  static const String failure = r"""
// lib/bloc/core/runtime/failure.dart
import 'package:equatable/equatable.dart';

class Failure extends Equatable {
  const Failure({
    required this.message,
    this.code = 'unknown',
    this.retryable = false,
    this.statusCode,
  });

  final String  message;
  final String  code;
  final bool    retryable;
  final int?    statusCode;

  @override
  List<Object?> get props => [message, code, retryable, statusCode];

  @override
  String toString() => 'Failure(code: $code, message: $message)';
}
""";

  // ─────────────────────────────────────────────────────────────────────────
  // async_state.dart
  // ─────────────────────────────────────────────────────────────────────────
  static const String asyncState = r"""
// lib/bloc/core/runtime/async_state.dart
import 'package:equatable/equatable.dart';
import 'failure.dart';

export 'failure.dart';

sealed class AsyncState<T> extends Equatable {
  const AsyncState();

  bool get isIdle    => this is AsyncIdle<T>;
  bool get isLoading => this is AsyncLoading<T>;
  bool get isSuccess => this is AsyncSuccess<T>;
  bool get isFailure => this is AsyncFailure<T>;
  bool get isEmpty   => this is AsyncEmpty<T>;

  /// True while a request is in-flight.
  bool get isBusy => this is AsyncLoading<T>;

  /// Returns data if in success state, otherwise null.
  T? get dataOrNull => switch (this) {
    AsyncSuccess<T>(data: final d) => d,
    _ => null,
  };

  /// Returns the Failure if in failure state, otherwise null.
  Failure? get failureOrNull => switch (this) {
    AsyncFailure<T>(failure: final f) => f,
    _ => null,
  };

  R when<R>({
    required R Function()        idle,
    required R Function()        loading,
    required R Function(T data)  success,
    required R Function(Failure) onFailure,
    R Function()?                empty,
  }) => switch (this) {
    AsyncIdle<T>()                  => idle(),
    AsyncLoading<T>()               => loading(),
    AsyncSuccess<T>(:final data)    => success(data),
    AsyncFailure<T>(:final failure) => onFailure(failure),
    AsyncEmpty<T>()                 => empty != null ? empty() : idle(),
  };

  R maybeWhen<R>({
    R Function()?        idle,
    R Function()?        loading,
    R Function(T data)?  success,
    R Function(Failure)? onFailure,
    R Function()?        empty,
    required R Function() orElse,
  }) => switch (this) {
    AsyncIdle<T>()                  => idle?.call()        ?? orElse(),
    AsyncLoading<T>()               => loading?.call()     ?? orElse(),
    AsyncSuccess<T>(:final data)    => success?.call(data) ?? orElse(),
    AsyncFailure<T>(:final failure) => onFailure?.call(failure) ?? orElse(),
    AsyncEmpty<T>()                 => empty?.call()       ?? orElse(),
  };
}

/// Initial / reset — no request has been made yet.
final class AsyncIdle<T> extends AsyncState<T> {
  const AsyncIdle();
  @override List<Object?> get props => const [];
}

/// A request is in-flight.
final class AsyncLoading<T> extends AsyncState<T> {
  const AsyncLoading();
  @override List<Object?> get props => const [];
}

/// Request succeeded with data.
final class AsyncSuccess<T> extends AsyncState<T> {
  const AsyncSuccess(this.data);
  final T data;
  @override List<Object?> get props => [data];
}

/// Request succeeded but the result set is empty.
final class AsyncEmpty<T> extends AsyncState<T> {
  const AsyncEmpty();
  @override List<Object?> get props => const [];
}

/// Request failed.
final class AsyncFailure<T> extends AsyncState<T> {
  const AsyncFailure(this.failure);
  final Failure failure;
  @override List<Object?> get props => [failure];
}
""";

  // ─────────────────────────────────────────────────────────────────────────
  // validation_error.dart
  // ─────────────────────────────────────────────────────────────────────────
  static const String validationError = r"""
// lib/bloc/core/runtime/validation_error.dart
import 'package:equatable/equatable.dart';

class ValidationError extends Equatable {
  const ValidationError({required this.field, required this.message});

  final String field;
  final String message;

  @override
  List<Object?> get props => [field, message];
}
""";

  // ─────────────────────────────────────────────────────────────────────────
  // validator.dart
  // ─────────────────────────────────────────────────────────────────────────
  static const String validator = r"""
// lib/bloc/core/runtime/validator.dart
import 'validation_error.dart';

typedef ValidationResult = List<ValidationError>;
typedef FieldValidator<T> = ValidationError? Function(T? value);

class Validators {
  static FieldValidator<String> required(String field, [String? msg]) =>
      (v) => (v == null || v.trim().isEmpty)
          ? ValidationError(field: field, message: msg ?? '$field is required')
          : null;

  static FieldValidator<String> minLength(String field, int min) =>
      (v) => (v != null && v.length < min)
          ? ValidationError(field: field, message: '$field must be at least $min characters')
          : null;

  static FieldValidator<String> maxLength(String field, int max) =>
      (v) => (v != null && v.length > max)
          ? ValidationError(field: field, message: '$field must be at most $max characters')
          : null;

  static FieldValidator<String> email(String field) =>
      (v) => (v != null &&
              v.isNotEmpty &&
              !RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(v))
          ? ValidationError(field: field, message: 'Enter a valid email')
          : null;

  static FieldValidator<String> phone(String field) =>
      (v) => (v != null &&
              v.isNotEmpty &&
              !RegExp(r'^\+?[0-9\s\-\(\)]{7,15}$').hasMatch(v))
          ? ValidationError(field: field, message: 'Enter a valid phone number')
          : null;

  static FieldValidator<String> regex(
          String field, String pattern, String msg) =>
      (v) => (v != null &&
              v.isNotEmpty &&
              !RegExp(pattern).hasMatch(v))
          ? ValidationError(field: field, message: msg)
          : null;

  static FieldValidator<num?> min(String field, num minVal) =>
      (v) => (v != null && v < minVal)
          ? ValidationError(field: field, message: '$field must be ≥ $minVal')
          : null;

  static FieldValidator<num?> max(String field, num maxVal) =>
      (v) => (v != null && v > maxVal)
          ? ValidationError(field: field, message: '$field must be ≤ $maxVal')
          : null;

  static ValidationResult combine(List<FieldValidator> validators, dynamic value) {
    final errors = <ValidationError>[];
    for (final v in validators) {
      final e = v(value);
      if (e != null) errors.add(e);
    }
    return errors;
  }
}
""";

  // ─────────────────────────────────────────────────────────────────────────
  // reactive_value.dart
  // ─────────────────────────────────────────────────────────────────────────
  static const String reactiveValue = r"""
// lib/bloc/core/runtime/reactive_value.dart
import 'package:equatable/equatable.dart';
import 'validation_error.dart';

class ReactiveValue<T> extends Equatable {
  /// Initial, untouched state. const-constructable for use as default params.
  const ReactiveValue.pure(this.value)
      : error     = null,
        isDirty   = false,
        isTouched = false;

  /// Value changed by the user.
  const ReactiveValue.dirty(this.value, {this.error})
      : isDirty   = true,
        isTouched = true;

  const ReactiveValue._({
    required this.value,
    this.error,
    required this.isDirty,
    required this.isTouched,
  });

  final T                value;
  final ValidationError? error;
  final bool             isDirty;
  final bool             isTouched;

  bool get isValid      => error == null;
  bool get isInvalid    => error != null;
  /// Alias used by generated screen code.
  bool get hasError     => error != null;
  String? get errorMessage => error?.message;

  ReactiveValue<T> withValue(T newValue) => ReactiveValue._(
    value: newValue, error: error, isDirty: true, isTouched: isTouched);

  ReactiveValue<T> withError(ValidationError? newError) => ReactiveValue._(
    value: value, error: newError, isDirty: isDirty, isTouched: true);

  ReactiveValue<T> touch() => ReactiveValue._(
    value: value, error: error, isDirty: isDirty, isTouched: true);

  ReactiveValue<T> reset(T initial) => ReactiveValue.pure(initial);

  @override
  List<Object?> get props => [value, error, isDirty, isTouched];
}
""";

  // ─────────────────────────────────────────────────────────────────────────
  // base_reactive_bloc.dart
  // ─────────────────────────────────────────────────────────────────────────
  static const String baseReactiveBloc = r"""
// lib/bloc/core/runtime/base_reactive_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'reactive_value.dart';
import 'validation_error.dart';

// ── Public types the generated BLoC references ───────────────────────────────

typedef Validator<T> = ValidationError? Function(T? value);

typedef StateUpdater<S> = S Function(
  S state,
  dynamic value,
  ValidationError? error,
);

class FunctionValidator<T> {
  const FunctionValidator(this._validate, {required this.code});

  final String? Function(T? value) _validate;
  final String code;

  ValidationError? call(T? value) {
    final msg = _validate(value);
    if (msg == null) return null;
    return ValidationError(field: code, message: msg);
  }
}

// ── Base class ────────────────────────────────────────────────────────────────

abstract class BaseReactiveBloc<E, S extends Equatable> extends Bloc<E, S> {
  BaseReactiveBloc(super.initialState);

  // ── Subclass contract ──────────────────────────────────────────────────────

  Map<String, FunctionValidator<dynamic>> get componentValidators;
  Map<String, StateUpdater<S>>            get componentUpdaters;
  Iterable<ReactiveValue<dynamic>>        get allFields;

  // ── Computed ───────────────────────────────────────────────────────────────

  bool get isAllValid => allFields.every((f) => f.isValid);

  // ── Event registration ─────────────────────────────────────────────────────

  void registerSequentialEvent<Ev extends E>(
    Future<void> Function(Ev, Emitter<S>) handler,
  ) => on<Ev>(handler, transformer: _sequential());

  void registerInputEvent<Ev extends E>(
    void Function(Ev, Emitter<S>) handler,
  ) => on<Ev>((e, emit) => handler(e, emit));

  void registerSubmitEvent<Ev extends E>(
    Future<void> Function(Ev, Emitter<S>) handler,
  ) => on<Ev>(handler, transformer: _sequential());

  // ── Component helpers ──────────────────────────────────────────────────────

  ValidationError? validateComponent(String key, dynamic value) =>
      componentValidators[key]?.call(value);

  void updateComponent(Emitter<S> emit, String key, dynamic value) {
    final updater = componentUpdaters[key];
    if (updater == null) return;
    final error = validateComponent(key, value);
    safeEmit(emit, updater(state, value, error));
  }

  void batchUpdateComponents(Emitter<S> emit, Map<String, dynamic> updates) {
    var current = state;
    for (final entry in updates.entries) {
      final updater = componentUpdaters[entry.key];
      if (updater == null) continue;
      final error = validateComponent(entry.key, entry.value);
      current = updater(current, entry.value, error);
    }
    safeEmit(emit, current);
  }

  // ── Guard ──────────────────────────────────────────────────────────────────

  void safeEmit(Emitter<S> emit, S newState) {
    if (!isClosed && state != newState) emit(newState);
  }

  // ── Private ────────────────────────────────────────────────────────────────

  EventTransformer<Ev> _sequential<Ev>() =>
      (events, mapper) => events.asyncExpand(mapper);
}
""";
}

// // lib/bloc/generators/runtime_sources.dart
// // All core runtime files emitted verbatim into lib/bloc/core/runtime/

// abstract final class RuntimeSources {
//   // ─────────────────────────────────────────────────────────────────────────
//   // failure.dart  — replaces the old bare Failure inside async_state
//   // ─────────────────────────────────────────────────────────────────────────
//   static const String failure = r"""
// // lib/bloc/core/runtime/failure.dart
// import 'package:equatable/equatable.dart';

// class Failure extends Equatable {
//   const Failure({
//     required this.message,
//     this.code = 'unknown',
//     this.retryable = false,
//     this.statusCode,
//   });

//   final String  message;
//   final String  code;
//   final bool    retryable;
//   final int?    statusCode;

//   @override
//   List<Object?> get props => [message, code, retryable, statusCode];

//   @override
//   String toString() => 'Failure(code: $code, message: $message)';
// }
// """;

//   // ─────────────────────────────────────────────────────────────────────────
//   // async_state.dart
//   // ─────────────────────────────────────────────────────────────────────────
//   static const String asyncState = r"""
// // lib/bloc/core/runtime/async_state.dart
// import 'package:equatable/equatable.dart';
// import 'failure.dart';

// export 'failure.dart';

// sealed class AsyncState<T> extends Equatable {
//   const AsyncState();

//   bool get isIdle    => this is AsyncIdle<T>;
//   bool get isLoading => this is AsyncLoading<T>;
//   bool get isSuccess => this is AsyncSuccess<T>;
//   bool get isFailure => this is AsyncFailure<T>;
//   bool get isEmpty   => this is AsyncEmpty<T>;

//   /// True while a request is in-flight.
//   bool get isBusy => this is AsyncLoading<T>;

//   /// Returns data if in success state, otherwise null.
//   T? get dataOrNull => switch (this) {
//     AsyncSuccess<T>(data: final d) => d,
//     _ => null,
//   };

//   /// Returns the Failure if in failure state, otherwise null.
//   Failure? get failureOrNull => switch (this) {
//     AsyncFailure<T>(failure: final f) => f,
//     _ => null,
//   };

//   R when<R>({
//     required R Function()        idle,
//     required R Function()        loading,
//     required R Function(T data)  success,
//     required R Function(Failure) failure,
//     R Function()?                empty,
//   }) => switch (this) {
//     AsyncIdle<T>()                  => idle(),
//     AsyncLoading<T>()               => loading(),
//     AsyncSuccess<T>(:final data)    => success(data),
//     AsyncFailure<T>(:final failure) => failure(failure),
//     AsyncEmpty<T>()                 => empty != null ? empty() : idle(),
//   };

//   R maybeWhen<R>({
//     R Function()?        idle,
//     R Function()?        loading,
//     R Function(T data)?  success,
//     R Function(Failure)? failure,
//     R Function()?        empty,
//     required R Function() orElse,
//   }) => switch (this) {
//     AsyncIdle<T>()                  => idle?.call()        ?? orElse(),
//     AsyncLoading<T>()               => loading?.call()     ?? orElse(),
//     AsyncSuccess<T>(:final data)    => success?.call(data) ?? orElse(),
//     AsyncFailure<T>(:final failure) => failure?.call(failure) ?? orElse(),
//     AsyncEmpty<T>()                 => empty?.call()       ?? orElse(),
//   };
// }

// /// Initial / reset — no request has been made yet.
// final class AsyncIdle<T> extends AsyncState<T> {
//   const AsyncIdle();
//   @override List<Object?> get props => const [];
// }

// /// A request is in-flight.
// final class AsyncLoading<T> extends AsyncState<T> {
//   const AsyncLoading();
//   @override List<Object?> get props => const [];
// }

// /// Request succeeded with data.
// final class AsyncSuccess<T> extends AsyncState<T> {
//   const AsyncSuccess(this.data);
//   final T data;
//   @override List<Object?> get props => [data];
// }

// /// Request succeeded but the result set is empty.
// final class AsyncEmpty<T> extends AsyncState<T> {
//   const AsyncEmpty();
//   @override List<Object?> get props => const [];
// }

// /// Request failed.
// final class AsyncFailure<T> extends AsyncState<T> {
//   const AsyncFailure(this.failure);
//   final Failure failure;
//   @override List<Object?> get props => [failure];
// }
// """;

//   // ─────────────────────────────────────────────────────────────────────────
//   // validation_error.dart
//   // ─────────────────────────────────────────────────────────────────────────
//   static const String validationError = r"""
// // lib/bloc/core/runtime/validation_error.dart
// import 'package:equatable/equatable.dart';

// class ValidationError extends Equatable {
//   const ValidationError({required this.field, required this.message});

//   final String field;
//   final String message;

//   @override
//   List<Object?> get props => [field, message];
// }
// """;

//   // ─────────────────────────────────────────────────────────────────────────
//   // validator.dart
//   // ─────────────────────────────────────────────────────────────────────────
//   static const String validator = r"""
// // lib/bloc/core/runtime/validator.dart
// import 'validation_error.dart';

// typedef ValidationResult = List<ValidationError>;
// typedef FieldValidator<T> = ValidationError? Function(T? value);

// class Validators {
//   static FieldValidator<String> required(String field, [String? msg]) =>
//       (v) => (v == null || v.trim().isEmpty)
//           ? ValidationError(field: field, message: msg ?? '$field is required')
//           : null;

//   static FieldValidator<String> minLength(String field, int min) =>
//       (v) => (v != null && v.length < min)
//           ? ValidationError(field: field, message: '$field must be at least $min characters')
//           : null;

//   static FieldValidator<String> maxLength(String field, int max) =>
//       (v) => (v != null && v.length > max)
//           ? ValidationError(field: field, message: '$field must be at most $max characters')
//           : null;

//   static FieldValidator<String> email(String field) =>
//       (v) => (v != null &&
//               v.isNotEmpty &&
//               !RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(v))
//           ? ValidationError(field: field, message: 'Enter a valid email')
//           : null;

//   static FieldValidator<String> phone(String field) =>
//       (v) => (v != null &&
//               v.isNotEmpty &&
//               !RegExp(r'^\+?[0-9\s\-\(\)]{7,15}$').hasMatch(v))
//           ? ValidationError(field: field, message: 'Enter a valid phone number')
//           : null;

//   static FieldValidator<String> regex(
//           String field, String pattern, String msg) =>
//       (v) => (v != null &&
//               v.isNotEmpty &&
//               !RegExp(pattern).hasMatch(v))
//           ? ValidationError(field: field, message: msg)
//           : null;

//   static FieldValidator<num?> min(String field, num minVal) =>
//       (v) => (v != null && v < minVal)
//           ? ValidationError(field: field, message: '$field must be ≥ $minVal')
//           : null;

//   static FieldValidator<num?> max(String field, num maxVal) =>
//       (v) => (v != null && v > maxVal)
//           ? ValidationError(field: field, message: '$field must be ≤ $maxVal')
//           : null;

//   static ValidationResult combine(List<FieldValidator> validators, dynamic value) {
//     final errors = <ValidationError>[];
//     for (final v in validators) {
//       final e = v(value);
//       if (e != null) errors.add(e);
//     }
//     return errors;
//   }
// }
// """;

//   // ─────────────────────────────────────────────────────────────────────────
//   // reactive_value.dart
//   // ─────────────────────────────────────────────────────────────────────────
//   static const String reactiveValue = r"""
// // lib/bloc/core/runtime/reactive_value.dart
// import 'package:equatable/equatable.dart';
// import 'validation_error.dart';

// class ReactiveValue<T> extends Equatable {
//   /// Initial, untouched state. const-constructable for use as default params.
//   const ReactiveValue.pure(this.value)
//       : error     = null,
//         isDirty   = false,
//         isTouched = false;

//   /// Value changed by the user.
//   const ReactiveValue.dirty(this.value, {this.error})
//       : isDirty   = true,
//         isTouched = true;

//   const ReactiveValue._({
//     required this.value,
//     this.error,
//     required this.isDirty,
//     required this.isTouched,
//   });

//   final T                value;
//   final ValidationError? error;
//   final bool             isDirty;
//   final bool             isTouched;

//   bool get isValid      => error == null;
//   bool get isInvalid    => error != null;
//   String? get errorMessage => error?.message;

//   ReactiveValue<T> withValue(T newValue) => ReactiveValue._(
//     value: newValue, error: error, isDirty: true, isTouched: isTouched);

//   ReactiveValue<T> withError(ValidationError? newError) => ReactiveValue._(
//     value: value, error: newError, isDirty: isDirty, isTouched: true);

//   ReactiveValue<T> touch() => ReactiveValue._(
//     value: value, error: error, isDirty: isDirty, isTouched: true);

//   ReactiveValue<T> reset(T initial) => ReactiveValue.pure(initial);

//   @override
//   List<Object?> get props => [value, error, isDirty, isTouched];
// }
// """;

//   // ─────────────────────────────────────────────────────────────────────────
//   // base_reactive_bloc.dart
//   // ─────────────────────────────────────────────────────────────────────────
//   static const String baseReactiveBloc = r"""
// // lib/bloc/core/runtime/base_reactive_bloc.dart
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:equatable/equatable.dart';
// import 'reactive_value.dart';
// import 'validation_error.dart';

// // ── Public types the generated BLoC references ───────────────────────────────

// typedef Validator<T> = ValidationError? Function(T? value);

// typedef StateUpdater<S> = S Function(
//   S state,
//   dynamic value,
//   ValidationError? error,
// );

// class FunctionValidator<T> {
//   const FunctionValidator(this._validate, {required this.code});

//   final String? Function(T? value) _validate;
//   final String code;

//   ValidationError? call(T? value) {
//     final msg = _validate(value);
//     if (msg == null) return null;
//     return ValidationError(field: code, message: msg);
//   }
// }

// // ── Base class ────────────────────────────────────────────────────────────────

// abstract class BaseReactiveBloc<E, S extends Equatable> extends Bloc<E, S> {
//   BaseReactiveBloc(super.initialState);

//   // ── Subclass contract ──────────────────────────────────────────────────────

//   Map<String, FunctionValidator<dynamic>> get componentValidators;
//   Map<String, StateUpdater<S>>            get componentUpdaters;
//   Iterable<ReactiveValue<dynamic>>        get allFields;

//   // ── Computed ───────────────────────────────────────────────────────────────

//   bool get isAllValid => allFields.every((f) => f.isValid);

//   // ── Event registration ─────────────────────────────────────────────────────

//   void registerSequentialEvent<Ev extends E>(
//     Future<void> Function(Ev, Emitter<S>) handler,
//   ) => on<Ev>(handler, transformer: _sequential());

//   void registerInputEvent<Ev extends E>(
//     void Function(Ev, Emitter<S>) handler,
//   ) => on<Ev>((e, emit) => handler(e, emit));

//   void registerSubmitEvent<Ev extends E>(
//     Future<void> Function(Ev, Emitter<S>) handler,
//   ) => on<Ev>(handler, transformer: _sequential());

//   // ── Component helpers ──────────────────────────────────────────────────────

//   ValidationError? validateComponent(String key, dynamic value) =>
//       componentValidators[key]?.call(value);

//   void updateComponent(Emitter<S> emit, String key, dynamic value) {
//     final updater = componentUpdaters[key];
//     if (updater == null) return;
//     final error = validateComponent(key, value);
//     safeEmit(emit, updater(state, value, error));
//   }

//   void batchUpdateComponents(Emitter<S> emit, Map<String, dynamic> updates) {
//     var current = state;
//     for (final entry in updates.entries) {
//       final updater = componentUpdaters[entry.key];
//       if (updater == null) continue;
//       final error = validateComponent(entry.key, entry.value);
//       current = updater(current, entry.value, error);
//     }
//     safeEmit(emit, current);
//   }

//   // ── Guard ──────────────────────────────────────────────────────────────────

//   void safeEmit(Emitter<S> emit, S newState) {
//     if (!isClosed && state != newState) emit(newState);
//   }

//   // ── Private ────────────────────────────────────────────────────────────────

//   EventTransformer<Ev> _sequential<Ev>() =>
//       (events, mapper) => events.asyncExpand(mapper);
// }
// """;
// }
