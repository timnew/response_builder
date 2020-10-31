import 'package:flutter/material.dart';
import 'package:response_builder/response_builder.dart';

class MyListWidget extends StatelessWidget with BuildAsyncResult<List<String>>, WithEmptyData<List<String>> {
  final Future<List<String>> future;

  const MyListWidget({Key key, this.future}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return buildFuture(future);
  }

  // Instead of implement buildData, you should implement buildContent as minimal implementation
  @override
  Widget buildContent(BuildContext context, List<String> content) {
    // Implement contract from WithEmptyData to build not empty content

    // content will never be empty
    assert(content.isNotEmpty);

    return ListView.builder(
      itemCount: content.length,
      itemBuilder: (_, index) => Text(content[index]),
    );
  }

  @override
  bool checkIsDataEmpty(List<String> data) {
    return data.where((e) => e.isNotEmpty).isEmpty;
  }
}
