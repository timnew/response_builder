import 'package:flutter/widgets.dart';

import 'build_mixins.dart';

/// Protocol to build data which potentially could be empty
///
/// When data is empty data, it build the widget with [buildEmpty], which render an empty view by default.
/// When data is not empty, it builds the widget with [buildContent], which needs to be implemented by developer.
///
/// [WithEmptyValue] implements [BuildValue] contract, so it works automatically with protocols depends on it,
/// includes [BuildAsyncResult], [BuildValueListenable], and [BuildResultListenable].
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

  /// Implement the contract of [BuildValue]
  ///
  /// Implementer should rarely need to override this contract when using [WithEmptyValue],
  /// or it is likely to be misuse.
  Widget buildValue(BuildContext context, T value) {
    if (checkIsValueEmpty(value)) return buildEmpty(context, value);
    return buildContent(context, value);
  }
}
