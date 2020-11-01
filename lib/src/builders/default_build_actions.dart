import 'package:flutter/material.dart';

typedef DataWidgetBuilder<T> = Widget Function(BuildContext context, T data);

/// Default building actions that used by [BuildResultListenable] and [BuildAsyncResult]
class DefaultBuildActions {
  static DataWidgetBuilder<Object> _customErrorBuilder;
  static WidgetBuilder _customWaitingBuilder;

  DefaultBuildActions._();

  /// Register customized [errorBuilder], which is used by [BuildResultListenable.buildError]
  /// and [BuildAsyncResult.buildError] by default.
  static void registerDefaultErrorBuilder(DataWidgetBuilder<Object> errorBuilder) {
    _customErrorBuilder = errorBuilder;
  }

  /// Register customized [waitingBuilder], which is used by [BuildAsyncResult.buildWaiting] by default.
  static void registerDefaultWaitingBuilder(WidgetBuilder waitingBuilder) {
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

  /// Build waiting view
  static Widget buildWaiting(BuildContext context) {
    if (_customWaitingBuilder != null) return _customWaitingBuilder(context);
    return Center(child: CircularProgressIndicator(value: null));
  }
}
