import 'package:flutter/widgets.dart';

mixin BuildWithBuilder {
  Widget buildWithBuilder(
          BuildContext context, TransitionBuilder builder, Widget child) =>
      builder == null ? child : builder(context, child);
}

mixin BuildWithBuilderInLocalContext {
  Widget buildWithBuilder(TransitionBuilder builder, Widget child) =>
      builder == null
          ? child
          : Builder(builder: (context) => builder(context, child));
}
