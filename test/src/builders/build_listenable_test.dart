import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:response_builder/response_builder.dart';

import '../../test_tools/test_widget.dart';

class TestValueWidget extends StatelessWidget with BuildValue<String> {
  final ValueListenable<String> listenable;

  TestValueWidget(this.listenable);

  @override
  Widget build(BuildContext context) => TestBench(child: buildValueListenable(listenable));

  @override
  Widget buildValue(BuildContext context, String value) => ContentWidget(value);
}

class TestResultWidget extends StatelessWidget with BuildResult<String> {
  final ResultNotifier<String> notifier;

  const TestResultWidget(this.notifier);

  @override
  Widget build(BuildContext context) => TestBench(child: buildResultListenable(notifier));

  @override
  Widget buildValue(BuildContext context, String value) => ContentWidget(value);
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
      final notifier = ResultNotifier<String>("data");

      await tester.pumpWidget(TestResultWidget(notifier));

      findContentWidget("data").shouldFindOne();

      notifier.putValue("new data");
      await tester.pump();

      findContentWidget("new data").shouldFindOne();
    });

    testWidgets("build error", (WidgetTester tester) async {
      final notifier = ResultNotifier<String>("data");

      await tester.pumpWidget(TestResultWidget(notifier));

      findContentWidget("data").shouldFindOne();
      findErrorWidget().shouldFindNothing();

      notifier.putError("error");
      await tester.pump();

      findContentWidget().shouldFindNothing();
      findErrorWidget("error").shouldFindOne();

      notifier.putValue("new data");
      await tester.pump();

      findContentWidget("new data").shouldFindOne();
      findErrorWidget().shouldFindNothing();
    });
  });
}
