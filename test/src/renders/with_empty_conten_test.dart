import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:request_render/request_render.dart';

import '../../dsl/test_widget.dart';

class TestWidget extends StatelessWidget with WithEmptyContent<String> {
  final String content;

  const TestWidget(this.content);

  @override
  Widget build(BuildContext context) => TestApp(
        child: buildData(context, content),
      );

  @override
  Widget buildContent(BuildContext context, String content) => ContentWidget(content);

  @override
  Widget buildEmpty(BuildContext context) => EmptyWidget();

  @override
  bool checkEmpty(String data) => data.isEmpty;
}

void main() {
  testWidgets("Should build content", (WidgetTester tester) async {
    await tester.pumpWidget(TestWidget("data"));

    findContent("data").shouldFindOne();
    findEmptyWidget.shouldFindNone();
  });

  testWidgets("Should build content", (WidgetTester tester) async {
    await tester.pumpWidget(TestWidget(""));

    findContentWidget.shouldFindNone();
    findEmptyWidget.shouldFindOne();
  });
}
