import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:response_builder/response_builder.dart';

/// Protocol that builds always-exist data from [ValueListenable]
extension BuildValueListenable<T> on BuildValue<T> {
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
extension BuildResultListenable<T> on BuildResult<T> {
  /// Build view for [ResultNotifier] with [ValueListenableBuilder]
  ///
  /// [key] specifies [StreamBuilder]'s key
  Widget buildResultListenable(ResultNotifier<T> listenable, {Key key}) => ValueListenableBuilder(
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
