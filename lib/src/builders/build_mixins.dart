import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:response_builder/src/request.dart';
import 'package:response_builder/src/result_store.dart';

import 'default_build_actions.dart';

/// Protocol that builds data
///
/// [BuildData] is designed to be a conceptual protocol, which would be rarely used directly.
///
/// * To build a data from [ValueListenable], use [BuildValueListenable]
/// * To build 2-state sync result from [ValueListenable], consider use [BuildResultListenable]
/// * To build 3-state async result, consider use [BuildAsyncResult]
mixin BuildData<T> {
  /// Contract to to build view when [data[ is loaded
  ///
  /// Implementer should always implement this contract
  Widget buildData(BuildContext context, T data);
}

/// Protocol that builds 2-state sync result, which could be either a data or an error
/// BuildResult implements [BuildData]
///
/// [BuildResult] is designed to be a conceptual protocol, which would be rarely used directly.
///
/// * For synchronous scenario, consider to use [BuildResultListenable].
/// * For asynchronous scenario, consider to use [BuildAsyncResult].
mixin BuildResult<T> implements BuildData<T> {
  /// Contract to to build view when [error] occurred
  Widget buildError(BuildContext context, Object error);
}

/// Protocol that builds 3-state async result, which can be:
///
/// * initial: not yet initialized or data source is null
/// * waiting: data is being loaded
/// * error: an error occurred
/// * data: data if properly loaded
///
/// [BuildAsyncResultProtocol] is considered as a conceptual protocol, which should be rarely used directly.
/// [BuildAsyncResult] is a ready-to-use implementation of [BuildAsyncResultProtocol]
mixin BuildAsyncResultProtocol<T> implements BuildResult<T> {
  /// Contract to build view when data source hasn't connected yet
  Widget buildInitialState(BuildContext context);

  /// Contract to build view when data is being loaded
  Widget buildWaiting(BuildContext context);

  /// Contract to build view when [error] occurred
  Widget buildError(BuildContext context, Object error);
}

/// Protocol that builds 3-state async result from a [Future], a [Stream] or a [Request]
///
/// * Use [buildFuture] to consume async data from [Future]
/// * Use [buildStream] to consume async data from [Stream]
/// * Use [buildRequest] to consume async data from [Request]
///
/// By default, [buildError] invokes [DefaultBuildActions.buildError]
/// [buildWaiting] invokes [DefaultBuildActions.buildWaiting]
mixin BuildAsyncResult<T> implements BuildAsyncResultProtocol<T> {
  /// Contract to to build view when data source hasn't connected yet
  ///
  /// By default it builds waiting view
  Widget buildInitialState(BuildContext context) => buildWaiting(context);

  /// Contract to to build view when data is being loaded
  ///
  /// By default it uses [DefaultBuildActions]
  Widget buildWaiting(BuildContext context) => DefaultBuildActions.buildWaiting(context);

  /// Contract to to build view when [error] occurred
  ///
  /// By default it build view with [DefaultBuildActions]
  Widget buildError(BuildContext context, Object error) => DefaultBuildActions.buildError(context, error);

  /// Implementation of [AsyncSnapShotBuilder] of [FutureBuilder] or [StreamBuilder], which builds view from [AsyncSnapshot].
  ///
  /// * Initial value / cached value/error is respected with high-priority
  /// * Build initial view when hadn't connect to a data source, it is likely to happen when data source is null
  /// * Build waiting view while connecting to data source
  /// * Build data/error when data/error is received
  /// * null is treated as loading in progress
  ///
  /// Implementer should rarely need to override this method, or it is likely to be a misuse.
  Widget buildAsyncSnapshot(BuildContext context, AsyncSnapshot<T> snapshot) {
    if (snapshot.hasError) return buildError(context, snapshot.error);
    if (snapshot.hasData) return buildData(context, snapshot.data);

    switch (snapshot.connectionState) {
      case ConnectionState.none:
        return buildInitialState(context);
      case ConnectionState.waiting:
        return buildWaiting(context);
      case ConnectionState.active:
        if (snapshot.hasError) return buildError(context, snapshot.error);
        if (snapshot.hasData) return buildData(context, snapshot.data);
        return buildWaiting(context);
      default:
        if (snapshot.hasError) return buildError(context, snapshot.error);
        if (snapshot.hasData) return buildData(context, snapshot.data);
        throw StateError("Bad AsyncSnapshot $snapshot}");
    }
  }

  /// Build view for a [Future] with [FutureBuilder]
  ///
  /// [key] specifies [FutureBuilder]'s key
  /// [initialData] specifies [FutureBuilder]'s initial value
  Widget buildFuture(Future<T> future, {Key key, T initialData}) =>
      FutureBuilder(key: key, future: future, builder: buildAsyncSnapshot, initialData: initialData);

  /// Build view for a [Stream] with [StreamBuilder]
  ///
  /// [key] specifies [StreamBuilder]'s key
  /// [initialData] specifies [StreamBuilder]'s initial value
  Widget buildStream(Stream<T> stream, {Key key, T initialData}) =>
      StreamBuilder(key: key, stream: stream, builder: buildAsyncSnapshot, initialData: initialData);

  /// Build view for a [Request] with [StreamBuilder]
  ///
  /// [key] specifies [StreamBuilder]'s key
  /// [initialData] specifies [StreamBuilder]'s initial value
  Widget buildRequest(Request<T> request, {Key key, T initialData}) =>
      buildStream(request?.resultStream, key: key, initialData: initialData);
}

/// Protocol that builds always-exist data from [ValueListenable]
mixin BuildValueListenable<T> implements BuildData<T> {
  /// Build view for [ValueListenable] with [ValueListenableBuilder]
  ///
  /// [key] specifies [StreamBuilder]'s key
  Widget buildValueListenable(ValueListenable<T> listenable, {Key key}) => ValueListenableBuilder(
        key: key,
        valueListenable: listenable,
        builder: (BuildContext context, T value, _) => buildData(context, value),
      );
}

/// Protocol that builds 2-state data from [ValueListenable],
/// error is supported beside of successful value.
///
/// [Result] from [package:async](https://pub.dev/packages/async) is used to represents 2-state data
mixin BuildResultListenable<T> implements BuildResult<T> {
  /// Contract to to build view when [error] occurred
  ///
  /// By default it build view with [DefaultBuildActions]
  Widget buildError(BuildContext context, Object error) => DefaultBuildActions.buildError(context, error);

  /// Build view for [ValueListenable] with [ValueListenableBuilder]
  /// [ValueListenable] holds 2-state [Result] instead of plain data
  ///
  /// [key] specifies [StreamBuilder]'s key
  Widget buildResultListenable(ValueListenable<Result<T>> listenable, {Key key}) => ValueListenableBuilder(
        key: key,
        valueListenable: listenable,
        builder: (BuildContext context, Result<T> value, _) {
          if (value.isValue) {
            return buildData(context, value.asValue.value);
          } else {
            return buildError(context, value.asError.error);
          }
        },
      );

  /// Build view for [ResultStore] with [ValueListenableBuilder]
  ///
  /// [key] specifies [StreamBuilder]'s key
  Widget buildStore(ResultStore<T> store, {Key key}) => buildResultListenable(store.listenable, key: key);
}
