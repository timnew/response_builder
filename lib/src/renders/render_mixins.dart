import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:request_render/src/request.dart';

import 'default_renders.dart';
import '../result_store.dart';

export 'data_widget_builder.dart';

mixin RenderData<T> {
  Widget buildData(BuildContext context, T data);
}

mixin RenderResult<T> implements RenderData<T> {
  Widget buildError(BuildContext context, Object error) => DefaultRenders.buildError(context, error);
}

mixin RenderAsyncResult<T> implements RenderResult<T> {
  Widget buildInitialState(BuildContext context) => buildWaiting(context);

  Widget buildWaiting(BuildContext context) => DefaultRenders.buildWaiting(context);

  Widget buildError(BuildContext context, Object error) => DefaultRenders.buildError(context, error);
}

mixin RenderAsyncSnapshot<T> implements RenderAsyncResult<T> {
  Widget buildInitialState(BuildContext context) => buildWaiting(context);

  Widget buildWaiting(BuildContext context) => DefaultRenders.buildWaiting(context);

  Widget buildError(BuildContext context, Object error) => DefaultRenders.buildError(context, error);

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

mixin RenderValueListenable<T> implements RenderData<T> {
  Widget buildValueListenable(ValueListenable<T> listenable, {Key key}) => ValueListenableBuilder(
        key: key,
        valueListenable: listenable,
        builder: (BuildContext context, T value, _) => buildData(context, value),
      );
}

mixin RenderResultListenable<T> implements RenderResult<T> {
  Widget buildError(BuildContext context, Object error) => DefaultRenders.buildError(context, error);

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
