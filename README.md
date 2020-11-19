# response_builder

[![Star this Repo](https://img.shields.io/github/stars/timnew/response_builder.svg?style=flat-square)](https://github.com/timnew/response_builder)
[![Pub Package](https://img.shields.io/pub/v/response_builder.svg?style=flat-square)](https://pub.dev/packages/response_builder)
[![Build Status](https://img.shields.io/github/workflow/status/timnew/response_builder/Run-Test)](https://github.com/timnew/response_builder/actions?query=workflow%3ARun-Test)

## Why create this library

`FutureBuilder` `StreamBuilder` are the foundation to consume any data that loaded from network or persistent storage. `FutureBuilder`, `StreamBuilder` are designed to be robust, flexible but it is not designed to be convenient. In fact handling with `AsyncSnapshot` in the callback is actually kind of complicated and error-prone, especially when you needs busy state, initial value, or switching to observe new future/stream from the old ones. Any mistake in the callback could cause bug in UI.

To reduce the complexity and avoid repetitive work to implement `AsyncWidgetBuilder` a thousand times, this library introduce some mixins, which help developer to consume data from future, stream, value listenable or other kind of observable sources in a nice and easy way.

## What response_builder can do

It enables flutter developer to implement following features with minimum effort:

* **Loading Screen**: Show a loading view when data not comming back
* **Error Screen**: Show an error screen when something goes wrong
* **Empty Screen**: Some something useful when API returns an empty list (As `ListView` and others don't support to render empty collection)
* **Refresh/Retry**: Fire the same request again when something goes wrong or just want to refresh the data
* **Optimal update**: update the UI optimally first, and refresh UI again when API returns.

## What's in library

### Key types

* Data Source
  * [Request] - Listenable data source for 3-state asynchronous data
  * [ResultListenable] and [ResultNotifier] - Listenable data source for 2-state synchronized data
* Build Protocols
  * [BuildAsyncSnapshot] - This protocol enable [BuildAsyncSnapshotActions] to consume 3-state data from [Future], [Stream] or [Request]
  * [BuildResult] - This protocol enable enables [BuildResultListenable] to consume 2-state data from [ResultListenable]
  * [BuildValue] - This protocol enable enables [BuildValueListenable] to consume value from [ValueListenable]
  * [WithEmptyValue] - Protocol implement [BuildValue.buildValue] contract, which enables building actions to handle empty value
* Build Actions
  * [BuildAsyncSnapshotActions] - Actions run on [BuildAsyncSnapshot] protocol to consume 3-state `AsyncResult` data from [Future], [Stream] or [Request],
  * [BuildResultListenable] - Actions run on [BuildResult] protocol, to consume 2-state `Result` from [ResultListenable]
  * [BuildValueListenable] - Actions run on [BuildValue] protocol, to consume value from [ValueListenable]

## Consume `AsyncResult` from `Future`

To consume `AsyncResult` is easy:

1. Create widget, could be either stateless or stateful, them both works
2. Implement `BuildAsyncResult` protocol by add `BuildAsyncSnapshot<T>` mixin to the widget class for `StatelessWidget` or to the `State` class for `StatefulWidget`. `T` is the the data type hold by `Future`.
3. Implement a `Widget buildValue(BuildContext context, T value)` method, which is the contract to build widget when value is loaded from `Stream`, `Future`.
4. Calling `buildFuture` in widget's `build` method.
5. You're done.

```dart
class MyWidget extends StatelessWidget with BuildAsyncSnapshot<String> {
  final Future<T> dataSource;

  MyWidget(this.dataSource);

  @override
  Widget build(BuildContext context) {
      // Calling buildFuture is dataSource is Future
      return buildFuture(dataSource);
  }

  @override
  Widget buildValue(BuildContext context, String value) {
    // Implement buildValue contract to render UI when value is successfully fetched
    return Center(
      child: Text(value),
    );
  }
}
```

As `Future` holds `AsyncResult`, which could be `Loading`, `Value` or `Error`, so `MyWidget` also has 3 different state, based on `AsyncResult`:

* Renders a `CircularLoadingIndicator` in the middle of parent before result is ready.
* Render the value in the middle of the screen, when `Future` yields value
* Render `!` icon with message in `error color` of current theme in the middle of parent when `Future` yields error.

No more direct mess around the `AsyncSnapshot` or `FutureBuilder`.

## Customize Error View / Loading View

Default loading view / error view is convenient when it is more the focus of future. But sometimes you might do want to have granular control on how they looks like.
To do so, you can

* Override `buildError` method, which is the contract being used to build error view.
* Override `buildLoading` method, which is the contract being used to build loading view.

Here is some example, it builds UI in Cupertino style instead of Material style:

```dart
class MyWidget extends StatelessWidget with BuildAsyncSnapshot<List<String>> {
  final Future<T> dataSource;

  MyWidget(this.dataSource);

  @override
  Widget build(BuildContext context) {
      // Calling buildFuture is dataSource is Future
      return buildFuture(dataSource);
  }

  @override
  Widget buildLoading(BuildContext context) {
    // Build Cupertino style UI instead of default Material style
    return Center(
      child: CupertinoActivityIndicator(),
    );
  }

  @override
  Widget buildError(BuildContext context, Object error) {
    // Build Cupertino style UI instead of default Material style
    final errorColor = CupertinoColors.systemRed;

    return Center(
      child: Row(children: [
        Icon(CupertinoIcons.exclamationmark_circle, color: errorColor),
        Text(error.toString(), style: TextStyle(color: errorColor)),
      ]),
    );
  }

  @override
  Widget buildValue(BuildContext context, List<String> value) {
    return ListView.builder(
      itemCount: value.length,
      builder: (context, index) => Text(value[index]),
    );
  }
}
```

## Customize Error View / Loading View across the whole app

Overriding `buildError` and `buildLoading` contract provides detailed control of how error view or loading view would like. But it is done on a case by case manner.
Sometimes, we want to change them across the whole app. This can be done by registering `DefaultLoadingBuilder` and `DefaultErrorBuilder`.

Firstly, register the default builders somewhere convenient, such as in the main method

```dart
void main () {
  DefaultBuildActions.registerDefaultLoadingBuilder((context) {
    return Center(
      child: CupertinoActivityIndicator(),
    );
  });

  DefaultBuildActions.registerDefaultErrorBuilder((context, error) {
    final errorColor = CupertinoColors.systemRed;

    return Center(
      child: Row(children: [
        Icon(CupertinoIcons.xmark_circle, color: errorColor),
        Text(error.toString(), style: TextStyle(color: errorColor)),
      ]),
    );
  });

  runApp(MyApp());
}
```

Then remove the overrides of `buildError` and `buildLoading`, so it can use the default builders.

```dart
class MyWidget extends StatelessWidget with BuildAsyncSnapshot<List<String>> {
  final Future<T> dataSource;

  MyWidget(this.dataSource);

  @override
  Widget build(BuildContext context) {
      // Calling buildFuture is dataSource is Future
      return buildFuture(dataSource);
  }

  @override
  Widget buildValue(BuildContext context, List<String> value) {
    return ListView.builder(
      itemCount: value.length,
      builder: (context, index) => Text(value[index]),
    );
  }
}
```

## `WithEmptyValue` protocol

`MyWidget` above might not work in every case, it would complain if the `Future` returns an `Empty Value`, in example, it is a `empty list`.
And `ListView` can't build empty list, so it complains.

`WithEmptyValue` is the protocol designed to address this particular issue:

```dart
class MyWidget extends StatelessWidget with BuildAsyncSnapshot<List<String>>, WithEmptyValue<List<String>>  {
  final Future<T> dataSource;

  MyWidget(this.dataSource);

  @override
  Widget build(BuildContext context) {
      // Calling buildFuture is dataSource is Future
      return buildFuture(dataSource);
  }

  // Instead of implement buildValue, you should implement buildContent as minimal implementation
  @override
  Widget buildContent(BuildContext context, List<String> value) {
    return ListView.builder(
      itemCount: value.length,
      builder: (context, index) => Text(value[index]),
    );
  }
}
```

There are 2 changes in this example from the one above:

1. Add `WithEmptyValue<List<String>> ` to `MyWidget`.
2. Instead of implement `buildValue` contract, it implements `buildContent` contract, with exactly same implementation.

With this code, when `Future` yield empty list, `MyWidget` just build an empty `Container` instead of `ListView`, so from user's perspective, UI renders "nothing".

## Customize Empty Screen

By Default, `WithEmptyValue` renders an empty `Container` for empty value is received, but it can be customized by override `buildEmpty` contract:

```dart
class MyWidget extends StatelessWidget with BuildAsyncSnapshot<List<String>>, WithEmptyValue<List<String>>  {
  final Future<T> dataSource;

  MyWidget(this.dataSource);

  @override
  Widget build(BuildContext context) {
      // Calling buildFuture is dataSource is Future
      return buildFuture(dataSource);
  }

  // Instead of implement buildValue, you should implement buildContent as minimal implementation
  @override
  Widget buildContent(BuildContext context, List<String> value) {
    return ListView.builder(
      itemCount: value.length,
      builder: (context, index) => Text(value[index]),
    );
  }

  @override
  Widget buildEmpty(BuildContext context, List emptyContent) {
    // Override Empty Screen
    return Center(
      child: Text("Hooray! No more remaining todo for today!"),
    );
  }
}
```

## Handle "empty model"

`WithEmptyValue` understands common data types:

* Anything is `Iterable`
  * Most of the built-in collection types, such as  `List` `Set`  is covered.
  * Majority of the 3rd party collection types should works too, such as the popular `BuiltList` or `KtList`.
* Any kind of `Map`, which might be used to render form or data sheet or so.
* `null` is always considered as `empty` by default

To deal with anything not covered by those 3 rules, an `UnsupportedError` would be thrown. In this case, `checkIsValueEmpty` contract need to be implemented manually to make it work.

For example, `MyTableView` build a table from a `Future<List<List<String>>>`, the row length is fixed to be `5`, but columns  not determined, which can be none.
In this case, the default `checkIsValueEmpty` logic won't work, as there are always `5` rows. Instead of checking the rows, we need to check columns.

```dart
class MyTableView extends StatelessWidget with BuildAsyncSnapshot<List<List<String>>>, WithEmptyValue<List<List<String>>> {
  final Future<List<List<String>>> future;

  const MyTableView({Key key, this.future}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return buildFuture(future);
  }

  // Instead of implement buildValue, you should implement buildContent as minimal implementation
  @override
  Widget buildContent(BuildContext context, List<List<String>> content) {
    return Table(
      children: content.map((r) => _buildRow(r)).toList(growable: false),
    )
  }

  Widget _buildRow(List<String> rowData) {
    return TableRow(
      children: rowData.map((c) => Text(c)).toList(growable: false),
    );
  }

  @override
  bool checkIsValueEmpty(List<List<String>> value) {
    // Every row in table should have same number of columns, so check first row should be enough
    return value.first.isEmpty;
  }
}
```

## "Universal" data builder

This library organised the code with a `protocol/contract/actions` based approach, so it actually enables the code to be flexible but not losing control. Here is a not very useful but interesting example to explain the idea:

This is is a universal widget that can consume a list of screen from:

* `List<String>`:  static data, UI won't update once build
* `ValueListenable`: observable sync data source, UI freshes when data source changed
* `ResultListenable`: observable sync 2-state data source, error view would be shown if result is an error
* `Future`: one-time observable async 3-state data source, a loading screen would be shown before result is ready, then a value view or error view would shown
* `Stream`: on-going observable async 3-state data source, a loading screen would be shown before result is ready, UI would update if new result is sent by remote source
* `Request`: on-going observable async 3-state data source, a loading screen would be shown before result is ready, UI would update by either controlled by remotely or locally.

```dart
class UniversalDataList extends StatelessWidget with BuildAsyncSnapshot<List<String>>, WithEmptyValue<List<String>>  {
  final dynamic dataSource;

  MyWidget(this.dataSource);

  @override
  Widget build(BuildContext context) {
      if(dataSource is ValueListenable<List<String>>) {
        return buildValueListenable(dataSource); // action from `BuildValueListenable`, depends on BuildValue protocol
      } else if(dataSource is ResultListenable<List<String>>) {
        return buildResultListenable(dataSource); // action from `BuildResultListenable`, depends on BuildResult protocol
      } else if(dataSource is Future<List<String>>) {
        return buildFuture(dataSource); // action from `BuildAsyncSnapshotActions, depends on BuildAsyncSnapshot protocol
      } else if(dataSource is Stream<List<String>>) {
        return buildStream(dataSource); // action from `BuildAsyncSnapshotActions, depends on BuildAsyncSnapshot protocol
      } else if(dataSource is Request<List<String>>) {
        return buildRequest(dataSource); // action from `BuildAsyncSnapshotActions, depends on BuildAsyncSnapshot protocol
      } else if(dataSource is List<String>) {
        return buildValue(context, dataSource); // Calling buildValue contract from BuildValue protocol
      } else {
        throw UnsupportedError("Unsupported data source ${dataSource.runtimeType}");
      }
  }

  // Instead of implement buildValue, you should implement buildContent as minimal implementation
  @override
  Widget buildContent(BuildContext context, List<String> value) {
    return ListView.builder(
      itemCount: value.length,
      builder: (context, index) => Text(value[index]),
    );
  }
}
```

## What is `Request` and `ResultListenable`, and what they used for

To better explain wha `Request` and `ResultListable` is, some terminologies should be explained first

### Some concepts

* **Value** - The most common type of `data`, which is a `result` that holds a piece of information can be used to render UI
* **Error** - A special type of `data` which indicates `result` is ready, something went wrong during the process. `Error` is exclusive to `value`.
* **Loading** - A special type of `data` which indicates the `result` is not yet available. It is supposed to be temporary, which eventually replaced by either `value` or an `error`.
* **Result** - A 2-state `data`, which could be either `value` or `error`. `Result` is synchronous `data`.
* **AsyncResult** - A 3-state `data`, which can be `value`, `error`, or `loading`, `AsyncResult` is asynchronous `data`.
* **Data** - The general concept of information used by app.
* **Empty** - A special type of `Value`, which is a legal `value`, but contains no information, such as `[]`of `List<String>`.

### Different type of data sources

With the concepts above, the data sources can be categories as:

* `List<String>`:  The `data` itself, it is static, its value won't change.
* `ValueListenable`: A synchronous observable data source, which provides `value`.
* `ResultListenable`: A synchronous 2-state observable data source, which provides `result`.
* `Future`: A one-time-use asynchronous 3-state observable data source, which provides `async result`
  * `Future`  is `one-time-use` , so `loading` would only appears once, then its value fixed in either a `value` or `error`. Can't changed afterward.
* `Stream`: An on-going asynchronous 3-state observable data source, which provides `async result`.
  * `Stream` is `on-going` data source, whose value could changing across time as many times as it needs to be.
  * `Stream`'s data is typically controlled by remote source, such as a file or remote server.
  * `Stream`'s data can only be accessed by listener in asynchronous way.
  * `Stream` needs to be listened before data is feeding, or previous values are lost.
* `Request`: An on-going asynchronous 3-state observable data source that provides `async result`.
  * `Request` is `on-going` data source, whose value could changing across time as many times as it needs to be.
  * `Request`'s value can be accessible in a synchronous by any one who has its instance.
  * `Request`'s value can be manipulated locally.
  * `Request` can be listened as many times as it needs to be.
  * `Request` can be listened by as many listeners simultaneously as it needs to be.
  * `Request` can be fed with `future`, `async result` yielded by `future` goes into `request`.

### Conclusion

So with this comparison, it is clear that:

>  `Request` is designed to be used as app state manager, while `future` or `stream` is more a low-level data source.

> `ResultListenable` is used to fill the gap in flutter framework, which is being lack of 2-state synchronous data source.

## Loading data from network with `Request`

Using `Request` is much easier than explaining what `Request` is and what is is for.

Here is an example that demonstrates loading some data from a search API:

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

Every request should implement at least `load` method, which is the contract used to specify how the data should be loaded.

## Use `Request` in widget

Build widget with `Request` can be easily done with `BuildAsyncSnapshot` protocol and `buildRequest` action:

```dart
class SearchResultView extends StatelessWidget with BuildAsyncSnapshot<List<SearchItem>>, WithEmptyValue<List<SearchItem>> {
  final MySearchRequest request;

  SearchResultView(this.request);

  @override
  Widget build(BuildContext context) {
    // use method from BuildAsyncSnapshot to render request
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

Besides being used to async result data source, `Request` also provides APIs to do other common tasks, such as re-execute `load` and feed its result to request, aka `retry` when request holds an `error `or `refresh` when request holds a `value`.

## Use `Request` as business logic controller instead of using `StatefulWidget`.

`Request` provides a bunch of API to work with 3-state `async result` with ease, and every changes on its value would notifies UI, eventually have UI updated with contracts defined by `BuildAsyncResult`. So `Request` can be used a logical controller that manages app state, instead of using a `StatefulWidget`.

Using `Request` as business logic controller has a few benefits:

* Decoupling the business logic from UI
* Business logic can be tested independently without UI
* UI can be stateless, which is cheapter to build and easier to maintain.

As `Request` is highly optimized for the scenario dealing with data loading, so in a few particular cases,`Request` could be a much-easier-to-use replacement of other complicated solutions, such as `bloc`, `mobx` or `redux` style `reducer`.

An example to make request do something more than just load:

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
    if (this.hasValue) { // Check whether request holds a value
      // write search result to file if it exists
      await file.writes(currentValue);
    } else if (this.hasError) {
      // writes error to file with writeError method
      await file.writeError(currentError);
    }
    // Skip if request is loading.
  }

  Future loadSearchResult(SearchResultFile file) async {
    Future<List<SearchItem>> Function() loadAction = file.read;

    // Feed a future into request, it updates UI just as the UI is listening to the future.
    await execute(loadAction);
  }

  void clearSearchResult() {
    // update request's data with given value
    putValue([]);
  }

  void trimResult(int limit) {
    // Update request's value based on current value
    // Exception happened during the updating is caught by request and rendered on UI automatically.
    updateValue((current) => current.take(limit).toList());
  }

  Future appendFromFile(SearchResultFile file) {
    // Update request's value based on current value in asynchronous way
    // Exception happened during the updating is caught by request and rendered on UI automatically.
    return updateValueAsync((current) async => current + await file.read());
  }
}
```

## handle 2-state synchronous result with `ResultNotifier`

`ResultNotifier` is a parallel type to `ValueNotifier` but holds 2-state result instead of just value.

2-state result is represented with `Result` from [async](https://pub.dev/packages/async) package

`ResultNotifier` could be useful when dealing with the case that error in data is not fatal.

Here is a simple example:

`FormData` holds a list of string form-field values, which can be either valid or invalid.

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
    // updateValue would only call its callback when it holds value
    fields[fieldName].updateValue((current) => throw current);
  }

  void validField(String fieldName) {
    // Fix error only execute when notifier holds error
    // the returned value is used as value
    // fixError would only call its callback when it holds error
    fields[fieldName].fixError((error) => error);
  }
}
```

## Build widget with `ResultNotifier`/ `ResultListenable`

`ResultListenable` can be consumed with `buildResultListenable` action on any type implemented `BuildResult` protocol:

```dart
class FormFieldView extends StatelessWidget with BuildResult<String> {
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
  Widget buildValue(BuildContext context, String value) {
    return Text(value);
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

**HINT**  `WithEmptyValue`  can be used with`BuildResultListenable` to handle empty content too.

## Consume `ValueListenable` with `BuildValueListenable`

Similar to `BuildResultListenable`, built-in `ValueListenable` can be consumed with `BuildValueListenable` with compatible manner.

**HINT**  `WithEmptyValue`  can be used with`BuildValueListenable` to handle empty content too.

## Implement Undo and Redo with `HistoryValueNotifier`

`HistoryValueNotifier` is an implementation of `ValueListenable<T>` with `undo` and `redo` support built-in.

```dart
// Create a HistoryValueNotifier that remembers past 30 changes
final userInputValue = HistoryValueNotifier<String>(31, initialValue: "");

// Use userInputValue as normal `ValueListenable`
buildValueListener(userInput);

// Undo last change
userInputValue.undo();

// Redo last user change
userInputValue.redo();
```

## License

The MIT License (MIT)
