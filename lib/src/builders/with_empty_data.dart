import 'package:flutter/widgets.dart';

import 'build_mixins.dart';

/// Protocol to build data which potentially could be empty
///
/// When data is empty data, it build the widget with [buildEmpty], which render an empty view by default.
/// When data is not empty, it builds the widget with [buildContent], which needs to be implemented by developer.
///
/// [WithEmptyData] implements [BuildData] contract, so it works automatically with protocols depends on it,
/// includes [BuildAsyncResult], [BuildValueListenable], and [BuildResultListenable].
mixin WithEmptyData<T> implements BuildData<T> {
  /// Check whether data is empty
  ///
  /// By default, [checkIsDataEmpty] understands
  ///
  /// * Anything implements [Iterable], which includes
  ///   * Dart built-in collection types, such as [List], [Set], etc.
  ///   * 3rd-party collection types, such as `BuiltList` from [package:built_collection](https://pub.dev/packages/built_collection) or `KtList` from [package:kt_dart](https://pub.dev/packages/kt_dart)
  /// * [Map], which might be parsed from json or loaded from other storage
  /// * `null` is always considered as empty
  ///
  /// Throws [UnsupportedError] when [T] is not [Iterable], [Map], or `null`.
  /// Implementer should override this contract when used with customized data type.
  bool checkIsDataEmpty(T data) {
    if (data == null) return true;
    if (data is Iterable) return data.isEmpty;
    if (data is Map) return data.entries.isEmpty;

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

  /// Implement the contract of [BuildData]
  ///
  /// Implementer should rarely need to override this contract when using [WithEmptyData],
  /// or it is likely to be misuse.
  Widget buildData(BuildContext context, T data) {
    if (checkIsDataEmpty(data)) return buildEmpty(context, data);
    return buildContent(context, data);
  }
}
