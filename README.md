# response_builder

[![Star this Repo](https://img.shields.io/github/stars/timnew/response_builder.svg?style=flat-square)](https://github.com/timnew/response_builder)
[![Pub Package](https://img.shields.io/pub/v/response_builder.svg?style=flat-square)](https://pub.dev/packages/response_builder)

## Why create this library?

`FutureBuilder` `StreamBuilder` are the foundation to consume any data that loaded from network or persistent storage. `FutureBuilder` `StreamBuilder` are designed to be robust, flexible but it is not designed to be convenient. In fact handling with `AsyncValueSnapshot` in the callback is actually kind of complicated and error-prone, especially when you needs busy state, initial value, or switcing to observe new future/stream from the old ones. Any mistake in the callback could cause bug in UI.

To reduce the complexity and avoid repetivie work to implement `AsyncWidgetBuilder` a thousand times, this libary introduce some mixins, which help developer to consuem data from future, stream, value listanble or other kind of observable sources in a nice and easy way.

## What response_builder can do?

It enables flutter developer to implement following features with minimum effort:

* **Loading Screen**: Show a loading view when data not comming back
* **Error Screen**: Show an error screen when something goes wrong
* **Empty Screen**: Some something useful when API returns an empty list (As `ListView` and others don't support to render empty collection)
* **Refresh/Retry**: Fire the same request again when something goes wrong or just want to refresh the data
* **Optimal update**: update the UI optimally first, and refresh UI again when API returns.

## Consume data from Future/Stream

To consume data from Future/Stream with `response_builder` library is very easy:

1. Create a stateless/stateful widget
2. Include `BuildAsyncResult<T>` mixin, `T` is the the data type contained in `Stream`/`Future`
3. Implement `buildData`, which is used to render the UI when the data is successfully loaded from `Stream`, `Future`.
4. Calling `buildFuture`/`buildStream` in widget's `build` method, to trigger wire the data source to `BuildAsyncResult` mixin.

```dart
import 'package:response_builder/response_builder.dart';

class MyWidget extends StatelessWidget with BuildAsyncResult<String> {
  final dynamic dataSource; // Stream<String> or Future<String>

  MyWidget(this.dataSource)
      : assert(dataSource != null),
        assert(dataSource is Stream<String> || dataSource is Stream<String>);

  @override
  Widget build(BuildContext context) {
    if (dataSource is Stream)
      // Calling buildStream is dataSource is Stream
      return buildStream(dataSource);
    else
      // Calling buildFuture is dataSource is Future
      return buildFuture(dataSource);
  }

  @override
  Widget buildData(BuildContext context, String data) {
    // Implement buildData contract to render UI when data is successfully fetched
    return Center(
      child: Text(data),
    );
  }
}
```

With the code above, you will get:

* Render a loading screen automatically before the data is ready
* Render a error screen automatically before if data source yields error

## Customize Error Screen / Loading Screen by overriding

You might want to customize the error screen / loading screen, which is also very easy:

* Override `buildWaiting` to customize the loading screen.
* Override `buildWaiting` to customize the busy screen.

```dart
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
  Widget buildWaiting(BuildContext context) {
    // This is the default Loading Screen implementation. You can customize it as your need.
    return Center(
      child: CircularProgressIndicator(value: null),
    );
  }

  @override
  Widget buildError(BuildContext context, Object error) {
    // This is the default Error Screen implementation, you can customize it as your need.
    final errorColor = Theme.of(context).errorColor;

    return Center(
      child: Row(children: [
        Icon(Icons.error_outline, color: errorColor),
        Text(error.toString(), style: TextStyle(color: errorColor)),
      ]),
    );
  }

  @override
  Widget buildData(BuildContext context, String data) {
    return Center(
      child: Text(data),
    );
  }
}
```

## Customize default Error Screen / Loading Screen build actions

Sometimes the default error screen/loading screen might not suits your app, such as you're using `CuptertinoApp` instead of `MaterialApp`, but override `buildWaiting` and `buildError` in every widget uses `BuildAsyncResult` could be a tedious and heavy task. Luckily, you actually don't need to do that.

`BuildAsyncResult` uses `DefaultBuildActions` to build the error screen/loading screen if
`buildWaiting` or `buildError` is not override. And `DefaultBuildActions` allow to you register your own error builder and waiting builder.

```dart
DefaultBuildActions.registerDefaultWaitingBuilder((context) {
  // Build Cupertino Style Loading Screen

  return Center(
    child: CupertinoActivityIndicator(),
  );
});

DefaultBuildActions.registerDefaultErrorBuilder((context, error) {
  // Build Cupertino Style Error Screen
  final errorColor = CupertinoColors.systemRed;

  return Center(
    child: Row(children: [
      Icon(CupertinoIcons.xmark_circle, color: errorColor),
      Text(error.toString(), style: TextStyle(color: errorColor)),
    ]),
  );
});
```

**HINT:** Register default builder with `DefaultBuildActions` will only impact those widgets uses `BuildAsyncResult` without overriding `buildError` or `buildWaiting`. Customized override will be respected

## Handle empty data

Sometimes our API returns successfully without error, but it gives empty result, such as user doing a search with typos in keywords which leads to nothing. And also if you render the UI with `ListView` or other collection widgets, which unfortunately doesn't support to build empty list.

`response_builder` provided `WithEmptyData<T>` mixin to tackle this issue, what's more is `WithEmptyData<T>` is aware of the contracts from `BuildAsyncResult<T>` or other builder mixins, so it just work together automatically without any additional effort.

```dart
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
}
```

## Customize Empty Screen for `WithEmptyData`

By Default, `WithEmptyData` renders an empty `Container` when empty data is received, so it looks like an blank screen from user's perspective, while `ListView` would complain if you feed it with an empty list.

But sometimes, you might also want to render a more meaningful empty screen rather than just a blank screen. Then you can override `buildEmpty` method.

```dart
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
  Widget buildEmpty(BuildContext context, List emptyContent) {
    // Override Empty Screen
    return Center(
      child: Text("There is nothing here"),
    );
  }
}
```

## Handle empty data model in `WithEmptyData`

By default `WithEmptyData` is smart enough to understand the common data types:

* `null` is always treated as `empty content`
* Anything implements `Iterable`
  * Dart built-in collection types, such as `List` or `Set`
  * 3rd party collection types, such as `BuiltList`, `KtList`
* `Map`, probably parsed from a json object or so.

But if you're using a customized data object, which isn't a `Map` or `Iterable`, or you want to do have your own implementation logic, then you will need to override `checkIsDataEmpty` method, or you might get an `UnsupportedError`.

```dart
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
    // Only count non-empty string
    return data.where((e) => e.isNotEmpty).isEmpty;
  }
}
```

## Load data asynchronously with `Request`

Loading data from network or data base is a extremely common behaviour of majority of the apps. Unfortunately `Future` or `Stream` is kind of too low level to implement app's common requirements.

`Request` is a production-ready abstraction of common behavior that loads data from either an API or making a query to database.

`Request` provides some useful API which enable developer to implement following commonly-seen features easily:

* Retry when error API call fails
* Refresh data automatically without being noticed by user
* Optimal update based user's action first, and refresh UI again when API returns.

`buildRequest` from `BuildAsyncResult` allow developer to consume the data from `Request` with no difference from  `buildFuture` or `buildStream`.

Here is an example request that make a search of given keywords:

```dart
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
```

Here is the Widget to render the search result:

```dart
class SearchResultView extends StatelessWidget with BuildAsyncResult<List<SearchItem>>, WithEmptyData<List<SearchItem>> {
  final MySearchRequest request;

  SearchResultView(this.request);

  @override
  Widget build(BuildContext context) {
    // use method from BuildAsyncResult to render request
    return buildRequest(request);
  }

  @override
  Widget buildError(BuildContext context, Object error) {
    return Center(
      child: Row(children: [
        Text(error.toString()),
        TextButton(
          child: Text("Retry"),
          onPressed: () => request.reload(), // Retry to do search again
        )
      ]),
    );
  }

  @override
  Widget buildContent(BuildContext context, List<SearchItem> content) {
    return ListView.builder(
      itemCount: content.length,
      itemBuilder: (context, index) => SearchItemView(content[index]),
    );
  }
}
```

## Use `Request` out side of widget building

`Request` is naturally a good place to implement data loading business logic. But it can do more thant that, `Request` provides a bunch of APIs allow developer to manage its value, so it can a good place to encapsulate business logic that related to the data that request holds. And any updates to request's data would be rendered properly, if it is consumed by `BuildAsyncResult`

Because `Request` is highly optimized for the scenario that loading data asynchronously, such as **calling an API** or **querying database**, in those particular use-cases,  `Request` could be good replacement of

* `bloc` from [Bloc](https://pub.dev/packages/bloc)
* `observable` from [MobX](https://pub.dev/packages/mobx)
* `reducer` in [redux](https://pub.dev/packages/flutter_redux)

```dart
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
    if (this.hasData) {
      // write search result to file if it exists
      await file.writes(currentData);
    } else if (this.hasError) {
      // writes error to file with writeError method
      await file.writeError(currentError);
    }
    // Skip if no data is loaded yet.
  }

  Future loadSearchResult(SearchResultFile file) async {
    Future<List<SearchItem>> Function() loadAction = file.read;

    // update request with data or error loaded from the file
    await execute(loadAction);
  }

  void clearSearchResult() {
    // Set value of request synchronously
    putValue([]);
  }

  void trimResult(int limit) {
    // Update result based on current data;
    updateValue((current) => currnt.take(limit).toList());
  }

  Future appendFromFile(SearchResultFile file) {
    // Update result based on current data asynchronously
    return updateValueAsync((current) async => current + await file.read());
  }
}
```

## Handle 2-state result with `ResultNotifier`

Flutter provided `ValueListenable` as synchronous observable data source. `ValueListenable` can only holds data, but not error, which is occasionally needed.

`response_builder` provides `ResultListenable`, `ResultNotifier`, which is parallel to `ValueListenable` `ValueNotifier`, but holds 2-state `Result` instead of only data.

2-state result is represented with `Result` from [async](https://pub.dev/packages/async) package

### Example

Suppose `FormData` model holds a list of fields value. Field value is always string, but its could be valid or invalid.

```dart
class FormData {
  final Map<String, ResultNotifier<String>> fields;

  FormData(Map<String, String> initialValues)
      : fields = Map.fromIterables(
          initialValues.keys, // field keys
          initialValues.values.map(
            // wrap initial with ResultNotifier
            (initialValue) => ResultNotifier(initialValue),
          ),
        );

  void invalidField(String fieldName) {
    // String can be thrown
    // Notifier would treat thrown string as error
    fields[fieldName].updateValue((current) => throw current);
  }

  void validField(String fieldName) {
    // Fix error only execute when notifier holds error
    // the returned value is used as value
    fields[fieldName].fixError((error) => error);
  }
}
```

## Build `ResultNotifier` with `BuildResultListenable`

`ResultNotifier` can be listened with `BuildResultListenable`, which shares the similar contract as `BuildAsyncResult`

### Example

```dart
class FormFieldView extends StatelessWidget with BuildResultListenable<String> {
  final String fieldName;
  final ResultListenable<String> listenable;

  const FormFieldView({Key key, this.fieldName, this.listenable}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(fieldName),
        buildResultListenable(listenable),
      ],
    );
  }

  @override
  Widget buildData(BuildContext context, String data) {
    return Text(data);
  }

  @override
  Widget buildError(BuildContext context, Object error) {
    final errorColor = Theme.of(context).errorColor;

    final badData = error as String;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Icon(Icons.error_outline, color: errorColor),
        ),
        Text(badData, style: TextStyle(color: errorColor)),
      ],
    );
  }
}
```

**HINT**  `WithEmptyData`  can be used with`BuildResultListenable` to handle empty content too.

## Consume `ValueListenable` with `BuildValueListenable`

Similar to `BuildResultListenable`, built-in `ValueListenable` can be consumed with `BuildValueListenable` with compatible manner.

**HINT**  `WithEmptyData`  can be used with`BuildValueListenable` to handle empty content too.

## License

The MIT License (MIT)