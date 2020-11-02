import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:response_builder/response_builder.dart';

import '../test_tools/stream_tester.dart';

class TestRequest extends Request<String> {
  final FutureOr<String> Function() createFuture;

  TestRequest({
    FutureOr<String> Function() factory,
    String initialValue,
    bool loadOnListened = true,
    bool initialLoadQuietly: false,
  })  : createFuture = factory ?? (() => Future.value("value")),
        super(
            initialValue: initialValue,
            loadOnListened: loadOnListened,
            initialLoadQuietly: initialLoadQuietly);

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
        final request = TestRequest(loadOnListened: false);

        expect(request.hasResult, isFalse);
        expect(request.isLoading, isFalse);
        expect(request.hasValue, isFalse);
        expect(request.hasError, isFalse);
        expect(request.currentData, isNull);
        expect(request.currentError, isNull);
        expect(() => request.ensuredCurrentData, throwsStateError);
      });

      test("has initial value", () {
        final request = TestRequest(initialValue: value, loadOnListened: false);

        expect(request.hasResult, isTrue);
        expect(request.isLoading, isFalse);
        expect(request.hasValue, isTrue);
        expect(request.hasError, isFalse);
        expect(request.currentData, value);
        expect(request.currentError, isNull);
        expect(request.ensuredCurrentData, value);
      });

      test("holds value", () async {
        final request = TestRequest(loadOnListened: false);

        request.putValue(value);

        expect(request.hasResult, isTrue);
        expect(request.isLoading, isFalse);
        expect(request.hasValue, isTrue);
        expect(request.hasError, isFalse);
        expect(request.currentData, value);
        expect(request.currentError, isNull);
        expect(request.ensuredCurrentData, value);
      });

      test("holds exception", () async {
        final request = TestRequest(loadOnListened: false);

        request.putError(exception, stackTrace);
        expect(request.hasResult, isTrue);
        expect(request.isLoading, isFalse);
        expect(request.hasValue, isFalse);
        expect(request.hasError, isTrue);
        expect(request.currentData, isNull);
        expect(request.currentError, same(exception));
        expect(() => request.ensuredCurrentData, throwsStateError);
      });

      test("holds error", () async {
        final request = TestRequest(loadOnListened: false);

        request.putError(error, stackTrace);
        expect(request.hasResult, isTrue);
        expect(request.isLoading, isFalse);
        expect(request.hasValue, isFalse);
        expect(request.hasError, isTrue);
        expect(request.currentData, isNull);
        expect(request.currentError, same(error));
        expect(() => request.ensuredCurrentData, throwsStateError);
      });

      test("holds waiting", () async {
        final request = TestRequest(loadOnListened: false);

        request.markAsWaiting();

        expect(request.hasResult, isFalse);
        expect(request.isLoading, isTrue);
        expect(request.hasValue, isFalse);
        expect(request.hasError, isFalse);
        expect(request.currentData, isNull);
        expect(request.currentError, isNull);
        expect(() => request.ensuredCurrentData, throwsStateError);
      });
    });

    group("load", () {
      test("load synchronously", () async {
        final request = TestRequest(factory: () => value);

        expect(request.hasResult, isFalse);
        expect(request.isLoading, isFalse);

        // Listen to stream
        StreamTester(request.resultStream);

        expect(request.hasResult, isFalse);
        expect(request.isLoading, isTrue);

        await breath();

        expect(request.hasValue, isTrue);
        expect(request.hasError, isFalse);
        expect(request.isLoading, isFalse);
        expect(request.ensuredCurrentData, value);
      });

      test("load synchronously with exception", () async {
        final request = TestRequest(factory: () => throw exception);

        expect(request.hasResult, isFalse);
        expect(request.isLoading, isFalse);

        // Listen to stream
        StreamTester(request.resultStream);

        await breath();

        expect(request.hasValue, isFalse);
        expect(request.hasError, isTrue);
        expect(request.isLoading, isFalse);
        expect(request.currentError, same(exception));
      });

      test(
        "load synchronously with exception",
        () async {
          final request = TestRequest(factory: () => throw error);

          expect(request.hasResult, isFalse);
          expect(request.isLoading, isFalse);

          // Listen to stream
          StreamTester(request.resultStream);

          expect(request.hasResult, isFalse);
          expect(request.isLoading, isTrue);

          await breath();

          expect(request.hasValue, isFalse);
          expect(request.hasError, isTrue);
          expect(request.isLoading, isFalse);
          expect(request.currentError, same(error));
        },
        skip: true, // error is thrown on calling side
      );

      test("load asynchronously", () async {
        Completer<String> completer;

        final request = TestRequest(factory: () {
          completer = Completer();
          return completer.future;
        });

        expect(request.hasResult, isFalse);
        expect(request.isLoading, isFalse);

        // Listen to stream
        StreamTester(request.resultStream);

        expect(request.hasResult, isFalse);
        expect(request.isLoading, isTrue);

        completer.complete(value);
        await breath();

        expect(request.hasValue, isTrue);
        expect(request.hasError, isFalse);
        expect(request.isLoading, isFalse);
        expect(request.ensuredCurrentData, value);
      });

      test("load asynchronously with exception", () async {
        Completer<String> completer;

        final request = TestRequest(factory: () {
          completer = Completer();
          return completer.future;
        });

        expect(request.hasResult, isFalse);
        expect(request.isLoading, isFalse);

        // Listen to stream
        StreamTester(request.resultStream);

        expect(request.hasResult, isFalse);
        expect(request.isLoading, isTrue);

        completer.completeError(exception);
        await breath();

        expect(request.hasValue, isFalse);
        expect(request.hasError, isTrue);
        expect(request.isLoading, isFalse);
        expect(request.currentError, same(exception));
      });

      test(
        "load asynchronously with error",
        () async {
          final request = TestRequest(factory: () => Future.error(error));

          expect(request.hasResult, isFalse);
          expect(request.isLoading, isFalse);

          // Listen to stream
          StreamTester(request.resultStream);

          expect(request.hasResult, isFalse);
          expect(request.isLoading, isTrue);

          await breath();

          expect(request.hasValue, isFalse);
          expect(request.hasError, isTrue);
          expect(request.isLoading, isFalse);
          expect(request.currentError, same(error));
        },
        skip: true, // error is thrown on calling side
      );

      test("do not load on listen", () async {
        final request = TestRequest(
            factory: () => Future.value(newValue),
            initialValue: value,
            loadOnListened: false);

        expect(request.isLoading, isFalse);
        expect(request.ensuredCurrentData, value);

        // Listen to stream
        StreamTester(request.resultStream);

        await breath();

        expect(request.isLoading, isFalse);
        expect(request.ensuredCurrentData, value);
      });

      test("load quietly", () async {
        Completer<String> completer;

        final request = TestRequest(
          factory: () {
            completer = Completer();
            return completer.future;
          },
          initialValue: value,
          initialLoadQuietly: true,
        );

        expect(request.isLoading, isFalse);
        expect(request.ensuredCurrentData, value);

        // Listen to stream
        StreamTester(request.resultStream);

        await breath();

        expect(request.isLoading, isFalse);
        expect(request.ensuredCurrentData, value);

        completer.complete(newValue);
        await breath();

        expect(request.isLoading, isFalse);
        expect(request.ensuredCurrentData, newValue);
      });
    });

    group("reload", () {
      test("reload a value", () async {
        Completer<String> completer;

        final request = TestRequest(factory: () {
          completer = Completer();
          return completer.future;
        });
        StreamTester(request.resultStream);
        completer.complete(value);
        await breath();

        expect(request.hasValue, isTrue);
        expect(request.hasError, isFalse);
        expect(request.isLoading, isFalse);
        expect(request.ensuredCurrentData, value);

        request.reload();
        await breath();

        expect(request.hasResult, isFalse);
        expect(request.isLoading, isTrue);

        completer.complete(newValue);
        await breath();

        expect(request.hasValue, isTrue);
        expect(request.hasError, isFalse);
        expect(request.isLoading, isFalse);
        expect(request.ensuredCurrentData, newValue);
      });

      test("reload a with an exception", () async {
        Completer<String> completer;

        final request = TestRequest(factory: () {
          completer = Completer();
          return completer.future;
        });
        StreamTester(request.resultStream);
        completer.complete(value);
        await breath();

        expect(request.hasValue, isTrue);
        expect(request.hasError, isFalse);
        expect(request.isLoading, isFalse);
        expect(request.ensuredCurrentData, value);

        request.reload();
        await breath();

        expect(request.hasResult, isFalse);
        expect(request.isLoading, isTrue);

        completer.completeError(exception);
        await breath();

        expect(request.hasValue, isFalse);
        expect(request.hasError, isTrue);
        expect(request.isLoading, isFalse);
        expect(request.currentError, same(exception));
      });

      test(
        "reload a with an error",
        () async {
          Completer<String> completer;

          final request = TestRequest(factory: () {
            completer = Completer();
            return completer.future;
          });
          StreamTester(request.resultStream);
          completer.complete(value);
          await breath();

          expect(request.hasValue, isTrue);
          expect(request.hasError, isFalse);
          expect(request.isLoading, isFalse);
          expect(request.ensuredCurrentData, value);

          final reloadFuture = request.reload();
          await breath();

          expect(request.hasResult, isFalse);
          expect(request.isLoading, isTrue);

          completer.completeError(error);
          await breath();

          expect(reloadFuture, throwsA(same(error)));

          expect(request.hasValue, isFalse);
          expect(request.hasError, isTrue);
          expect(request.isLoading, isFalse);
          expect(request.currentError, same(error));
        },
        skip: true, // Exception is not captured by framework
      );

      test("reload quietly", () async {
        Completer<String> completer;

        final request = TestRequest(factory: () {
          completer = Completer();
          return completer.future;
        });
        StreamTester(request.resultStream);
        completer.complete(value);
        await breath();

        expect(request.hasValue, isTrue);
        expect(request.hasError, isFalse);
        expect(request.isLoading, isFalse);
        expect(request.ensuredCurrentData, value);

        request.reload(quiet: true);
        await breath();

        expect(request.hasValue, isTrue);
        expect(request.hasError, isFalse);
        expect(request.isLoading, isFalse);
        expect(request.ensuredCurrentData, value);

        completer.complete(newValue);
        await breath();

        expect(request.hasValue, isTrue);
        expect(request.hasError, isFalse);
        expect(request.isLoading, isFalse);
        expect(request.ensuredCurrentData, newValue);
      });
    });

    group("update", () {
      test("update with value", () async {
        final request = TestRequest();
        StreamTester(request.resultStream);
        await breath();

        expect(request.hasValue, isTrue);
        expect(request.hasError, isFalse);
        expect(request.isLoading, isFalse);
        expect(request.ensuredCurrentData, value);

        request.update(newValue);
        await breath();

        expect(request.hasValue, isTrue);
        expect(request.hasError, isFalse);
        expect(request.isLoading, isFalse);
        expect(request.ensuredCurrentData, newValue);
      });

      test("update with future", () async {
        final request = TestRequest();
        StreamTester(request.resultStream);
        await breath();

        expect(request.hasValue, isTrue);
        expect(request.hasError, isFalse);
        expect(request.isLoading, isFalse);
        expect(request.ensuredCurrentData, value);

        final completer = Completer<String>();

        request.update(completer.future);
        await breath();

        expect(request.hasResult, isFalse);
        expect(request.isLoading, isTrue);

        completer.complete(newValue);
        await breath();

        expect(request.hasValue, isTrue);
        expect(request.hasError, isFalse);
        expect(request.isLoading, isFalse);
        expect(request.ensuredCurrentData, newValue);
      });

      test("update with failed future", () async {
        final request = TestRequest();
        StreamTester(request.resultStream);
        await breath();

        expect(request.hasValue, isTrue);
        expect(request.hasError, isFalse);
        expect(request.isLoading, isFalse);
        expect(request.ensuredCurrentData, value);

        final completer = Completer<String>();

        request.update(completer.future);
        await breath();

        expect(request.hasResult, isFalse);
        expect(request.isLoading, isTrue);

        completer.completeError(exception);
        await breath();

        expect(request.hasValue, isFalse);
        expect(request.hasError, isTrue);
        expect(request.isLoading, isFalse);
        expect(request.currentError, same(exception));
      });

      test("error should be rethrown", () async {
        final request = TestRequest();
        StreamTester(request.resultStream);
        await breath();

        expect(request.hasValue, isTrue);
        expect(request.hasError, isFalse);
        expect(request.isLoading, isFalse);
        expect(request.ensuredCurrentData, value);

        expect(request.update(Future.error(error)), throwsA(same(error)));

        await breath();

        expect(request.hasValue, isFalse);
        expect(request.hasError, isTrue);
        expect(request.isLoading, isFalse);
        expect(request.currentError, same(error));
      });

      test("update with future quietly", () async {
        final request = TestRequest();
        StreamTester(request.resultStream);
        await breath();

        expect(request.hasValue, isTrue);
        expect(request.hasError, isFalse);
        expect(request.isLoading, isFalse);
        expect(request.ensuredCurrentData, value);

        final completer = Completer<String>();

        request.update(completer.future, quiet: true);
        await breath();

        expect(request.hasValue, isTrue);
        expect(request.hasError, isFalse);
        expect(request.isLoading, isFalse);
        expect(request.ensuredCurrentData, value);

        completer.complete(newValue);
        await breath();

        expect(request.hasValue, isTrue);
        expect(request.hasError, isFalse);
        expect(request.isLoading, isFalse);
        expect(request.ensuredCurrentData, newValue);
      });
    });

    group("execute", () {
      test("execute sync action", () async {
        final request = TestRequest();
        StreamTester(request.resultStream);
        await breath();

        expect(request.hasValue, isTrue);
        expect(request.hasError, isFalse);
        expect(request.isLoading, isFalse);
        expect(request.ensuredCurrentData, value);

        request.execute(() => newValue);
        await breath();

        expect(request.hasValue, isTrue);
        expect(request.hasError, isFalse);
        expect(request.isLoading, isFalse);
        expect(request.ensuredCurrentData, newValue);
      });

      test("sync action throws exception", () async {
        final request = TestRequest();
        StreamTester(request.resultStream);
        await breath();

        expect(request.hasValue, isTrue);
        expect(request.hasError, isFalse);
        expect(request.isLoading, isFalse);
        expect(request.ensuredCurrentData, value);

        request.execute(() => throw exception);
        await breath();

        expect(request.hasValue, isFalse);
        expect(request.hasError, isTrue);
        expect(request.isLoading, isFalse);
        expect(request.currentError, same(exception));
      });

      test("sync action throws error", () async {
        final request = TestRequest();
        StreamTester(request.resultStream);
        await breath();

        expect(request.hasValue, isTrue);
        expect(request.hasError, isFalse);
        expect(request.isLoading, isFalse);
        expect(request.ensuredCurrentData, value);

        expect(
          () async {
            await request.execute(() => throw error);
          },
          throwsA(same(error)),
        );

        await breath();

        expect(request.hasValue, isFalse);
        expect(request.hasError, isTrue);
        expect(request.isLoading, isFalse);
        expect(request.currentError, same(error));
      });

      test("update async action", () async {
        final request = TestRequest();
        StreamTester(request.resultStream);
        await breath();

        expect(request.hasValue, isTrue);
        expect(request.hasError, isFalse);
        expect(request.isLoading, isFalse);
        expect(request.ensuredCurrentData, value);

        final completer = Completer<String>();

        request.execute(() => completer.future);
        await breath();

        expect(request.hasResult, isFalse);
        expect(request.isLoading, isTrue);

        completer.complete(newValue);
        await breath();

        expect(request.hasValue, isTrue);
        expect(request.hasError, isFalse);
        expect(request.isLoading, isFalse);
        expect(request.ensuredCurrentData, newValue);
      });

      test("async action yields exception", () async {
        final request = TestRequest();
        StreamTester(request.resultStream);
        await breath();

        expect(request.hasValue, isTrue);
        expect(request.hasError, isFalse);
        expect(request.isLoading, isFalse);
        expect(request.ensuredCurrentData, value);

        final completer = Completer<String>();

        request.execute(() => completer.future);
        await breath();

        expect(request.hasResult, isFalse);
        expect(request.isLoading, isTrue);

        completer.completeError(exception);
        await breath();

        expect(request.hasValue, isFalse);
        expect(request.hasError, isTrue);
        expect(request.isLoading, isFalse);
        expect(request.currentError, same(exception));
      });

      test("async action yields error", () async {
        final request = TestRequest();
        StreamTester(request.resultStream);
        await breath();

        expect(request.hasValue, isTrue);
        expect(request.hasError, isFalse);
        expect(request.isLoading, isFalse);
        expect(request.ensuredCurrentData, value);

        expect(
          () async {
            await request.execute(() => Future.error(error));
          },
          throwsA(same(error)),
        );

        await breath();

        expect(request.hasValue, isFalse);
        expect(request.hasError, isTrue);
        expect(request.isLoading, isFalse);
        expect(request.currentError, same(error));
      });

      test("execute quietly", () async {
        final request = TestRequest();
        StreamTester(request.resultStream);
        await breath();

        expect(request.hasValue, isTrue);
        expect(request.hasError, isFalse);
        expect(request.isLoading, isFalse);
        expect(request.ensuredCurrentData, value);

        final completer = Completer<String>();

        request.execute(() => completer.future, quiet: true);
        await breath();

        expect(request.hasValue, isTrue);
        expect(request.hasError, isFalse);
        expect(request.isLoading, isFalse);
        expect(request.ensuredCurrentData, value);

        completer.complete(newValue);
        await breath();

        expect(request.hasValue, isTrue);
        expect(request.hasError, isFalse);
        expect(request.isLoading, isFalse);
        expect(request.ensuredCurrentData, newValue);
      });
    });

    group("first value", () {
      test("fetch initial value", () async {
        final request = TestRequest(initialValue: value, loadOnListened: false);
        final future = request.firstResult;

        expect(await future, value);
      });

      test("fetch first value", () async {
        final request = TestRequest(loadOnListened: false);
        final future = request.firstResult;

        request.putValue(value);

        expect(await future, value);
      });

      test("fetch only first value", () async {
        final request = TestRequest(loadOnListened: false);
        final future = request.firstResult;

        request.putValue(value);
        request.putValue(newValue);

        expect(await future, value);
      });

      test("ignore waiting", () async {
        final request = TestRequest(loadOnListened: false);
        final future = request.firstResult;

        request.markAsWaiting();
        request.putValue(value);

        expect(await future, value);
      });

      test("catch error", () async {
        final request = TestRequest(loadOnListened: false);
        final future = request.firstResult;

        request.putError(exception);

        expect(future, throwsException);
      });

      test("ignore waiting before  error", () async {
        final request = TestRequest(loadOnListened: false);
        final future = request.firstResult;

        request.markAsWaiting();
        request.putError(exception);

        expect(future, throwsException);
      });
    });

    group("updateValue", () {
      test("should update value", () {
        final request = TestRequest(initialValue: value, loadOnListened: false);

        expect(request.ensuredCurrentData, value);

        request.updateValue((current) => "updated $current");

        expect(request.ensuredCurrentData, "updated $value");
      });

      test("should catch exception", () {
        final request = TestRequest(initialValue: value, loadOnListened: false);

        expect(request.ensuredCurrentData, value);

        request.updateValue((current) => throw exception);

        expect(request.isLoading, isFalse);
        expect(request.hasValue, isFalse);
        expect(request.hasError, isTrue);

        expect(request.currentError, same(exception));
      });

      test("should rethrow error", () {
        final request = TestRequest(initialValue: value, loadOnListened: false);

        expect(request.ensuredCurrentData, value);

        expect(() => request.updateValue((current) => throw error),
            throwsA(same(error)));
      });

      test("should throws when updates on exception", () {
        final request = TestRequest(loadOnListened: false);

        request.putError(exception);

        expect(() => request.updateValue((current) => "updated $current"),
            throwsStateError);
      });

      test("should throws when updates on waiting", () {
        final request = TestRequest(initialValue: value, loadOnListened: false);

        request.markAsWaiting();

        expect(() => request.updateValue((current) => "updated $current"),
            throwsStateError);
      });
    });

    group("updateValueAsync", () {
      test("should update value", () async {
        final request = TestRequest(initialValue: value, loadOnListened: false);

        expect(request.ensuredCurrentData, value);

        final completer = Completer();

        request.updateValueAsync((current) async {
          await completer.future;
          return "updated $current";
        });

        expect(request.isLoading, isTrue);

        completer.complete();
        await breath();

        expect(request.ensuredCurrentData, "updated $value");
      });

      test("should update value quietly", () async {
        final request = TestRequest(initialValue: value, loadOnListened: false);

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
        final request = TestRequest(initialValue: value, loadOnListened: false);

        expect(request.ensuredCurrentData, value);

        request.updateValueAsync((current) => Future.error(exception));
        await breath();

        expect(request.isLoading, isFalse);
        expect(request.hasValue, isFalse);
        expect(request.hasError, isTrue);

        expect(request.currentError, same(exception));
      });

      test("should rethrow error", () {
        final request = TestRequest(initialValue: value, loadOnListened: false);

        expect(request.ensuredCurrentData, value);

        expect(
          () async => await request.updateValueAsync(
            (current) => Future.error(error),
          ),
          throwsA(same(error)),
        );
      });

      test("should throws when updates on exception", () {
        final request = TestRequest(loadOnListened: false);

        request.putError(exception);

        expect(
          () async => await request.updateValueAsync(
            (current) => Future.value("updated $current"),
          ),
          throwsStateError,
        );
      });

      test("should throws when updates on waiting", () {
        final request = TestRequest(initialValue: value, loadOnListened: false);

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
          loadOnListened: false,
        );
        final tester = StreamTester(request.resultStream);

        await breath();

        expect(tester.formatChanges(), ["V:$value"]);
      });

      test("result should go to stream", () async {
        final request = TestRequest();
        final tester = StreamTester(request.resultStream);

        await waitStream();

        expect(tester.formatChanges(), ["V:null", "V:$value"]);
      });

      test("reload should publish to stream", () async {
        var count = 0;
        final request = TestRequest(factory: () => Future.value("${++count}"));
        final tester = StreamTester(request.resultStream);

        await waitStream();

        await request.reload();

        await waitStream();

        expect(tester.formatChanges(), ["V:null", "V:1", "V:null", "V:2"]);
      });

      test("execute should publish to stream", () async {
        final request = TestRequest();
        final tester = StreamTester(request.resultStream);

        await waitStream();

        await request.update(Future.value(newValue));

        await waitStream();

        expect(tester.formatChanges(),
            ["V:null", "V:$value", "V:null", "V:$newValue"]);
      });

      test("execute should publish exception to stream", () async {
        final request = TestRequest();
        final tester = StreamTester(request.resultStream);

        await waitStream();

        await request.update(Future.error(exception));

        await waitStream();

        expect(tester.formatChanges(),
            ["V:null", "V:$value", "V:null", "E:$exception"]);
      });

      test("putValue should publish to stream", () async {
        final request = TestRequest();
        final tester = StreamTester(request.resultStream);

        await waitStream();

        request.putValue(newValue);

        await waitStream();

        expect(tester.formatChanges(), ["V:null", "V:$value", "V:$newValue"]);
      });

      test("putError should publish to stream", () async {
        final request = TestRequest();
        final tester = StreamTester(request.resultStream);

        await waitStream();

        request.putError(exception);

        await waitStream();

        expect(tester.formatChanges(), ["V:null", "V:$value", "E:$exception"]);
      });
    });
  });
}
