import 'dart:async';

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

  Future saveSearchResult(SearchResultFile file) async {
    if (this.hasValue) {
      await file.writes(currentData);
    }
  }

  Future loadSearchResult(SearchResultFile file) async {
    FutureOr<List<SearchItem>> Function() loadAction = file.read;
    await execute(loadAction);
  }

  void clearSearchResult() {
    putValue([]);
  }

  void trimResult(int limit) {
    updateValue((current) => current.take(limit).toList());
  }

  Future appendFromFile(SearchResultFile file) {
    return updateValueAsync((current) async => current + await file.read());
  }
}

class SearchResultView extends StatelessWidget
    with BuildAsyncResult<List<SearchItem>> {
  final MySearchRequest request;

  SearchResultView(this.request);

  @override
  Widget build(BuildContext context) {
    // use method from BuildAsyncResult to render request
    return buildRequest(request);
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
  Widget buildValue(BuildContext context, List<SearchItem> value) {
    return ListView.builder(
      itemCount: request.ensuredCurrentData.length,
      itemBuilder: (context, index) =>
          SearchItemView(request.ensuredCurrentData[index]),
    );
  }
}
