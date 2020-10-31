import 'package:flutter/widgets.dart';

import 'build_mixins.dart';

mixin WithEmptyData<T> implements BuildData<T> {
  bool checkIsDataEmpty(T data) {
    if (data == null) return true;
    if (data is Iterable) return data.isEmpty;
    if (data is Map) return data.entries.isEmpty;
    
    throw UnsupportedError("Check empty for $T is not supported");
  }

  Widget buildContent(BuildContext context, T content);

  Widget buildEmpty(BuildContext context, T emptyContent) => Container();

  Widget buildData(BuildContext context, T data) {
    if (checkIsDataEmpty(data)) return buildEmpty(context, data);
    return buildContent(context, data);
  }
}
