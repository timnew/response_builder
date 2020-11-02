import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:response_builder/response_builder.dart';

import '../../test_tools/test_widget.dart';

class TestWidget extends StatelessWidget with WithEmptyValue<String> {
  final String content;

  const TestWidget(this.content);

  @override
  Widget build(BuildContext context) => TestBench(
        child: buildValue(context, content),
      );

  @override
  Widget buildContent(BuildContext context, String content) =>
      ContentWidget(content);

  @override
  Widget buildEmpty(BuildContext context, String emptyContent) => EmptyWidget();

  @override
  bool checkIsValueEmpty(String value) => value.isEmpty;
}

class TestFutureWithEmptyWidget extends StatelessWidget
    with BuildAsyncSnapshot<String>, WithEmptyValue<String> {
  final completer = Completer<String>();

  @override
  Widget build(BuildContext context) => TestBench(
        child: buildFuture(completer.future),
      );

  @override
  Widget buildContent(BuildContext context, String content) =>
      ContentWidget(content);

  @override
  Widget buildEmpty(BuildContext context, String emptyContent) => EmptyWidget();

  @override
  bool checkIsValueEmpty(String data) => data.isEmpty;
}

class DefaultBehaviorWidget<T> extends StatelessWidget with WithEmptyValue<T> {
  final T data;

  const DefaultBehaviorWidget(this.data);

  @override
  Widget build(BuildContext context) => TestBench(
        child: buildValue(context, data),
      );

  @override
  Widget buildContent(BuildContext context, T content) =>
      ContentWidget(content.toString());
}

void main() {
  useDefaultRenders();

  group("WithEmptyData", () {
    group("direct use", () {
      testWidgets("Render content", (WidgetTester tester) async {
        await tester.pumpWidget(TestWidget("data"));

        findContentWidget("data").shouldFindOne();
        findEmptyWidget.shouldFindNothing();
      });

      testWidgets("Render empty", (WidgetTester tester) async {
        await tester.pumpWidget(TestWidget(""));

        findContentWidget().shouldFindNothing();
        findEmptyWidget.shouldFindOne();
      });
    });

    group("with BuildAsyncSnapshot", () {
      testWidgets("Render content", (WidgetTester tester) async {
        final widget = TestFutureWithEmptyWidget();
        await tester.pumpWidget(widget);

        findWaitingWidget.shouldFindOne();
        findContentWidget().shouldFindNothing();
        findEmptyWidget.shouldFindNothing();
        findErrorWidget().shouldFindNothing();

        widget.completer.complete("data");
        await tester.pump();

        findWaitingWidget.shouldFindNothing();
        findContentWidget("data").shouldFindOne();
        findEmptyWidget.shouldFindNothing();
        findErrorWidget().shouldFindNothing();
      });

      testWidgets("Render empty", (WidgetTester tester) async {
        final widget = TestFutureWithEmptyWidget();
        await tester.pumpWidget(widget);

        findWaitingWidget.shouldFindOne();
        findContentWidget().shouldFindNothing();
        findEmptyWidget.shouldFindNothing();
        findErrorWidget().shouldFindNothing();

        widget.completer.complete("");
        await tester.pump();

        findWaitingWidget.shouldFindNothing();
        findContentWidget().shouldFindNothing();
        findEmptyWidget.shouldFindOne();
        findErrorWidget().shouldFindNothing();
      });

      testWidgets("Render error", (WidgetTester tester) async {
        final widget = TestFutureWithEmptyWidget();
        await tester.pumpWidget(widget);

        findWaitingWidget.shouldFindOne();
        findContentWidget().shouldFindNothing();
        findEmptyWidget.shouldFindNothing();
        findErrorWidget().shouldFindNothing();

        widget.completer.completeError("error");
        await tester.pump();

        findWaitingWidget.shouldFindNothing();
        findContentWidget().shouldFindNothing();
        findEmptyWidget.shouldFindNothing();
        findErrorWidget("error").shouldFindOne();
      });
    });

    group("default behavior", () {
      group("list", () {
        testWidgets("Render content", (WidgetTester tester) async {
          await tester.pumpWidget(DefaultBehaviorWidget(["data"]));

          findContentWidget("[data]").shouldFindOne();
          findInTestScope.findChild<Container>().shouldFindNothing();
        });

        testWidgets("Render empty", (WidgetTester tester) async {
          await tester.pumpWidget(DefaultBehaviorWidget([]));

          findContentWidget().shouldFindNothing();
          findInTestScope.findChild<Container>().shouldFindOne();
        });

        testWidgets("Render null", (WidgetTester tester) async {
          await tester.pumpWidget(DefaultBehaviorWidget<List>(null));

          findContentWidget().shouldFindNothing();
          findInTestScope.findChild<Container>().shouldFindOne();
        });
      });

      group("map", () {
        testWidgets("Render content", (WidgetTester tester) async {
          await tester.pumpWidget(DefaultBehaviorWidget({"key": "data"}));

          findContentWidget("{key: data}").shouldFindOne();
          findInTestScope.findChild<Container>().shouldFindNothing();
        });

        testWidgets("Render empty", (WidgetTester tester) async {
          await tester.pumpWidget(DefaultBehaviorWidget({}));

          findContentWidget().shouldFindNothing();
          findInTestScope.findChild<Container>().shouldFindOne();
        });

        testWidgets("Render null", (WidgetTester tester) async {
          await tester.pumpWidget(DefaultBehaviorWidget<Map>(null));

          findContentWidget().shouldFindNothing();
          findInTestScope.findChild<Container>().shouldFindOne();
        });
      });

      group("set", () {
        testWidgets("Render content", (WidgetTester tester) async {
          await tester.pumpWidget(DefaultBehaviorWidget(Set.of(["data"])));

          findContentWidget("{data}").shouldFindOne();
          findInTestScope.findChild<Container>().shouldFindNothing();
        });

        testWidgets("Render empty", (WidgetTester tester) async {
          await tester.pumpWidget(DefaultBehaviorWidget(Set.of([])));

          findContentWidget().shouldFindNothing();
          findInTestScope.findChild<Container>().shouldFindOne();
        });

        testWidgets("Render null", (WidgetTester tester) async {
          await tester.pumpWidget(DefaultBehaviorWidget<Set>(null));

          findContentWidget().shouldFindNothing();
          findInTestScope.findChild<Container>().shouldFindOne();
        });
      });

      group("unsupported", () {
        testWidgets("Render content", (WidgetTester tester) async {
          expect(tester.pumpWidget(DefaultBehaviorWidget("data")),
              throwsUnsupportedError);
        }, skip: true);

        testWidgets("Render empty", (WidgetTester tester) async {
          expect(tester.pumpWidget(DefaultBehaviorWidget("")),
              throwsUnsupportedError);
        }, skip: true);

        testWidgets("Render null", (WidgetTester tester) async {
          await tester.pumpWidget(DefaultBehaviorWidget<String>(null));

          findContentWidget().shouldFindNothing();
          findInTestScope.findChild<Container>().shouldFindOne();
        });
      },
          skip:
              "error is thrown in build phrase, which is caught by future of pumpWidget");
    });
  });
}
