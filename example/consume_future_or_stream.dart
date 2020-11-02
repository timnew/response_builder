import 'package:flutter/material.dart';
import 'package:response_builder/response_builder.dart';

class MyWidget extends StatelessWidget with BuildAsyncResult<String> {
  final dynamic dataSource; // Stream<String> or Future<String>

  MyWidget(this.dataSource)
      : assert(dataSource != null),
        assert(dataSource is Stream<String> || dataSource is Stream<String>);

  @override
  Widget build(BuildContext context) {
    if (dataSource is Stream)
      return buildStream(dataSource);
    else
      return buildFuture(dataSource);
  }

  @override
  Widget buildLoading(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(value: null),
    );
  }

  @override
  Widget buildError(BuildContext context, Object error) {
    return Center(
      child: Text(error.toString()),
    );
  }

  @override
  Widget buildValue(BuildContext context, String value) {
    return Center(
      child: Text(value),
    );
  }
}
