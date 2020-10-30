import 'package:flutter/material.dart';

import 'data_widget_builder.dart';

class DefaultRenders {
  static DataWidgetBuilder<Object> _customErrorBuilder;
  static WidgetBuilder _customWaitingBuilder;

  static void registerDefaultErrorBuilder(DataWidgetBuilder<Object> builder) {
    _customErrorBuilder = builder;
  }

  static void registerDefaultWaitingBuilder(WidgetBuilder builder) {
    _customWaitingBuilder = builder;
  }

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

  static Widget buildWaiting(BuildContext context) {
    if (_customWaitingBuilder != null) return _customWaitingBuilder(context);
    return Center(child: CircularProgressIndicator(value: null));
  }
}
