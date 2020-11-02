import 'dart:async';

import 'package:response_builder/builder_only.dart';
import 'package:rxdart/rxdart.dart';

import 'update_actions.dart';
export 'update_actions.dart';

/// [Request] is a listenable data source that loads data in either synchronous or asynchronous manner.
///
/// Similar to [Future] and [Stream], [Request] can hold 3-state result, which could `data`, `error` or `waiting`.
/// Unlike [Future] and [Stream], [Request] also provide method to read or write result in both synchronous or asynchronous way.
///
/// [Request] is designed to be used with [BuildAsyncResult] protocol.
/// It can be consumed with [BuildAsyncResult.buildRequest] as [Future] and [Protocol].
///
/// [Request] is abstract class, a derived class should be created for particular use case.
/// Derived class should at least implement [load] method to explicitly specify how request should load data.
///
/// [load] can be either synchronous or asynchronous, it can return the result directly if data can be loaded synchronously
///
///  * Returns value directly if result can be loaded synchronously
///  * Returns a Future that holds result if data loaded asynchronously
///
/// [load] method should do its job without any parameters, consider to add parameters required by load method as Request's field.
/// Depends on whether those parameter fields are mutable or final,[Request] can be either mutable or immutable.
///
/// [Request] only start to load data when [Request.resultStream] is listened, typically it is when Request is listenable by a widget
/// with [BuildAsyncResult] protocol. This behavior can be customized for different scenarios:
///
/// * Expect to control when to load data, such as when user clicks load button or so
///   * Set [initialValue] with a legal empty value. For more details about "legal empty value", check below.
///   * Set [loadOnListened] to `false`, so data loading won't triggered automatically
///   * Leave [initialLoadQuietly] to `false`, so a proper loading indicator would show when loading is triggered
/// * Render UI with local cached value first, and refresh it on it fly
///   * Set [initialValue] with cached result.
///   * Leave [loadOnListened] to `true`, so a fresh load would be triggered when UI data is used.
///   * Set [initialLoadQuietly] to `true`, so loading view won't happen when refresh is happening in background
///   * To only refresh data when cache is expired, [loadOnListened] can only set to `true` when cache is expired.
///
/// [initialValue] provides the initial data to build UI before the data is loaded asynchronously
///   * By default Leave it unset or give `null`, UI would render a loading view before result available
///   * Give [initialValue] if a data view is expected before result is available
///     * It could a data loaded from sync cache
///     * An legal "empty value" should be given instead of using `null`:
///       * Empty [List] or other equivalent should be given if data is collection type.
///       * [Null Object Pattern](https://en.wikipedia.org/wiki/Null_object_pattern) is highly recommended,
///
/// [Request] is designed to handle asynchronous scenario, so its API is more complex and could be more expensive to instantiate.
/// To deal with synchronous data only, consider use [ResultStore] instead of [Request]
abstract class Request<T> {
  final BehaviorSubject<T> _subject;

  /// The stream that provides the latest result of current request
  ///
  /// [Widget] can consume the data from the stream with [BuildAsyncResult.buildStream]
  /// Or use [BuildAsyncResult.buildRequest] to consume the whole request.
  Stream<T> get resultStream => _subject;

  /// Constructor of [Request].
  ///
  /// [initialValue] provide initial value to the request
  /// [loadOnListened] decides whether request should load data when [resultStream] is being listened, default to `true`
  /// [initialLoadQuietly] decides whether whether initial loads should be quite or not.
  ///
  /// * Expect to control when to load data, such as when user clicks load button or so
  ///   * Set [initialValue] with a legal empty value. For more details about "legal empty value", check below.
  ///   * Set [loadOnListened] to `false`, so data loading won't triggered automatically
  ///   * Leave [initialLoadQuietly] to `false`, so a proper loading indicator would show when loading is triggered
  /// * Render UI with local cached value first, and refresh it on it fly
  ///   * Set [initialValue] with cached result.
  ///   * Leave [loadOnListened] to `true`, so a fresh load would be triggered when UI data is used.
  ///   * Set [initialLoadQuietly] to `true`, so loading view won't happen when refresh is happening in background
  ///   * To only refresh data when cache is expired, [loadOnListened] can only set to `true` when cache is expired.
  ///
  /// [initialValue] provides the initial data to build UI before the data is loaded asynchronously
  ///   * By default Leave it unset or give `null`, UI would render a loading view before result available
  ///   * Give [initialValue] if a data view is expected before result is available
  ///     * It could a data loaded from sync cache
  ///     * An legal "empty value" should be given instead of using `null`:
  ///       * Empty [List] or other equivalent should be given if data is collection type.
  ///       * [Null Object Pattern](https://en.wikipedia.org/wiki/Null_object_pattern) is highly recommended,
  Request({
    T initialValue,
    bool loadOnListened = true,
    bool initialLoadQuietly = false,
  })  : _subject = initialValue != null
            ? BehaviorSubject.seeded(initialValue)
            : BehaviorSubject(),
        assert(loadOnListened is bool),
        assert(initialLoadQuietly is bool) {
    if (loadOnListened) {
      // Load data quietly if initial value is given
      _subject.onListen = () => reload(quiet: initialLoadQuietly);
    }
  }

  /// Contract that specifies how request loads data
  ///
  /// Derived class should always implement this contract
  FutureOr<T> load();

  /// Enforce a request to reload data with current parameters
  ///
  /// [quiet] can be used to control whether a loading view should be shown when data is being loaded, default to `false`
  /// Typically, [quiet] is only set to `true`, when it is a background data refresh.
  Future reload({quiet: false}) async => _execute(load, quiet);

  /// Update request with [value] either synchronously or asynchronously
  ///
  /// * When [value] is [T], result is updated synchronously, [quiet] is ignored
  /// * When [value] is `Future<T>`, result is updated asynchronously, [quiet] indicates whether a loading view should be shown when data is being loaded, default to `false
  ///   * Typically, [quiet] is only set to `true`, when it is a background data refresh.
  ///   * Error yield by future would be caught by result stream
  Future update(FutureOr<T> value, {quiet: false}) async {
    if (value is Future) {
      await _execute(value, quiet);
    } else {
      putValue(value);
    }
  }

  /// Execute the [action], updates request with the return value from action.
  ///
  /// [action] can either return [T] or `Future<T>`
  /// [Exception] thrown by `action` would be caught as error result
  Future execute(FutureOr<T> Function() action, {bool quiet: false}) =>
      _execute(action, quiet);

  Future _execute(dynamic futureOrAction, bool quiet) async {
    assert(futureOrAction is FutureOr<T> ||
        futureOrAction is FutureOr<T> Function());

    if (!quiet) markAsWaiting();

    try {
      final future =
          futureOrAction is Future ? futureOrAction : futureOrAction();
      final result = await future;
      putValue(result);
    } on Exception catch (error, stackTrace) {
      putError(error, stackTrace);
    } catch (error, stackTrace) {
      putError(error, stackTrace);
      rethrow;
    }
  }

  /// Update request with [value] synchronously
  void putValue(T value) {
    _subject.add(value);
  }

  /// Update request with [error] synchronously
  void putError(Object error, [StackTrace stackTrace]) {
    _subject.addError(error, stackTrace);
  }

  /// Update request as waiting synchronously
  void markAsWaiting() {
    _subject.add(null);
  }

  /// Check whether request is in waiting state
  ///
  /// [isWaiting] is exclusive to [hasCurrent], [hasData] and [hasError]
  bool get isWaiting => _subject.hasValue && currentData == null;

  /// Check whether request has a data or an error.
  ///
  /// [hasCurrent] is exclusive to [isWaiting]
  /// Use [hasData] or [hasError] to determine current value is data or error
  bool get hasCurrent => hasData || hasError;

  /// Check whether request has a data
  ///
  /// Check whether current is error with [hasError]
  /// Check whether request is waiting with [isWaiting]
  bool get hasData => _subject.hasValue && currentData != null;

  /// Check whether request has a error
  ///
  /// Check whether current is data with [hasData]
  /// Check whether request is waiting with [isWaiting]
  bool get hasError => _subject.hasError;

  /// Get latest data.
  ///
  /// Returns `null` if request holds an error or
  /// Consider to use [ensuredCurrentData] is data is always expected.
  T get currentData => _subject.value;

  /// Similar to [currentData], but throws [StateError] when data is not available
  T get ensuredCurrentData {
    if (!hasData) throw StateError("Access data when it is not yet available");
    return currentData;
  }

  /// Get latest error
  ///
  /// Returns `null` if request doesn't hold an error
  Object get currentError => _subject.error;

  /// Get latest stack trace of latest error
  ///
  /// Always returns `null` for now due to upstream limitation
  StackTrace get currentErrorStackTrace => null; // NOT EXPOSED YET

  /// Returns a future which resolves when first data or error fetched
  ///
  /// Future resolves immediately when request holds a data or an error loaded before.
  Future<T> get firstResult =>
      resultStream.firstWhere((result) => result != null);

  /// Update request with [updater] synchronously
  ///
  /// [updater] accept the existing data and returns a new data, which is used to update the request
  ///
  /// Example: Suppose request is Request<Int>, the following code increase the value for one
  /// ```dart
  /// request.updateValue((currentIntValue) => currentIntValue + 1);
  /// ```
  ///
  /// Exception throws by [updater] would be caught by result as error result
  ///
  /// [StateError] is thrown when data is not available, check request state with [hasData] if not sure.
  ///
  /// To update value asynchronously, use [updateValueAsync]
  void updateValue(ValueUpdater<T> updater) {
    try {
      putValue(updater(ensuredCurrentData));
    } on Exception catch (error, stacktrace) {
      putError(error, stacktrace);
    } catch (error) {
      rethrow;
    }
  }

  /// Update request with [updater] asynchronously
  ///
  /// [updater] accept the existing data and returns a [Future] of new data, which is used to update the request
  ///
  /// Exception throws by [updater] would be caught by result as error result
  ///
  /// [StateError] is thrown when data is not available, check request state with [hasData] if not sure.
  ///
  /// To update value synchronously, use [updateValue]
  Future updateValueAsync(AsyncValueUpdater<T> updater, {quiet: false}) {
    return update(updater(ensuredCurrentData), quiet: quiet);
  }
}
