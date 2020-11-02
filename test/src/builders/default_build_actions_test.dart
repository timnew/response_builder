import 'package:flutter/material.dart' hide ErrorWidget;
import 'package:flutter_test/flutter_test.dart';
import 'package:response_builder/response_builder.dart';

import '../../test_tools/test_widget.dart';

class TestErrorWidget extends StatelessWidget {
  final Object error;

  TestErrorWidget(this.error);

  @override
  Widget build(BuildContext context) =>
      TestBench(child: DefaultBuildActions.buildError(context, error));
}

class TestWaitingWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TestBench(
        child: DefaultBuildActions.buildLoading(context),
      );
}

void main() {
  group("default build actions", () {
    final error = "test error message";

    testWidgets("build error with built in builder",
        (WidgetTester tester) async {
      await tester.pumpWidget(TestErrorWidget(error));

      find.text(error).shouldFindOne();
    });

    testWidgets("build error with customize builder",
        (WidgetTester tester) async {
      DefaultBuildActions.registerDefaultErrorBuilder(
          (context, data) => ErrorWidget(data));

      await tester.pumpWidget(TestErrorWidget(error));

      findErrorWidget(error).shouldFindOne();
    });

    testWidgets("build waiting with built in builder",
        (WidgetTester tester) async {
      await tester.pumpWidget(TestWaitingWidget());

      find.byType(CircularProgressIndicator).shouldFindOne();
    });

    testWidgets("build error with customize builder",
        (WidgetTester tester) async {
      DefaultBuildActions.registerDefaultLoadingBuilder(
          (context) => EmptyWidget());

      await tester.pumpWidget(TestWaitingWidget());

      findEmptyWidget.shouldFindOne();
    });

    tearDown(() {
      DefaultBuildActions.registerDefaultLoadingBuilder(null);
      DefaultBuildActions.registerDefaultErrorBuilder(null);
    });
  });
}
