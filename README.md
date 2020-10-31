# response_builder



[![Star this Repo](https://img.shields.io/github/stars/timnew/response_builder.svg?style=flat-square)](https://github.com/timnew/response_builder)
[![Pub Package](https://img.shields.io/pub/v/response_builder.svg?style=flat-square)](https://pub.dev/packages/response_builder)


Request Render is a package to simplify the implementation to load data from network, as well as local updates / optimic updates.

## Getting Start

### Request

Request is a representation of the data that loads asychronisedly, such as data loads from API or from other asynchronised source.

#### Create your own request class

Implment a request is relatively easy, create your own request class, and implement `load` method, which returns a Future or sync result.

```dart
class MySearchRequest extends Request<BuiltList<SearchItem>> {
  final String keywords;
  
  MySearchRequest(this.keywords);
  
  Future<BuiltList<SearchItem>> load() async {
	  final response = await searchApi.search(keywords: keywords);
	  
	  if(response.statusCode != 200) {
	  	 throw NetworkException("Failed to execute search, please retry");
	  }
	  
	  return response.parseBody();
  }
}
```

#### Render the request

```dart
class SearchResultView extends StatelessWidget with RenderAsyncSnapshot<BuiltList<SearchItem>> {
  final MySearchRequest request;

  SearchResultView(this.request);

  @override
  Widget build(BuildContext context) => 
    // use method from RenderAsyncSnapshot to render request
    buildRequest(request);

  @override
  Widget buildWaiting(BuildContext context) =>
    // Contract in RenderAsyncSnapshot
    // Render busy screen before data is loaded
    Center(child: CircularProgressIndicator(value: null));come back

  Widget buildError(BuildContext context, Object error) => 
     // Contract in RenderAsyncSnapshot
     // Render error screen when exception happens
     Center(
        child: Row(children: [
          Text(error.toString()),
          TextButton(
            child: Text("Retry"),
            onPressed: () => request.reload(), // Retry
          )
        ]),
      );

  @override
  Widget buildData(BuildContext context, BuiltList<SearchItem> data) =>
      // Contract in RenderAsyncSnapshot
      // Render data when data is fetched
      ListView.builder(
        itemCount: request.ensuredCurrentData.length,
        itemBuilder: (context, index) => SearchItemView(request.ensuredCurrentData[index]),
      );
}
```




### ResultValueStore

### SingletonRegistry


## Other Libraries

This library is designed to used along with following libraries, but it is okay to use it without those libs:

* [RxDart]: To access value synchronised from stream
* [async]: For ValueListanble with value or error.
* [provider]: To access request or store provided by parent
* [freezed] or [built_value]: For immutable data models
* [built_collection] or [kt_dart]: for immutable collection



  
## License

The MIT License (MIT)
 
[RxDart]: https://pub.dev/packages/rxdart
[async]: https://pub.dev/packages/async
[provider]: https://pub.dev/packages/provider
[freezed]: https://pub.dev/packages/freezed
[built_value]: https://pub.dev/packages/built_value
[built_collection]: https://pub.dev/packages/built_collection
[kt_dart]:https://pub.dev/packages/kt_dart

