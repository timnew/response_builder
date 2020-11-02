import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:response_builder/response_builder.dart';

import 'package:response_builder/src/request.dart';

import 'default_build_actions.dart';

/// Protocol that builds value
///
/// [BuildValue] is designed to be a conceptual protocol, which would be rarely used directly.
///
/// * To build a value from [ValueListenable], use [BuildValueListenable]
/// * To build 2-state sync result from [ResultListenable], consider use [BuildResultListenable]
/// * To build 3-state async result from [Request], [Future] or [Stream], consider use [BuildAsyncResult]
mixin BuildValue<T> {
  /// Contract to to build view when [value[ is loaded
  ///
  /// Implementer should always implement this contract
  Widget buildValue(BuildContext context, T value);
}

/// Protocol that builds 2-state sync result, which could be either a value or an error
/// BuildResult implements [BuildValue]
///
/// [BuildResult] is designed to be a conceptual protocol, which would be rarely used directly.
///
/// * To build a value from [ValueListenable], use [BuildValueListenable]
/// * To build 2-state sync result from [ResultListenable], consider use [BuildResultListenable]
/// * To build 3-state async result from [Request], [Future] or [Stream], consider use [BuildAsyncResult]
mixin BuildResult<T> implements BuildValue<T> {
  /// Contract to to build view when [error] occurred
  Widget buildError(BuildContext context, Object error);
}

/// Protocol that builds 3-state async result, which can be:
///
/// * initial: not yet initialized or data source is null
/// * waiting: data is being loaded
/// * error: an error occurred
/// * value: data if properly loaded
///
/// [BuildAsyncResultProtocol] is considered as a conceptual protocol, which should be rarely used directly.
/// [BuildAsyncResult] is a ready-to-use implementation of [BuildAsyncResultProtocol]
mixin BuildAsyncResultProtocol<T> implements BuildResult<T> {
  /// Contract to build view when data source hasn't connected yet
  Widget buildNoDataSource(BuildContext context);

  /// Contract to build view when data is being loaded
  Widget buildLoading(BuildContext context);

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
/// [buildLoading] invokes [DefaultBuildActions.buildLoading]
mixin BuildAsyncResult<T> implements BuildAsyncResultProtocol<T> {
  /// Contract to to build view when data source hasn't connected yet
  ///
  /// By default it builds waiting view
  Widget buildNoDataSource(BuildContext context) => buildLoading(context);

  /// Contract to to build view when data is being loaded
  ///
  /// By default it uses [DefaultBuildActions]
  Widget buildLoading(BuildContext context) => DefaultBuildActions.buildLoading(context);

  /// Contract to to build view when [error] occurred
  ///
  /// By default it build view with [DefaultBuildActions]
  Widget buildError(BuildContext context, Object error) => DefaultBuildActions.buildError(context, error);

  /// Implementation of `AsyncSnapShotBuilder` for [FutureBuilder] or [StreamBuilder], which builds view from [AsyncSnapshot].
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
    if (snapshot.hasData) return buildValue(context, snapshot.data);

    switch (snapshot.connectionState) {
      case ConnectionState.none:
        return buildNoDataSource(context);
      case ConnectionState.waiting:
        return buildLoading(context);
      case ConnectionState.active:
        if (snapshot.hasError) return buildError(context, snapshot.error);
        if (snapshot.hasData) return buildValue(context, snapshot.data);
        return buildLoading(context);
      default:
        if (snapshot.hasError) return buildError(context, snapshot.error);
        if (snapshot.hasData) return buildValue(context, snapshot.data);
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
mixin BuildValueListenable<T> implements BuildValue<T> {
  /// Build view for [ValueListenable] with [ValueListenableBuilder]
  ///
  /// [key] specifies [StreamBuilder]'s key
  Widget buildValueListenable(ValueListenable<T> listenable, {Key key}) => ValueListenableBuilder(
        key: key,
        valueListenable: listenable,
        builder: (BuildContext context, T value, _) => buildValue(context, value),
      );
}

/// Protocol that builds 2-state data from [ResultNotifier], which is similar to [ValueListenable] but holds 2-state result.
///
/// [Result] from [package:async](https://pub.dev/packages/async) is used to represents 2-state data
mixin BuildResultListenable<T> implements BuildResult<T> {
  /// Contract to to build view when [error] occurred
  ///
  /// By default it build view with [DefaultBuildActions]
  Widget buildError(BuildContext context, Object error) => DefaultBuildActions.buildError(context, error);

  /// Build view for [ResultNotifier] with [ValueListenableBuilder]
  ///
  /// [key] specifies [StreamBuilder]'s key
  Widget buildResultListenable(ResultNotifier<T> listenable, {Key key}) =>
      buildValueListenable(listenable.asValueListenable(), key: key);

  /// Build view for [ValueListenable] with [ValueListenableBuilder]
  /// [ValueListenable] holds 2-state [Result] instead of plain value
  ///
  /// [key] specifies [ValueListenableBuilder]'s key
  Widget buildValueListenable(ValueListenable<Result<T>> listenable, {Key key}) => ValueListenableBuilder(
        key: key,
        valueListenable: listenable,
        builder: (BuildContext context, Result<T> value, _) {
          if (value.isValue) {
            return buildValue(context, value.asValue.value);
          } else {
            return buildError(context, value.asError.error);
          }
        },
      );
}
