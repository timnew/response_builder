import 'dart:async';

import 'package:rxdart/rxdart.dart';

import 'update_actions.dart';
export 'update_actions.dart';

abstract class Request<T> {
  final BehaviorSubject<T> _subject;

  Stream<T> get resultStream => _subject;

  Request({T initialValue, bool executeOnFirstListen = true})
      : _subject = initialValue != null ? BehaviorSubject.seeded(initialValue) : BehaviorSubject() {
    if (executeOnFirstListen) {
      _subject.onListen = reload;
    }
  }

  T get result => null;

  FutureOr<T> load();

  Future reload({quiet: false}) async => await execute(load(), quiet: quiet);

  Future execute(FutureOr<T> value, {quiet: false}) async {
    if (!quiet && value is Future) markAsWaiting();

    try {
      final result = value is Future ? await value : value;
      putValue(result);
    } on Exception catch (error, stackTrace) {
      putError(error, stackTrace);
    } catch (error) {
      rethrow;
    }
  }

  void putValue(T value) {
    _subject.add(value);
  }

  void putError(Object error, [StackTrace stackTrace]) {
    _subject.addError(error, stackTrace);
  }

  void markAsWaiting() {
    _subject.add(null);
  }

  bool get isWaiting => _subject.hasValue && currentData == null;

  bool get hasData => _subject.hasValue && currentData != null;

  T get currentData => _subject.value;

  T get ensuredCurrentData {
    if (!hasData) throw StateError("Access data when it is not yet available");
    return currentData;
  }

  bool get hasError => _subject.hasError;

  Object get currentError => _subject.error;

  StackTrace get currentErrorStackTrace => null; // NOT EXPOSED YET

  bool get hasCurrent => hasData || hasError;

  Future<T> get firstValue => resultStream.firstWhere((result) => result != null);

  void updateValue(ValueUpdater<T> updater) {
    try {
      putValue(updater(ensuredCurrentData));
    } on Exception catch (error, stacktrace) {
      putError(error, stacktrace);
    } catch (error) {
      rethrow;
    }
  }

  Future updateValueAsync(AsyncValueUpdater<T> updater, {quiet: false}) {
    return execute(updater(ensuredCurrentData), quiet: quiet);
  }
}
