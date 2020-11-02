import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'default_build_actions.dart';

/// Protocol that builds value
///
/// [BuildValue] is designed to be a conceptual protocol, which would be rarely used directly.
///
/// * To build a value from [ValueListenable], use [BuildValueListenable]
/// * To build 2-state sync result from [ResultListenable], consider use [BuildResultListenable]
/// * To build 3-state async result from [Request], [Future] or [Stream], consider use [BuildAsyncSnapshot]
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
/// * To build 3-state async result from [Request], [Future] or [Stream], consider use [BuildAsyncSnapshot]
mixin BuildResult<T> implements BuildValue<T> {
  /// Contract to to build view when [error] occurred
  Widget buildError(BuildContext context, Object error) => DefaultBuildActions.buildError(context, error);
}

/// Protocol that builds 3-state async result, which can be:
///
/// * initial: not yet initialized or data source is null
/// * waiting: data is being loaded
/// * error: an error occurred
/// * value: data if properly loaded
///
/// [BuildAsyncResult] is considered as a conceptual protocol, which should be rarely used directly.
/// [BuildAsyncSnapshot] is a ready-to-use implementation of [BuildAsyncResult]
mixin BuildAsyncResult<T> implements BuildResult<T> {
  /// Contract to build view when data source hasn't connected yet
  Widget buildNoDataSource(BuildContext context) => buildLoading(context);

  /// Contract to build view when data is being loaded
  Widget buildLoading(BuildContext context) => DefaultBuildActions.buildLoading(context);

  /// Contract to build view when [error] occurred
  Widget buildError(BuildContext context, Object error) => DefaultBuildActions.buildError(context, error);
}

/// Protocol that builds 3-state async result from a [Future], a [Stream] or a [Request]
///
/// * Use [buildFuture] to consume async data from [Future]
/// * Use [buildStream] to consume async data from [Stream]
/// * Use [buildRequest] to consume async data from [Request]
///
/// By default, [buildError] invokes [DefaultBuildActions.buildError]
/// [buildLoading] invokes [DefaultBuildActions.buildLoading]
mixin BuildAsyncSnapshot<T> implements BuildAsyncResult<T> {
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
}

/// Protocol to build data which potentially could be empty
///
/// When data is empty data, it build the widget with [buildEmpty], which render an empty view by default.
/// When data is not empty, it builds the widget with [buildContent], which needs to be implemented by developer.
///
/// [WithEmptyValue] implements [BuildValue] contract, so it works automatically with protocols depends on it,
/// includes [BuildAsyncSnapshot], [BuildValueListenable], and [BuildResultListenable].
mixin WithEmptyValue<T> implements BuildValue<T> {
  /// Check whether data is empty
  ///
  /// By default, [checkIsValueEmpty] understands
  ///
  /// * Anything implements [Iterable], which includes
  ///   * Dart built-in collection types, such as [List], [Set], etc.
  ///   * 3rd-party collection types, such as `BuiltList` from [package:built_collection](https://pub.dev/packages/built_collection) or `KtList` from [package:kt_dart](https://pub.dev/packages/kt_dart)
  /// * [Map], which might be parsed from json or loaded from other storage
  /// * `null` is always considered as empty
  ///
  /// Throws [UnsupportedError] when [T] is not [Iterable], [Map], or `null`.
  /// Implementer should override this contract when used with customized data type.
  bool checkIsValueEmpty(T value) {
    if (value == null) return true;
    if (value is Iterable) return value.isEmpty;
    if (value is Map) return value.entries.isEmpty;

    throw UnsupportedError("Check empty for $T is not supported");
  }

  /// Contract to build view when data isn't empty
  ///
  /// Implementer should always implement this contract
  Widget buildContent(BuildContext context, T content);

  /// Contract to build view when data is empty
  ///
  /// By default it builds an empty [Container], which is renders nothing on screen.
  ///
  /// Implementer can override this contract to change other behaviour
  Widget buildEmpty(BuildContext context, T emptyContent) => Container();

  /// Behavior implementation of contract of [BuildValue]
  ///
  /// Implementer should rarely need to override this contract when using [WithEmptyValue],
  /// or it is likely to be misuse.
  Widget buildValue(BuildContext context, T value) {
    if (checkIsValueEmpty(value)) return buildEmpty(context, value);
    return buildContent(context, value);
  }
}
