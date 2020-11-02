import 'package:async/async.dart';

class StreamTester<T> {
  final Stream<T> stream;

  final List<Result<T>> changes = List();

  int get changeCount => changes.length;

  bool get hasChanges => changeCount > 0;

  Result<T> get lastChange => changes.last;

  Result<T> popLastChange() => changes.removeLast();

  void clear() => changes.clear();

  StreamTester(this.stream) {
    stream.listen(onData, onError: onError, cancelOnError: false);
  }

  void onData(T value) {
    changes.add(Result.value(value));
  }

  void onError(Object error, StackTrace stackTrace) {
    changes.add(Result.error(error, stackTrace));
  }

  List<T> changeAsValues() =>
      changes.map((e) => e.asValue.value).toList(growable: false);

  List<String> _formatResults(List<Result<T>> results) => results
      .map((e) => e.isValue ? "V:${e.asValue.value}" : "E:${e.asError.error}")
      .toList(growable: false);

  List<String> formatChanges() => _formatResults(changes);
}
