import 'package:flutter/material.dart' hide ErrorWidget;
import 'package:flutter_test/flutter_test.dart';
import 'package:request_render/renders.dart';

import '../../dsl/test_widget.dart';

class TestErrorWidget extends StatelessWidget {
  final Object error;

  TestErrorWidget(this.error);

  @override
  Widget build(BuildContext context) => TestApp(child: DefaultRenders.buildError(context, error));
}

class TestWaitingWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TestApp(
        child: DefaultRenders.buildWaiting(context),
      );
}

void main() {
  final error = "test error message";

  testWidgets("build error with built in builder", (WidgetTester tester) async {
    await tester.pumpWidget(TestErrorWidget(error));

    find.text(error).shouldFindOne();
  });

  testWidgets("build error with customize builder", (WidgetTester tester) async {
    DefaultRenders.registerDefaultErrorBuilder((context, data) => ErrorWidget(data));

    await tester.pumpWidget(TestErrorWidget(error));

    findError(error).shouldFindOne();
  });

  testWidgets("build waiting with built in builder", (WidgetTester tester) async {
    await tester.pumpWidget(TestWaitingWidget());

    find.byType(CircularProgressIndicator).shouldFindOne();
  });

  testWidgets("build error with customize builder", (WidgetTester tester) async {
    DefaultRenders.registerDefaultWaitingBuilder((context) => EmptyWidget());

    await tester.pumpWidget(TestWaitingWidget());

    findEmptyWidget.shouldFindOne();
  });

  tearDown(() {
    DefaultRenders.clearForTest();
  });
}
