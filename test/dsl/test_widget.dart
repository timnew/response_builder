import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

export 'finder_extension.dart';

class TestApp extends StatelessWidget {
  final Widget child;

  TestApp({this.child});

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          body: TestScope(child: child),
        ),
      );
}

class TestScope extends StatelessWidget {
  final Widget child;

  const TestScope({Key key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) => child;
}

final findInTestScope = find.byType(TestScope);

class EmptyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text("Empty");
}

final findEmptyWidget = find.byType(EmptyWidget);

class ErrorWidget extends StatelessWidget {
  final Object error;

  ErrorWidget(this.error);

  @override
  Widget build(BuildContext context) {
    return Text("$error");
  }
}

final findErrorWidget = find.byType(ErrorWidget);

Finder findError(Object error) => find.widgetWithText(ErrorWidget, "$error");

class WaitingWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

final findWaiting = find.byType(WaitingWidget);

class ContentWidget extends StatelessWidget {
  final String content;

  ContentWidget(this.content);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text("Content"),
        Text(content),
      ],
    );
  }
}

final findContentWidget = find.byType(ContentWidget);

Finder findContent(String content) => find.widgetWithText(ContentWidget, content);
