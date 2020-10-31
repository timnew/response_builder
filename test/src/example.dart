import 'package:flutter/material.dart';
import 'package:response_builder/builder_only.dart';
import 'package:response_builder/response_builder.dart';

class SearchItem {}

class BuiltList<T> {
  int length;

  T operator [](int index) {
    return null;
  }
}

class Response {
  int statusCode;

  BuiltList<SearchItem> parseBody() => null;
}

class NetworkException {
  NetworkException(String message);
}

class SearchApi {
  Future<Response> search({String keywords}) async {
    return null;
  }
}

final searchApi = SearchApi();

class SearchItemView extends StatelessWidget {
  SearchItemView(SearchItem ensuredCurrentData);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}


class MySearchRequest extends Request<BuiltList<SearchItem>> {
  final String keywords;

  MySearchRequest(this.keywords);

  Future<BuiltList<SearchItem>> load() async {
    final response = await searchApi.search(keywords: keywords);

    if (response.statusCode != 200) {
      throw NetworkException("Failed to execute search, please retry");
    }

    return response.parseBody();
  }
}

class SearchResultView extends StatelessWidget with RenderAsyncSnapshot<BuiltList<SearchItem>> {
  final MySearchRequest request;

  SearchResultView(this.request);

  @override
  Widget build(BuildContext context) => buildRequest(request);

  @override
  Widget buildWaiting(BuildContext context) => Center(child: CircularProgressIndicator(value: null));

  Widget buildError(BuildContext context, Object error) => Center(
        child: Row(children: [
          Text(error.toString()),
          TextButton(
            child: Text("Retry"),
            onPressed: () => request.reload(),
          )
        ]),
      );

  @override
  Widget buildData(BuildContext context, BuiltList<SearchItem> data) => ListView.builder(
        itemCount: request.ensuredCurrentData.length,
        itemBuilder: (context, index) => SearchItemView(request.ensuredCurrentData[index]),
      );
}
