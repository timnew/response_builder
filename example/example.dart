import 'package:flutter/material.dart';
import 'package:response_builder/response_builder.dart';

import 'stub.dart';

class MySearchRequest extends Request<List<SearchItem>> {
  final String keywords;

  MySearchRequest(this.keywords);

  Future<List<SearchItem>> load() async {
    final response = await searchApi.search(keywords: keywords);

    if (response.statusCode != 200) {
      throw NetworkException("Failed to execute search, please retry");
    }

    return response.parseBody();
  }
}

class SearchResultView extends StatelessWidget with BuildAsyncResult<List<SearchItem>> {
  final MySearchRequest request;

  SearchResultView(this.request);

  @override
  Widget build(BuildContext context) {
    // use method from BuildAsyncResult to render request
    return buildRequest(request);
  }

  @override
  Widget buildWaiting(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(value: null),
    );
  }

  @override
  Widget buildError(BuildContext context, Object error) {
    return Center(
      child: Row(children: [
        Text(error.toString()),
        TextButton(
          child: Text("Retry"),
          onPressed: () => request.reload(),
        )
      ]),
    );
  }

  @override
  Widget buildData(BuildContext context, List<SearchItem> data) {
    return ListView.builder(
      itemCount: request.ensuredCurrentData.length,
      itemBuilder: (context, index) => SearchItemView(request.ensuredCurrentData[index]),
    );
  }
}
