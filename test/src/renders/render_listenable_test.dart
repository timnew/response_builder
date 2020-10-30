import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:request_render/request_render.dart';

import '../../dsl/test_widget.dart';

class TestValueWidget extends StatelessWidget with RenderValueListenable<String> {
  final ValueListenable<String> listenable;

  TestValueWidget(this.listenable);

  @override
  Widget build(BuildContext context) => TestBench(child: buildValueListenable(listenable));

  @override
  Widget buildData(BuildContext context, String data) => ContentWidget(data);
}

class TestResultWidget extends StatelessWidget with RenderResultListenable<String> {
  final ResultStore<String> store;

  const TestResultWidget(this.store);

  @override
  Widget build(BuildContext context) => TestBench(child: buildStore(store));

  @override
  Widget buildData(BuildContext context, String data) => ContentWidget(data);
}

void main() {
  group("RenderValueListenable", () {
    testWidgets("render value listenable", (WidgetTester tester) async {
      final notifier = ValueNotifier<String>("data");

      await tester.pumpWidget(TestValueWidget(notifier));

      findContentWidget("data").shouldFindOne();

      notifier.value = "new data";

      await tester.pump();

      findContentWidget("new data").shouldFindOne();
    });
  });

  group("RenderResultListenable", () {
    useDefaultRenders();

    testWidgets("render value", (WidgetTester tester) async {
      final store = ResultStore<String>("data");

      await tester.pumpWidget(TestResultWidget(store));

      findContentWidget("data").shouldFindOne();

      store.putValue("new data");
      await tester.pump();

      findContentWidget("new data").shouldFindOne();
    });

    testWidgets("render error", (WidgetTester tester) async {
      final store = ResultStore<String>("data");

      await tester.pumpWidget(TestResultWidget(store));

      findContentWidget("data").shouldFindOne();
      findErrorWidget().shouldFindNone();

      store.putError("error");
      await tester.pump();

      findContentWidget().shouldFindNone();
      findErrorWidget("error").shouldFindOne();

      store.putValue("new data");
      await tester.pump();

      findContentWidget("new data").shouldFindOne();
      findErrorWidget().shouldFindNone();
    });
  });
}
