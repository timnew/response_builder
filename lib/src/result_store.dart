import 'package:async/async.dart';
import 'package:flutter/foundation.dart';

import 'mapper_types.dart';
export 'mapper_types.dart';

class ResultStore<T> {
  final ValueNotifier<Result<T>> _notifier;

  ValueListenable<Result<T>> get listenable => _notifier;

  ResultStore(T value) : _notifier = ValueNotifier(Result.value(value));

  ResultStore.error(Object error, [StackTrace stackTrace]) : _notifier = ValueNotifier(Result.error(error, stackTrace));

  Result<T> get result => _notifier.value;

  bool get hasValue => result.isValue;

  bool get hasError => result.isError;

  T get value {
    if (!hasValue) throw StateError("Expect a value but got an error");
    return result.asValue.value;
  }

  Object get error {
    if (!hasError) throw StateError("Expect an error but got an value");
    return result.asError.error;
  }

  StackTrace get stackTrace {
    if (!hasError) throw StateError("Expect an error but got an value");
    return result.asError.stackTrace;
  }

  T putValue(T value) {
    _notifier.value = Result.value(value);
    return value;
  }

  void putError(Object error, [StackTrace stackTrace]) {
    _notifier.value = Result.error(error, stackTrace);
  }

  T updateValue(ValueUpdater<T> updater) {
    if (hasError) return null;

    return putValue(updater(value));
  }

  T fixError(ErrorFixer<T> fixer) {
    if (hasValue) return value;

    return putValue(fixer(error));
  }
}
