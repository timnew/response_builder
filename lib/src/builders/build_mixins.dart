import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:response_builder/src/request.dart';
import 'package:response_builder/src/result_store.dart';

import 'default_build_actions.dart';

mixin BuildData<T> {
  Widget buildData(BuildContext context, T data);
}

mixin BuildResult<T> implements BuildData<T> {
  Widget buildError(BuildContext context, Object error) => DefaultBuildActions.buildError(context, error);
}

mixin BuildAsyncResultProtocol<T> implements BuildResult<T> {
  Widget buildInitialState(BuildContext context) => buildWaiting(context);

  Widget buildWaiting(BuildContext context) => DefaultBuildActions.buildWaiting(context);

  Widget buildError(BuildContext context, Object error) => DefaultBuildActions.buildError(context, error);
}

mixin BuildAsyncResult<T> implements BuildAsyncResultProtocol<T> {
  Widget buildInitialState(BuildContext context) => buildWaiting(context);

  Widget buildWaiting(BuildContext context) => DefaultBuildActions.buildWaiting(context);

  Widget buildError(BuildContext context, Object error) => DefaultBuildActions.buildError(context, error);

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

  Widget buildFuture(Future<T> future, {Key key, T initialData}) =>
      FutureBuilder(key: key, future: future, builder: buildAsyncSnapshot, initialData: initialData);

  Widget buildStream(Stream<T> stream, {Key key, T initialData}) =>
      StreamBuilder(key: key, stream: stream, builder: buildAsyncSnapshot, initialData: initialData);

  Widget buildRequest(Request<T> request, {Key key, T initialData}) =>
      buildStream(request?.valueStream, key: key, initialData: initialData);
}

mixin BuildValueListenable<T> implements BuildData<T> {
  Widget buildValueListenable(ValueListenable<T> listenable, {Key key}) => ValueListenableBuilder(
        key: key,
        valueListenable: listenable,
        builder: (BuildContext context, T value, _) => buildData(context, value),
      );
}

mixin BuildResultListenable<T> implements BuildResult<T> {
  Widget buildError(BuildContext context, Object error) => DefaultBuildActions.buildError(context, error);

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

  Widget buildStore(ResultStore<T> store, {Key key}) => buildResultListenable(store.listenable, key: key);
}
