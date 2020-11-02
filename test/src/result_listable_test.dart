import 'package:flutter_test/flutter_test.dart';
import 'package:async/async.dart';

import 'package:response_builder/response_builder.dart';

import '../test_tools/listenable_tester.dart';

void main() {
  final value = "value";
  final error = ArgumentError("error");
  final exception = Exception("exception");
  final stackTrace = StackTrace.empty;

  group("ResultListenable", () {
    test("get value", () {
      final notifier = ResultNotifier<String>(value);

      expect(notifier.hasValue, isTrue);
      expect(notifier.value, equals(value));

      expect(notifier.hasError, isFalse);
      expect(() => notifier.error, throwsStateError);
      expect(() => notifier.stackTrace, throwsStateError);

      expect(notifier.result, isA<ValueResult<String>>());
      expect(notifier.result.asValue.value, equals(value));
    });

    test("get error", () {
      final notifier = ResultNotifier<String>.error(error, stackTrace);

      expect(notifier.hasValue, isFalse);
      expect(() => notifier.value, throwsStateError);

      expect(notifier.hasError, isTrue);
      expect(notifier.error, equals(error));
      expect(notifier.stackTrace, equals(stackTrace));

      expect(notifier.result, isA<ErrorResult>());
      expect(notifier.result.asError.error, equals(error));
      expect(notifier.result.asError.stackTrace, equals(stackTrace));
    });

    test("receive change notification", () {
      final notifier = ResultNotifier<String>("initial");
      final tester = ValueListenableTester(notifier.asValueListenable());

      expect(tester.changeCount, 0);

      notifier.putValue(value);

      expect(tester.changeCount, 1);
      expect(tester.popLastChange().asValue.value, value);

      notifier.putError(error, stackTrace);
      expect(tester.lastChange.asError.error, error);
      expect(tester.popLastChange().asError.stackTrace, stackTrace);
    });

    group("update value", () {
      test("update if holds value", () {
        final notifier = ResultNotifier<String>(value);
        final tester = ValueListenableTester(notifier.asValueListenable());

        final updateResult = notifier.updateValue((current) => "new $current");
        expect(tester.changeCount, 1);
        expect(updateResult, isTrue);
        expect(tester.lastChange.asValue.value, "new value");
      });

      test("ignore is holds error", () {
        final notifier = ResultNotifier<String>.error(exception);
        final tester = ValueListenableTester(notifier.asValueListenable());

        final updateResult = notifier.updateValue((current) => "new $current");
        expect(tester.changeCount, 0);
        expect(updateResult, isFalse);
      });

      test("update action throws exception", () {
        final notifier = ResultNotifier<String>(value);
        final tester = ValueListenableTester(notifier.asValueListenable());

        final updateResult = notifier.updateValue((current) => throw exception);
        expect(tester.changeCount, 1);
        expect(updateResult, isFalse);
        expect(tester.lastChange.asError.error, same(exception));
      });

      test("update value throws error", () {
        final notifier = ResultNotifier<String>(value);

        expect(() => notifier.updateValue((current) => throw error), throwsA(same(error)));
      });

      test("update value throws non error", () {
        final notifier = ResultNotifier<String>(value);
        final tester = ValueListenableTester(notifier.asValueListenable());

        final updateResult = notifier.updateValue((current) => throw current);
        expect(tester.changeCount, 1);
        expect(updateResult, false);
        expect(tester.lastChange.asError.error, same(value));
      });
    });

    test("fix error", () {
      final notifier = ResultNotifier<String>.error(error, stackTrace);
      final tester = ValueListenableTester(notifier.asValueListenable());

      final fixedResult = notifier.fixError((err) {
        expect(err, error);

        return "fixed";
      });
      expect(tester.changeCount, 1);
      expect(fixedResult, "fixed");
      expect(tester.lastChange.asValue.value, "fixed");

      final ignoredResult = notifier.fixError((error) => "fixed again");
      expect(tester.changeCount, 1);
      expect(ignoredResult, "fixed");
    });
  });
}
