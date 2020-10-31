import 'package:flutter_test/flutter_test.dart';
import 'package:async/async.dart';

import 'package:response_builder/response_builder.dart';

import '../test_tools/listenable_tester.dart';

void main() {
  final value = "value";
  final error = "error";
  final stackTrace = StackTrace.empty;

  group("ResultStore", () {
    test("get value", () {
      final store = ResultStore<String>(value);

      expect(store.hasValue, isTrue);
      expect(store.value, equals(value));

      expect(store.hasError, isFalse);
      expect(() => store.error, throwsStateError);
      expect(() => store.stackTrace, throwsStateError);

      expect(store.result, isA<ValueResult<String>>());
      expect(store.result.asValue.value, equals(value));
    });

    test("get error", () {
      final store = ResultStore<String>.error(error, stackTrace);

      expect(store.hasValue, isFalse);
      expect(() => store.value, throwsStateError);

      expect(store.hasError, isTrue);
      expect(store.error, equals(error));
      expect(store.stackTrace, equals(stackTrace));

      expect(store.result, isA<ErrorResult>());
      expect(store.result.asError.error, equals(error));
      expect(store.result.asError.stackTrace, equals(stackTrace));
    });

    test("receive change notification", () {
      final store = ResultStore<String>("initial");
      final tester = ValueListenableTester(store.listenable);

      expect(tester.changeCount, 0);

      store.putValue(value);

      expect(tester.changeCount, 1);
      expect(tester.popLastChange().asValue.value, value);

      store.putError(error, stackTrace);
      expect(tester.lastChange.asError.error, error);
      expect(tester.popLastChange().asError.stackTrace, stackTrace);
    });

    test("update value", () {
      final store = ResultStore<String>(value);
      final tester = ValueListenableTester(store.listenable);

      final updateResult = store.updateValue((current) => "new $current");
      expect(tester.changeCount, 1);
      expect(updateResult, "new value");
      expect(tester.lastChange.asValue.value, "new value");

      store.putError(error);
      expect(tester.changeCount, 2);

      final ignoredResult = store.updateValue((current) => "new $current");
      expect(tester.changeCount, 2);
      expect(ignoredResult, isNull);
    });

    test("fix error", () {
      final store = ResultStore<String>.error(error, stackTrace);
      final tester = ValueListenableTester(store.listenable);

      final fixedResult = store.fixError((err) {
        expect(err, error);

        return "fixed";
      });
      expect(tester.changeCount, 1);
      expect(fixedResult, "fixed");
      expect(tester.lastChange.asValue.value, "fixed");

      final ignoredResult = store.fixError((error) => "fixed again");
      expect(tester.changeCount, 1);
      expect(ignoredResult, "fixed");
    });
  });
}
