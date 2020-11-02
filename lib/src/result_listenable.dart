import 'package:async/async.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:response_builder/src/update_actions.dart';

/// An interface for subclasses of [Listenable] that expose a [result].
///
/// This interface is implemented by [ResultNotifier]
///
/// See also:
///
///  * [BuildResultListenable], a minx that enables widget to work with [ResultListenable
abstract class ResultListenable<T> implements Listenable {
  Result<T> get result;

  /// Check whether result is a value
  bool get hasValue => result.isValue;

  /// Check whether result is an error
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
}

/// [ResultNotifier] is just like [ValueNotifier] but support to hold error along with value.
///
/// [ResultNotifier] holds 2-state [Result], which could be either a data or an error.
///
/// When [ResultNotifier.result] changes, it notifies its listeners
class ResultNotifier<T> extends ChangeNotifier with ResultListenable<T> {
  Result<T> _result;

  /// Create [ResultNotifier] with [value]
  ResultNotifier(T value) : this._(Result.value(value));

  /// Create [ResultNotifier] with [error]
  /// [stackTrace] is optional, will be `null` if not specified.
  ResultNotifier.error(Object error, [StackTrace stackTrace]) : this._(Result.error(error, stackTrace));

  ResultNotifier._(this._result);

  /// Get 2-state result
  Result<T> get result => _result;

  /// Set 2-state result
  set result(Result<T> newResult) {
    _result = newResult;
    notifyListeners();
  }

  /// Put [value] into store
  ///
  /// This method will notify store's listeners
  T putValue(T value) {
    result = Result.value(value);
    return value;
  }

  /// Put [error] into store
  /// [stackTrace] is optional
  ///
  /// This method will notify store's listeners
  void putError(Object error, [StackTrace stackTrace]) {
    result = Result.error(error, stackTrace);
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

  ValueListenable<Result<T>> asValueListenable() => _ValueListenableWrapper(this);
}

class _ValueListenableWrapper<T> implements ValueListenable<Result<T>> {
  final ResultNotifier<T> _listenable;

  _ValueListenableWrapper(this._listenable);

  @override
  void addListener(void Function() listener) => _listenable.addListener(listener);

  @override
  void removeListener(void Function() listener) => _listenable.removeListener(listener);

  @override
  Result<T> get value => _listenable.result;
}
