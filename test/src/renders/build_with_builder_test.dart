import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:request_render/request_render.dart';

import '../../test_tools//test_widget.dart';

class TestWidget extends StatelessWidget with BuildWithBuilder {
  final TransitionBuilder builder;
  final Widget child;

  const TestWidget({Key key, this.builder, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) => TestBench(
        child: buildWithBuilder(context, builder, child),
      );
}

class AnotherTestWidget extends StatelessWidget with BuildWithBuilderInLocalContext {
  final TransitionBuilder builder;
  final Widget child;

  const AnotherTestWidget({Key key, this.builder, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) => TestBench(
        child: buildWithBuilder(builder, child),
      );
}

void main() {
  group("BuildWithBuilder", () {
    testWidgets("BuildWithBuilder should build with only builder", (WidgetTester tester) async {
      await tester.pumpWidget(
        TestWidget(
          builder: (context, child) => ContentWidget("data"),
        ),
      );

      findContentWidget("data").shouldFindOne();
    });

    testWidgets("BuildWithBuilder should build with only child", (WidgetTester tester) async {
      await tester.pumpWidget(
        TestWidget(
          child: ContentWidget("data"),
        ),
      );

      findContentWidget("data").shouldFindOne();
    });

    testWidgets("BuildWithBuilder should build with both builder and child", (WidgetTester tester) async {
      await tester.pumpWidget(
        TestWidget(
          builder: (context, child) => Container(child: child),
          child: ContentWidget("data"),
        ),
      );

      findContentWidget("data").findAncestor<Container>().shouldFindOne();
    });
  });

  group("BuildWithBuilderInLocalContext", () {
    testWidgets("BuildWithBuilder should build with only builder", (WidgetTester tester) async {
      await tester.pumpWidget(
        AnotherTestWidget(
          builder: (context, child) => ContentWidget("data"),
        ),
      );

      findInTestScope.findChild<Builder>().findChildBy(findContentWidget("data")).shouldFindOne();
    });

    testWidgets("BuildWithBuilder should build with only child", (WidgetTester tester) async {
      await tester.pumpWidget(
        AnotherTestWidget(
          child: ContentWidget("data"),
        ),
      );

      findInTestScope.findChild<Builder>().shouldFindNone();
      findInTestScope.findChildBy(findContentWidget("data")).shouldFindOne();
    });

    testWidgets("BuildWithBuilder should build with both builder and child", (WidgetTester tester) async {
      await tester.pumpWidget(
        AnotherTestWidget(
          builder: (context, child) => Container(child: child),
          child: ContentWidget("data"),
        ),
      );

      findInTestScope
          .findChild<Builder>()
          .findChild<Container>()
          .findChildBy(findContentWidget("data"))
          .shouldFindOne();
    });
  });
}
