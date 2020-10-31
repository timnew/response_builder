import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:response_builder/response_builder.dart';

import '../../test_tools/test_widget.dart';

class TestWidget extends StatelessWidget with WithEmptyContent<String> {
  final String content;

  const TestWidget(this.content);

  @override
  Widget build(BuildContext context) => TestBench(
        child: buildData(context, content),
      );

  @override
  Widget buildContent(BuildContext context, String content) => ContentWidget(content);

  @override
  Widget buildEmpty(BuildContext context) => EmptyWidget();

  @override
  bool checkEmpty(String data) => data.isEmpty;
}

class TestFutureWithEmptyWidget extends StatelessWidget with BuildAsyncResult<String>, WithEmptyContent<String> {
  final completer = Completer<String>();

  @override
  Widget build(BuildContext context) => TestBench(
        child: buildFuture(completer.future),
      );

  @override
  Widget buildContent(BuildContext context, String content) => ContentWidget(content);

  @override
  Widget buildEmpty(BuildContext context) => EmptyWidget();

  @override
  bool checkEmpty(String data) => data.isEmpty;
}

void main() {
  useDefaultRenders();

  group("WithEmptyContent", () {
    group("direct use", () {
      testWidgets("Render content", (WidgetTester tester) async {
        await tester.pumpWidget(TestWidget("data"));

        findContentWidget("data").shouldFindOne();
        findEmptyWidget.shouldFindNone();
      });

      testWidgets("Render empty", (WidgetTester tester) async {
        await tester.pumpWidget(TestWidget(""));

        findContentWidget().shouldFindNone();
        findEmptyWidget.shouldFindOne();
      });
    });

    group("with BuildAsyncResult", () {
      testWidgets("Render content", (WidgetTester tester) async {
        final widget = TestFutureWithEmptyWidget();
        await tester.pumpWidget(widget);

        findWaitingWidget.shouldFindOne();
        findContentWidget().shouldFindNone();
        findEmptyWidget.shouldFindNone();
        findErrorWidget().shouldFindNone();

        widget.completer.complete("data");
        await tester.pump();

        findWaitingWidget.shouldFindNone();
        findContentWidget("data").shouldFindOne();
        findEmptyWidget.shouldFindNone();
        findErrorWidget().shouldFindNone();
      });

      testWidgets("Render empty", (WidgetTester tester) async {
        final widget = TestFutureWithEmptyWidget();
        await tester.pumpWidget(widget);

        findWaitingWidget.shouldFindOne();
        findContentWidget().shouldFindNone();
        findEmptyWidget.shouldFindNone();
        findErrorWidget().shouldFindNone();

        widget.completer.complete("");
        await tester.pump();

        findWaitingWidget.shouldFindNone();
        findContentWidget().shouldFindNone();
        findEmptyWidget.shouldFindOne();
        findErrorWidget().shouldFindNone();
      });

      testWidgets("Render error", (WidgetTester tester) async {
        final widget = TestFutureWithEmptyWidget();
        await tester.pumpWidget(widget);

        findWaitingWidget.shouldFindOne();
        findContentWidget().shouldFindNone();
        findEmptyWidget.shouldFindNone();
        findErrorWidget().shouldFindNone();

        widget.completer.completeError("error");
        await tester.pump();

        findWaitingWidget.shouldFindNone();
        findContentWidget().shouldFindNone();
        findEmptyWidget.shouldFindNone();
        findErrorWidget("error").shouldFindOne();
      });
    });
  });
}
