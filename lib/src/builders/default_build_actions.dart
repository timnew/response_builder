import 'package:flutter/material.dart';

typedef ValueWidgetBuilder<T> = Widget Function(BuildContext context, T value);

/// Default building actions that used by [BuildResultListenable] and [BuildAsyncResult]
class DefaultBuildActions {
  static ValueWidgetBuilder<Object> _customErrorBuilder;
  static WidgetBuilder _customWaitingBuilder;

  DefaultBuildActions._();

  /// Register customized [errorBuilder], which is used by [BuildResultListenable.buildError]
  /// and [BuildAsyncResult.buildError] by default.
  static void registerDefaultErrorBuilder(ValueWidgetBuilder<Object> errorBuilder) {
    _customErrorBuilder = errorBuilder;
  }

  /// Register customized [waitingBuilder], which is used by [BuildAsyncResult.buildLoading] by default.
  static void registerDefaultLoadingBuilder(WidgetBuilder waitingBuilder) {
    _customWaitingBuilder = waitingBuilder;
  }

  /// Build error view for [error]
  static Widget buildError(BuildContext context, Object error) {
    if (_customErrorBuilder != null) return _customErrorBuilder(context, error);

    final errorColor = Theme.of(context).errorColor;

    return Center(
      child: Row(children: [
        Icon(Icons.error_outline, color: errorColor),
        Text(error.toString(), style: TextStyle(color: errorColor)),
      ]),
    );
  }

  /// Build loading view
  static Widget buildLoading(BuildContext context) {
    if (_customWaitingBuilder != null) return _customWaitingBuilder(context);
    return Center(child: CircularProgressIndicator(value: null));
  }
}
