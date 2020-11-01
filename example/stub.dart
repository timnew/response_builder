import 'package:flutter/material.dart';

class SearchItem {}

class Response {
  int statusCode;

  List<SearchItem> parseBody() => null;
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

class SearchResultFile {
  Future<List<SearchItem>> read() {}

  Future writes(List<SearchItem> currentData) {}

  Future close() {}
}
