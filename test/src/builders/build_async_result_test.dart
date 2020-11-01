import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:response_builder/response_builder.dart';

import '../../test_tools/test_widget.dart';

class TestFutureWidget extends StatelessWidget with BuildAsyncResult<String> {
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
  TestRequest() : super(loadOnListened: false);

  @override
  Future<String> load() async {
    return null;
  }
}

class TestRequestWidget extends StatelessWidget with BuildAsyncResult<String> {
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

  group("BuildAsyncResult", () {
    group("build future", () {
      testWidgets("build future data", (WidgetTester tester) async {
        final completer = Completer<String>();

        await tester.pumpWidget(TestFutureWidget(completer.future));

        findInitialWidget.shouldFindNothing();
        findWaitingWidget.shouldFindOne();
        findContentWidget().shouldFindNothing();
        findErrorWidget().shouldFindNothing();

        completer.complete("data");
        await tester.pump();

        findInitialWidget.shouldFindNothing();
        findWaitingWidget.shouldFindNothing();
        findContentWidget("data").shouldFindOne();
        findErrorWidget().shouldFindNothing();
      });

      testWidgets("build future error", (WidgetTester tester) async {
        final completer = Completer<String>();

        await tester.pumpWidget(TestFutureWidget(completer.future));

        findInitialWidget.shouldFindNothing();
        findWaitingWidget.shouldFindOne();
        findContentWidget().shouldFindNothing();
        findErrorWidget().shouldFindNothing();

        completer.completeError("error");
        await tester.pump();

        findInitialWidget.shouldFindNothing();
        findWaitingWidget.shouldFindNothing();
        findContentWidget().shouldFindNothing();
        findErrorWidget("error").shouldFindOne();
      });

      testWidgets("build null", (WidgetTester tester) async {
        await tester.pumpWidget(TestFutureWidget(null));

        findInitialWidget.shouldFindOne();
        findWaitingWidget.shouldFindNothing();
        findContentWidget().shouldFindNothing();
        findErrorWidget().shouldFindNothing();
      });
    });

    group("build stream/request", () {
      testWidgets("build stream data sequence", (WidgetTester tester) async {
        final request = TestRequest();

        // initialize
        await tester.pumpWidget(TestRequestWidget(request));

        findInitialWidget.shouldFindNothing();
        findWaitingWidget.shouldFindOne();
        findContentWidget().shouldFindNothing();
        findErrorWidget().shouldFindNothing();

        // loading
        await tester.runAsync(() async {
          request.markAsWaiting();
        });
        await tester.pump();

        findInitialWidget.shouldFindNothing();
        findWaitingWidget.shouldFindOne();
        findContentWidget().shouldFindNothing();
        findErrorWidget().shouldFindNothing();

        // fetch data
        await tester.runAsync(() async {
          request.putValue("data");
        });
        await tester.pump();

        findInitialWidget.shouldFindNothing();
        findWaitingWidget.shouldFindNothing();
        findContentWidget("data").shouldFindOne();
        findErrorWidget().shouldFindNothing();

        await tester.runAsync(() async {
          request.markAsWaiting();
        });
        await tester.pump();

        findInitialWidget.shouldFindNothing();
        findWaitingWidget.shouldFindOne();
        findContentWidget().shouldFindNothing();
        findErrorWidget().shouldFindNothing();

        // error returned
        await tester.runAsync(() async {
          request.putError("error");
        });
        await tester.pump();

        findInitialWidget.shouldFindNothing();
        findWaitingWidget.shouldFindNothing();
        findContentWidget().shouldFindNothing();
        findErrorWidget("error").shouldFindOne();
      });

      testWidgets("build empty request/stream", (WidgetTester tester) async {
        // initialize
        await tester.pumpWidget(TestRequestWidget(null));

        findInitialWidget.shouldFindOne();
        findWaitingWidget.shouldFindNothing();
        findContentWidget().shouldFindNothing();
        findErrorWidget().shouldFindNothing();
      });
    });
  });
}
