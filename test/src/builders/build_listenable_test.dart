import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:response_builder/response_builder.dart';

import '../../test_tools/test_widget.dart';

class TestValueWidget extends StatelessWidget
    with BuildValueListenable<String> {
  final ValueListenable<String> listenable;

  TestValueWidget(this.listenable);

  @override
  Widget build(BuildContext context) =>
      TestBench(child: buildValueListenable(listenable));

  @override
  Widget buildData(BuildContext context, String data) => ContentWidget(data);
}

class TestResultWidget extends StatelessWidget
    with BuildResultListenable<String> {
  final ResultStore<String> store;

  const TestResultWidget(this.store);

  @override
  Widget build(BuildContext context) => TestBench(child: buildStore(store));

  @override
  Widget buildData(BuildContext context, String data) => ContentWidget(data);
}

void main() {
  group("BuildValueListenable", () {
    testWidgets("build value listenable", (WidgetTester tester) async {
      final notifier = ValueNotifier<String>("data");

      await tester.pumpWidget(TestValueWidget(notifier));

      findContentWidget("data").shouldFindOne();

      notifier.value = "new data";

      await tester.pump();

      findContentWidget("new data").shouldFindOne();
    });
  });

  group("BuildResultListenable", () {
    useDefaultRenders();

    testWidgets("build value", (WidgetTester tester) async {
      final store = ResultStore<String>("data");

      await tester.pumpWidget(TestResultWidget(store));

      findContentWidget("data").shouldFindOne();

      store.putValue("new data");
      await tester.pump();

      findContentWidget("new data").shouldFindOne();
    });

    testWidgets("build error", (WidgetTester tester) async {
      final store = ResultStore<String>("data");

      await tester.pumpWidget(TestResultWidget(store));

      findContentWidget("data").shouldFindOne();
      findErrorWidget().shouldFindNothing();

      store.putError("error");
      await tester.pump();

      findContentWidget().shouldFindNothing();
      findErrorWidget("error").shouldFindOne();

      store.putValue("new data");
      await tester.pump();

      findContentWidget("new data").shouldFindOne();
      findErrorWidget().shouldFindNothing();
    });
  });
}
