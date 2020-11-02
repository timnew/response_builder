import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:response_builder/response_builder.dart';

/// Actions that depends on Protocol [ValueListenable]
extension BuildValueListenable<T> on BuildValue<T> {
  /// Build view for [ValueListenable] with [ValueListenableBuilder]
  ///
  /// [key] specifies the key of [ValueListenableBuilder]
  Widget buildValueListenable(ValueListenable<T> listenable, {Key key}) =>
      ValueListenableBuilder(
        key: key,
        valueListenable: listenable,
        builder: (BuildContext context, T value, _) =>
            buildValue(context, value),
      );
}

/// Actions that depends on Protocol [BuildResult]
extension BuildResultListenable<T> on BuildResult<T> {
  /// Build view for [ResultNotifier]
  ///
  /// [key] specifies [ValueListenableBuilder]'s key
  Widget buildResultListenable(ResultNotifier<T> listenable, {Key key}) =>
      ValueListenableBuilder(
        key: key,
        valueListenable: listenable.asValueListenable(),
        builder: (BuildContext context, Result<T> value, _) {
          if (value.isValue) {
            return buildValue(context, value.asValue.value);
          } else {
            return buildError(context, value.asError.error);
          }
        },
      );
}

extension BuildAsyncSnapshotActions<T> on BuildAsyncSnapshot<T> {
  /// Build view for a [Future]
  ///
  /// [key] specifies [FutureBuilder]'s key
  /// [initialData] specifies [FutureBuilder]'s initial value
  Widget buildFuture(Future<T> future, {Key key, T initialData}) =>
      FutureBuilder(
          key: key,
          future: future,
          builder: buildAsyncSnapshot,
          initialData: initialData);

  /// Build view for a [Stream]
  ///
  /// [key] specifies [StreamBuilder]'s key
  /// [initialData] specifies [StreamBuilder]'s initial value
  Widget buildStream(Stream<T> stream, {Key key, T initialData}) =>
      StreamBuilder(
          key: key,
          stream: stream,
          builder: buildAsyncSnapshot,
          initialData: initialData);

  /// Build view for a [Request]
  ///
  /// [key] specifies [StreamBuilder]'s key
  /// [initialData] specifies [StreamBuilder]'s initial value
  Widget buildRequest(Request<T> request, {Key key, T initialData}) =>
      buildStream(request?.resultStream, key: key, initialData: initialData);
}
