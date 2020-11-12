import 'package:flutter_test/flutter_test.dart';
import 'package:response_builder/src/data_sources/history_value_notifier.dart';

import '../../test_tools/listenable_tester.dart';

void main() {
  group("HistoryValueNotifier", () {
    group("create", () {
      test("empty instance", () {
        final notifier = HistoryValueNotifier<int>(4);

        expect(notifier.capacity, 4);
        expect(notifier.historyLength, 0);
        expect(notifier.undoCount, 0);
        expect(notifier.redoCount, 0);
      });

      test("with initial value", () {
        final notifier = HistoryValueNotifier<int>(4, initialValue: 100);

        expect(notifier.value, 100);

        expect(notifier.capacity, 4);
        expect(notifier.historyLength, 1);
        expect(notifier.undoCount, 0);
        expect(notifier.redoCount, 0);
      });
    });

    group("update", () {
      test("putValue", () {
        final notifier = HistoryValueNotifier<int>(4, initialValue: 100);
        final listener = ValueListenableTester(notifier);

        expect(notifier.value, 100);
        expect(notifier.historyLength, 1);

        notifier.putValue(200);

        expect(notifier.value, 200);
        expect(notifier.historyLength, 2);

        expect(listener.pastValues, [200]);
      });

      test("putValue off record", () {
        final notifier = HistoryValueNotifier<int>(4, initialValue: 100);
        final listener = ValueListenableTester(notifier);

        expect(notifier.value, 100);
        expect(notifier.historyLength, 1);

        notifier.putValue(200, offRecord: true);

        expect(notifier.value, 200);
        expect(notifier.historyLength, 1);

        expect(listener.pastValues, [200]);
      });

      test("putValue silently", () {
        final notifier = HistoryValueNotifier<int>(4, initialValue: 100);
        final listener = ValueListenableTester(notifier);

        expect(notifier.value, 100);
        expect(notifier.historyLength, 1);

        notifier.putValue(200, silent: true);

        expect(notifier.value, 200);
        expect(notifier.historyLength, 2);

        expect(listener.pastValues, isEmpty);
      });
    });

    group("undo redo", () {
      test("undo redo changes", () {
        final notifier = HistoryValueNotifier<int>(4);
        final listener = ValueListenableTester(notifier);

        expect(notifier.historyLength, 0);
        expect(notifier.undoCount, 0);
        expect(notifier.canUndo, false);
        expect(notifier.redoCount, 0);
        expect(notifier.canRedo, false);

        notifier.value = 1;

        expect(notifier.value, 1);
        expect(listener.pastValues, [1]);

        expect(notifier.historyLength, 1);
        expect(notifier.undoCount, 0);
        expect(notifier.canUndo, false);
        expect(notifier.redoCount, 0);
        expect(notifier.canRedo, false);

        notifier.value = 2;

        expect(notifier.value, 2);
        expect(listener.pastValues, [1, 2]);

        expect(notifier.historyLength, 2);
        expect(notifier.undoCount, 1);
        expect(notifier.canUndo, true);
        expect(notifier.redoCount, 0);
        expect(notifier.canRedo, false);

        expect(notifier.undo(), 1);

        expect(notifier.value, 1);
        expect(listener.pastValues, [1, 2, 1]);

        expect(notifier.historyLength, 2);
        expect(notifier.undoCount, 0);
        expect(notifier.canUndo, false);
        expect(notifier.redoCount, 1);
        expect(notifier.canRedo, true);

        expect(notifier.redo(), 2);

        expect(notifier.value, 2);
        expect(listener.pastValues, [1, 2, 1, 2]);

        expect(notifier.historyLength, 2);
        expect(notifier.undoCount, 1);
        expect(notifier.canUndo, true);
        expect(notifier.redoCount, 0);
        expect(notifier.canRedo, false);
      });

      test("undo does nothing when undo is not available", () {
        final notifier = HistoryValueNotifier<int>(4, initialValue: 100);
        final listener = ValueListenableTester(notifier);

        expect(notifier.value, 100);
        expect(notifier.canUndo, false);

        expect(notifier.undo(), 100);
        expect(listener.pastValues, isEmpty);
      });

      test("redo does nothing when undo is not available", () {
        final notifier = HistoryValueNotifier<int>(4, initialValue: 100);
        final listener = ValueListenableTester(notifier);

        expect(notifier.value, 100);
        expect(notifier.canRedo, false);

        expect(notifier.redo(), 100);
        expect(listener.pastValues, isEmpty);
      });
    });

    group("history management", () {
      test("drop oldest history when full", () {
        final notifier = HistoryValueNotifier<int>(2);
        final listener = ValueListenableTester(notifier);

        notifier.putValue(1);
        notifier.putValue(2);

        expect(notifier.value, 2);
        expect(listener.pastValues, [1, 2]);

        expect(notifier.capacity, 2);
        expect(notifier.historyLength, 2);
        expect(notifier.undoCount, 1);
        expect(notifier.redoCount, 0);

        notifier.putValue(3);

        expect(notifier.value, 3);
        expect(listener.pastValues, [1, 2, 3]);

        expect(notifier.capacity, 2);
        expect(notifier.historyLength, 2);
        expect(notifier.undoCount, 1);
        expect(notifier.redoCount, 0);

        notifier.undo();

        expect(listener.pastValues, [1, 2, 3, 2]);

        expect(notifier.capacity, 2);
        expect(notifier.historyLength, 2);
        expect(notifier.undoCount, 0);
        expect(notifier.redoCount, 1);
      });

      test("purge future changes when value changed after undo", () {
        final notifier = HistoryValueNotifier<int>(4);

        notifier.putValue(1);
        notifier.putValue(2);
        notifier.putValue(3);
        notifier.putValue(4);
        notifier.undo();
        notifier.undo();

        expect(notifier.value, 2);
        expect(notifier.historyLength, 4);
        expect(notifier.undoCount, 1);
        expect(notifier.redoCount, 2);

        notifier.putValue(100);

        expect(notifier.value, 100);
        expect(notifier.historyLength, 3);
        expect(notifier.undoCount, 2);
        expect(notifier.redoCount, 0);
      });

      test(
          "purge future changes when value changed after undo for off record change",
          () {
        final notifier = HistoryValueNotifier<int>(4);

        notifier.putValue(1);
        notifier.putValue(2);
        notifier.putValue(3);
        notifier.putValue(4);
        notifier.undo();
        notifier.undo();

        expect(notifier.value, 2);
        expect(notifier.historyLength, 4);
        expect(notifier.undoCount, 1);
        expect(notifier.redoCount, 2);

        notifier.putValue(100, offRecord: true);

        expect(notifier.value, 100);
        expect(notifier.historyLength, 2);
        expect(notifier.undoCount, 1);
        expect(notifier.redoCount, 0);
      });

      test("truncate history", () {
        final notifier = HistoryValueNotifier<int>(4);

        notifier.putValue(1);
        notifier.putValue(2);
        notifier.putValue(3);
        notifier.putValue(4);
        notifier.undo();
        notifier.undo();

        expect(notifier.value, 2);
        expect(notifier.historyLength, 4);
        expect(notifier.undoCount, 1);
        expect(notifier.redoCount, 2);

        notifier.truncateHistory();

        expect(notifier.value, 2);
        expect(notifier.capacity, 4);
        expect(notifier.historyLength, 1);
        expect(notifier.undoCount, 0);
        expect(notifier.redoCount, 0);
      });
    });
  });
}
