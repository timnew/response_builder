import 'package:async/async.dart';
import 'package:flutter/foundation.dart';

import 'update_actions.dart';
export 'update_actions.dart';

/// [ResultStore] is a listenable data source that holds 2-state synchronous result, which could be either `data` or `error`.
/// [ResultStore] is very similar to [ValueListenable] except it understands 2-state [Result].
///
/// [ResultStore] is designed to be used with [BuildResultListenable] protocol.
/// It can be consumed with [BuildResultListenable.buildStore].
///
/// [ResultStore] can be instantiate directly, if no customized behavior is needed.
/// Or a derived class can be created to add more dedicated behavior.
///
/// 2-state result is represented with [Result] from [package:async](https://pub.dev/packages/async)
///
/// Same as [ValueListenable], initial value is required when [ResultStore] is initialized.
/// To use error as initial value, use [ResultStore.error] factory method.
class ResultStore<T> {
  final ValueNotifier<Result<T>> _notifier;

  /// Get underline [ValueListenable]
  ValueListenable<Result<T>> get listenable => _notifier;

  /// Create [ResultStore] with [value]
  ResultStore(T value) : _notifier = ValueNotifier(Result.value(value));

  /// Create [ResultStore] with [error]
  /// [stackTrace] is optional, will be `null` if not specified.
  ResultStore.error(Object error, [StackTrace stackTrace])
      : _notifier = ValueNotifier(Result.error(error, stackTrace));

  /// Get the 2-state result
  Result<T> get result => _notifier.value;

  /// Check if store contains a value
  bool get hasValue => result.isValue;

  /// Check if store contains an error
  bool get hasError => result.isError;

  /// Get the value of the [result]
  ///
  /// Throws [StateError] if value has an error
  T get value {
    if (!hasValue) throw StateError("Expect a value but got an error");
    return result.asValue.value;
  }

  /// Get the error of the [result]
  ///
  /// Throws [StateError] if value has a value
  Object get error {
    if (!hasError) throw StateError("Expect an error but got an value");
    return result.asError.error;
  }

  /// Get the stackTrace of the [result]
  ///
  /// Throws [StateError] if value has a value
  StackTrace get stackTrace {
    if (!hasError) throw StateError("Expect an error but got an value");
    return result.asError.stackTrace;
  }

  /// Put [value] into store
  ///
  /// This method will notify store's listeners
  T putValue(T value) {
    _notifier.value = Result.value(value);
    return value;
  }

  /// Put [error] into store
  /// [stackTrace] is optional
  ///
  /// This method will notify store's listeners
  void putError(Object error, [StackTrace stackTrace]) {
    _notifier.value = Result.error(error, stackTrace);
  }

  /// Update store value with [updater] if store holds a value
  ///
  /// [updater] accept current value and return a new value
  ///
  /// Return true when value is updated
  /// Returns false if store holds an error
  /// Returns false if [updater] throws exception
  ///
  /// [Exception] thrown by [updater] will be captured as error result by store
  /// [Error] will be rethrown
  bool updateValue(ValueUpdater<T> updater) {
    if (hasError) return false;

    try {
      putValue(updater(value));
      return true;
    } on Exception catch (err, stackTrace) {
      putError(err, stackTrace);
      return false;
    } on Error {
      rethrow;
    } catch (err, stackTrace) {
      putError(err, stackTrace);
      return false;
    }
  }

  /// Update store with return value from [fixer] if store holds a error
  /// Returns the return value from fixer if store holds an error before, Returns the store value otherwise.
  ///
  /// [fixer] accept current error and return a new value
  ///
  /// Error thrown by [fixer] will be thrown directly rather than being captured by store.
  ///
  /// [fixError] can be used before calling [updateValue] to unify the error
  ///
  /// ```dart
  /// void increment() {
  ///   fixError((_) => 0 );
  ///   updateValue((i) => i + 1);
  /// }
  /// ```
  T fixError(ErrorFixer<T> fixer) {
    if (hasValue) return value;

    return putValue(fixer(error));
  }
}
