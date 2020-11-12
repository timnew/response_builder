# Exmaples

## Consume `AsyncResult` from `Future`


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

## Customize Error View / Loading View

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

## Customize Empty Screen

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

## Loading data from network with `Request`

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

## Use `Request` in widget

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

## Use `Request` as business logic controller instead of using `StatefulWidget`.

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

## Implement Undo and Redo with `HistoryValueNotifier`

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
