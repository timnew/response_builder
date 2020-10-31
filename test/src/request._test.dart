import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:response_builder/response_builder.dart';

import '../test_tools/stream_tester.dart';

class TestRequest extends Request<String> {
  final Future<String> Function() createFuture;

  TestRequest({Future<String> Function() factory, String initialValue, bool executeOnFirstListen = true})
      : createFuture = factory ?? (() => Future.value("value")),
        super(initialValue: initialValue, executeOnFirstListen: initialValue == null && executeOnFirstListen);

  FutureOr<String> load() => createFuture();
}

Future breath() async {}

Future waitStream() async {
  await Future.delayed(Duration(microseconds: 1));
}

void main() {
  final value = "value";
  final newValue = "new value";

  final exception = Exception("exception");
  final error = ArgumentError("error");
  final stackTrace = StackTrace.current;

  group("request", () {
    group("status properties", () {
      test("has no value", () {
        final request = TestRequest(executeOnFirstListen: false);

        expect(request.hasCurrent, isFalse);
        expect(request.isWaiting, isFalse);
        expect(request.hasData, isFalse);
        expect(request.hasError, isFalse);
        expect(request.currentData, isNull);
        expect(request.currentError, isNull);
        expect(() => request.ensuredCurrentData, throwsStateError);
      });

      test("has initial value", () {
        final request = TestRequest(initialValue: value, executeOnFirstListen: false);

        expect(request.hasCurrent, isTrue);
        expect(request.isWaiting, isFalse);
        expect(request.hasData, isTrue);
        expect(request.hasError, isFalse);
        expect(request.currentData, value);
        expect(request.currentError, isNull);
        expect(request.ensuredCurrentData, value);
      });

      test("holds value", () async {
        final request = TestRequest(executeOnFirstListen: false);

        request.putValue(value);

        expect(request.hasCurrent, isTrue);
        expect(request.isWaiting, isFalse);
        expect(request.hasData, isTrue);
        expect(request.hasError, isFalse);
        expect(request.currentData, value);
        expect(request.currentError, isNull);
        expect(request.ensuredCurrentData, value);
      });

      test("holds exception", () async {
        final request = TestRequest(executeOnFirstListen: false);

        request.putError(exception, stackTrace);
        expect(request.hasCurrent, isTrue);
        expect(request.isWaiting, isFalse);
        expect(request.hasData, isFalse);
        expect(request.hasError, isTrue);
        expect(request.currentData, isNull);
        expect(request.currentError, same(exception));
        expect(() => request.ensuredCurrentData, throwsStateError);
      });

      test("holds error", () async {
        final request = TestRequest(executeOnFirstListen: false);

        request.putError(error, stackTrace);
        expect(request.hasCurrent, isTrue);
        expect(request.isWaiting, isFalse);
        expect(request.hasData, isFalse);
        expect(request.hasError, isTrue);
        expect(request.currentData, isNull);
        expect(request.currentError, same(error));
        expect(() => request.ensuredCurrentData, throwsStateError);
      });

      test("holds waiting", () async {
        final request = TestRequest(executeOnFirstListen: false);

        request.markAsWaiting();

        expect(request.hasCurrent, isFalse);
        expect(request.isWaiting, isTrue);
        expect(request.hasData, isFalse);
        expect(request.hasError, isFalse);
        expect(request.currentData, isNull);
        expect(request.currentError, isNull);
        expect(() => request.ensuredCurrentData, throwsStateError);
      });
    });

    group("load and reload", () {
      test("load", () async {
        Completer<String> completer;

        final request = TestRequest(factory: () {
          completer = Completer();
          return completer.future;
        });

        expect(request.hasCurrent, isFalse);
        expect(request.isWaiting, isFalse);

        // Listen to stream
        StreamTester(request.valueStream);

        expect(request.hasCurrent, isFalse);
        expect(request.isWaiting, isTrue);

        completer.complete(value);
        await breath();

        expect(request.hasData, isTrue);
        expect(request.hasError, isFalse);
        expect(request.isWaiting, isFalse);
        expect(request.ensuredCurrentData, value);
      });

      test("reload", () async {
        Completer<String> completer;

        final request = TestRequest(factory: () {
          completer = Completer();
          return completer.future;
        });
        StreamTester(request.valueStream);
        completer.complete(value);
        await breath();

        expect(request.hasData, isTrue);
        expect(request.hasError, isFalse);
        expect(request.isWaiting, isFalse);
        expect(request.ensuredCurrentData, value);

        request.reload();
        await breath();

        expect(request.hasCurrent, isFalse);
        expect(request.isWaiting, isTrue);

        completer.complete(newValue);
        await breath();

        expect(request.hasData, isTrue);
        expect(request.hasError, isFalse);
        expect(request.isWaiting, isFalse);
        expect(request.ensuredCurrentData, newValue);
      });

      test("reload quietly", () async {
        Completer<String> completer;

        final request = TestRequest(factory: () {
          completer = Completer();
          return completer.future;
        });
        StreamTester(request.valueStream);
        completer.complete(value);
        await breath();

        expect(request.hasData, isTrue);
        expect(request.hasError, isFalse);
        expect(request.isWaiting, isFalse);
        expect(request.ensuredCurrentData, value);

        request.reload(quiet: true);
        await breath();

        expect(request.hasData, isTrue);
        expect(request.hasError, isFalse);
        expect(request.isWaiting, isFalse);
        expect(request.ensuredCurrentData, value);

        completer.complete(newValue);
        await breath();

        expect(request.hasData, isTrue);
        expect(request.hasError, isFalse);
        expect(request.isWaiting, isFalse);
        expect(request.ensuredCurrentData, newValue);
      });
    });

    group("execute", () {
      test("execute", () async {
        final request = TestRequest();
        StreamTester(request.valueStream);
        await breath();

        expect(request.hasData, isTrue);
        expect(request.hasError, isFalse);
        expect(request.isWaiting, isFalse);
        expect(request.ensuredCurrentData, value);

        final completer = Completer<String>();

        request.execute(completer.future);
        await breath();

        expect(request.hasCurrent, isFalse);
        expect(request.isWaiting, isTrue);

        completer.complete(newValue);
        await breath();

        expect(request.hasData, isTrue);
        expect(request.hasError, isFalse);
        expect(request.isWaiting, isFalse);
        expect(request.ensuredCurrentData, newValue);
      });

      test("execute quietly", () async {
        final request = TestRequest();
        StreamTester(request.valueStream);
        await breath();

        expect(request.hasData, isTrue);
        expect(request.hasError, isFalse);
        expect(request.isWaiting, isFalse);
        expect(request.ensuredCurrentData, value);

        final completer = Completer<String>();

        request.execute(completer.future, quiet: true);
        await breath();

        expect(request.hasData, isTrue);
        expect(request.hasError, isFalse);
        expect(request.isWaiting, isFalse);
        expect(request.ensuredCurrentData, value);

        completer.complete(newValue);
        await breath();

        expect(request.hasData, isTrue);
        expect(request.hasError, isFalse);
        expect(request.isWaiting, isFalse);
        expect(request.ensuredCurrentData, newValue);
      });
    });

    group("first value", () {
      test("fetch initial value", () async {
        final request = TestRequest(initialValue: value, executeOnFirstListen: false);
        final future = request.firstValue;

        expect(await future, value);
      });

      test("fetch first value", () async {
        final request = TestRequest(executeOnFirstListen: false);
        final future = request.firstValue;

        request.putValue(value);

        expect(await future, value);
      });

      test("fetch only first value", () async {
        final request = TestRequest(executeOnFirstListen: false);
        final future = request.firstValue;

        request.putValue(value);
        request.putValue(newValue);

        expect(await future, value);
      });

      test("ignore waiting", () async {
        final request = TestRequest(executeOnFirstListen: false);
        final future = request.firstValue;

        request.markAsWaiting();
        request.putValue(value);

        expect(await future, value);
      });

      test("catch error", () async {
        final request = TestRequest(executeOnFirstListen: false);
        final future = request.firstValue;

        request.putError(exception);

        expect(() async => await future, throwsException);
      });

      test("ignore waiting before  error", () async {
        final request = TestRequest(executeOnFirstListen: false);
        final future = request.firstValue;

        request.markAsWaiting();
        request.putError(exception);

        expect(() async => await future, throwsException);
      });
    });

    group("updateValue", () {
      test("should update value", () {
        final request = TestRequest(initialValue: value, executeOnFirstListen: false);

        expect(request.ensuredCurrentData, value);

        request.updateValue((current) => "updated $current");

        expect(request.ensuredCurrentData, "updated $value");
      });

      test("should catch exception", () {
        final request = TestRequest(initialValue: value, executeOnFirstListen: false);

        expect(request.ensuredCurrentData, value);

        request.updateValue((current) => throw exception);

        expect(request.isWaiting, isFalse);
        expect(request.hasData, isFalse);
        expect(request.hasError, isTrue);

        expect(request.currentError, same(exception));
      });

      test("should rethrow error", () {
        final request = TestRequest(initialValue: value, executeOnFirstListen: false);

        expect(request.ensuredCurrentData, value);

        expect(() => request.updateValue((current) => throw error), throwsA(same(error)));
      });

      test("should throws when updates on exception", () {
        final request = TestRequest(executeOnFirstListen: false);

        request.putError(exception);

        expect(() => request.updateValue((current) => "updated $current"), throwsStateError);
      });

      test("should throws when updates on waiting", () {
        final request = TestRequest(initialValue: value, executeOnFirstListen: false);

        request.markAsWaiting();

        expect(() => request.updateValue((current) => "updated $current"), throwsStateError);
      });
    });

    group("updateValueAsync", () {
      test("should update value", () async {
        final request = TestRequest(initialValue: value, executeOnFirstListen: false);

        expect(request.ensuredCurrentData, value);

        final completer = Completer();

        request.updateValueAsync((current) async {
          await completer.future;
          return "updated $current";
        });

        expect(request.isWaiting, isTrue);

        completer.complete();
        await breath();

        expect(request.ensuredCurrentData, "updated $value");
      });

      test("should update value quietly", () async {
        final request = TestRequest(initialValue: value, executeOnFirstListen: false);

        expect(request.ensuredCurrentData, value);

        final completer = Completer();

        request.updateValueAsync((current) async {
          await completer.future;
          return "updated $current";
        }, quiet: true);

        expect(request.ensuredCurrentData, value);

        completer.complete();
        await breath();

        expect(request.ensuredCurrentData, "updated $value");
      });

      test("should catch exception", () async {
        final request = TestRequest(initialValue: value, executeOnFirstListen: false);

        expect(request.ensuredCurrentData, value);

        request.updateValueAsync((current) => Future.error(exception));
        await breath();

        expect(request.isWaiting, isFalse);
        expect(request.hasData, isFalse);
        expect(request.hasError, isTrue);

        expect(request.currentError, same(exception));
      });

      test("should rethrow error", () {
        final request = TestRequest(initialValue: value, executeOnFirstListen: false);

        expect(request.ensuredCurrentData, value);

        expect(
          () async => await request.updateValueAsync(
            (current) => Future.error(error),
          ),
          throwsA(same(error)),
        );
      });

      test("should throws when updates on exception", () {
        final request = TestRequest(executeOnFirstListen: false);

        request.putError(exception);

        expect(
          () async => await request.updateValueAsync(
            (current) => Future.value("updated $current"),
          ),
          throwsStateError,
        );
      });

      test("should throws when updates on waiting", () {
        final request = TestRequest(initialValue: value, executeOnFirstListen: false);

        request.markAsWaiting();

        expect(
          () async => await request.updateValueAsync(
            (current) => Future.value("updated $current"),
          ),
          throwsStateError,
        );
      });
    });

    group("publish to stream", () {
      test("initial value should go to stream", () async {
        final request = TestRequest(
          initialValue: value,
        );
        final tester = StreamTester(request.valueStream);

        await breath();

        expect(tester.formatChanges(), ["V:$value"]);
      });

      test("result should go to stream", () async {
        final request = TestRequest();
        final tester = StreamTester(request.valueStream);

        await waitStream();

        expect(tester.formatChanges(), ["V:null", "V:$value"]);
      });

      test("reload should publish to stream", () async {
        var count = 0;
        final request = TestRequest(factory: () => Future.value("${++count}"));
        final tester = StreamTester(request.valueStream);

        await waitStream();

        await request.reload();

        await waitStream();

        expect(tester.formatChanges(), ["V:null", "V:1", "V:null", "V:2"]);
      });

      test("execute should publish to stream", () async {
        final request = TestRequest();
        final tester = StreamTester(request.valueStream);

        await waitStream();

        await request.execute(Future.value(newValue));

        await waitStream();

        expect(tester.formatChanges(), ["V:null", "V:$value", "V:null", "V:$newValue"]);
      });

      test("execute should publish exception to stream", () async {
        final request = TestRequest();
        final tester = StreamTester(request.valueStream);

        await waitStream();

        await request.execute(Future.error(exception));

        await waitStream();

        expect(tester.formatChanges(), ["V:null", "V:$value", "V:null", "E:$exception"]);
      });

      test("putValue should publish to stream", () async {
        final request = TestRequest();
        final tester = StreamTester(request.valueStream);

        await waitStream();

        request.putValue(newValue);

        await waitStream();

        expect(tester.formatChanges(), ["V:null", "V:$value", "V:$newValue"]);
      });

      test("putError should publish to stream", () async {
        final request = TestRequest();
        final tester = StreamTester(request.valueStream);

        await waitStream();

        request.putError(exception);

        await waitStream();

        expect(tester.formatChanges(), ["V:null", "V:$value", "E:$exception"]);
      });
    });
  });
}
