import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:request_render/request_render.dart';

import '../../test_tools/test_widget.dart';

class TestFutureWidget extends StatelessWidget with RenderAsyncSnapshot<String> {
  final Future<String> future;

  const TestFutureWidget(this.future);

  @override
  Widget build(BuildContext context) => TestBench(
        child: buildFuture(future),
      );

  @override
  Widget buildInitialState(BuildContext context) => InitialWidget();

  @override
  Widget buildData(BuildContext context, String data) => ContentWidget(data);
}

class TestRequest extends Request<String> {
  TestRequest() : super(executeOnFirstListen: false);

  @override
  Future<String> load() async {
    return null;
  }
}

class TestRequestWidget extends StatelessWidget with RenderAsyncSnapshot<String> {
  final TestRequest request;

  TestRequestWidget(this.request);

  @override
  Widget build(BuildContext context) => TestBench(
        child: buildRequest(request),
      );

  @override
  Widget buildInitialState(BuildContext context) => InitialWidget();

  @override
  Widget buildData(BuildContext context, String data) => ContentWidget(data);
}

void main() {
  useDefaultRenders();

  group("render future", () {
    testWidgets("Render future data", (WidgetTester tester) async {
      final completer = Completer<String>();

      await tester.pumpWidget(TestFutureWidget(completer.future));

      findInitialWidget.shouldFindNone();
      findWaitingWidget.shouldFindOne();
      findContentWidget().shouldFindNone();
      findErrorWidget().shouldFindNone();

      completer.complete("data");
      await tester.pump();

      findInitialWidget.shouldFindNone();
      findWaitingWidget.shouldFindNone();
      findContentWidget("data").shouldFindOne();
      findErrorWidget().shouldFindNone();
    });

    testWidgets("Render future error", (WidgetTester tester) async {
      final completer = Completer<String>();

      await tester.pumpWidget(TestFutureWidget(completer.future));

      findInitialWidget.shouldFindNone();
      findWaitingWidget.shouldFindOne();
      findContentWidget().shouldFindNone();
      findErrorWidget().shouldFindNone();

      completer.completeError("error");
      await tester.pump();

      findInitialWidget.shouldFindNone();
      findWaitingWidget.shouldFindNone();
      findContentWidget().shouldFindNone();
      findErrorWidget("error").shouldFindOne();
    });

    testWidgets("Render null", (WidgetTester tester) async {
      await tester.pumpWidget(TestFutureWidget(null));

      findInitialWidget.shouldFindOne();
      findWaitingWidget.shouldFindNone();
      findContentWidget().shouldFindNone();
      findErrorWidget().shouldFindNone();
    });
  });

  group("render stream/request", () {
    testWidgets("Render stream data sequence", (WidgetTester tester) async {
      final request = TestRequest();

      // initialize
      await tester.pumpWidget(TestRequestWidget(request));

      findInitialWidget.shouldFindNone();
      findWaitingWidget.shouldFindOne();
      findContentWidget().shouldFindNone();
      findErrorWidget().shouldFindNone();

      // loading
      await tester.runAsync(() async {
        request.markAsWaiting();
      });
      await tester.pump();

      findInitialWidget.shouldFindNone();
      findWaitingWidget.shouldFindOne();
      findContentWidget().shouldFindNone();
      findErrorWidget().shouldFindNone();

      // fetch data
      await tester.runAsync(() async {
        request.putValue("data");
      });
      await tester.pump();

      findInitialWidget.shouldFindNone();
      findWaitingWidget.shouldFindNone();
      findContentWidget("data").shouldFindOne();
      findErrorWidget().shouldFindNone();

      await tester.runAsync(() async {
        request.markAsWaiting();
      });
      await tester.pump();

      findInitialWidget.shouldFindNone();
      findWaitingWidget.shouldFindOne();
      findContentWidget().shouldFindNone();
      findErrorWidget().shouldFindNone();

      // error returned
      await tester.runAsync(() async {
        request.putError("error");
      });
      await tester.pump();

      findInitialWidget.shouldFindNone();
      findWaitingWidget.shouldFindNone();
      findContentWidget().shouldFindNone();
      findErrorWidget("error").shouldFindOne();
    });

    testWidgets("build empty request/stream", (WidgetTester tester) async {
      // initialize
      await tester.pumpWidget(TestRequestWidget(null));

      findInitialWidget.shouldFindOne();
      findWaitingWidget.shouldFindNone();
      findContentWidget().shouldFindNone();
      findErrorWidget().shouldFindNone();
    });
  });
}
