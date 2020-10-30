import 'package:flutter/widgets.dart';

import 'render_mixins.dart';

mixin WithEmptyContent<T> implements RenderData<T> {
  bool checkEmpty(T data);

  Widget buildContent(BuildContext context, T content);

  Widget buildEmpty(BuildContext context);

  Widget buildData(BuildContext context, T data) {
    if (checkEmpty(data)) return buildEmpty(context);
    return buildContent(context, data);
  }
}
