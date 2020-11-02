import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:response_builder/response_builder.dart';

export 'finder_extension.dart';

class TestBench extends StatelessWidget {
  final Widget child;

  TestBench({this.child});

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

class InitialWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

final findInitialWidget = find.byType(InitialWidget);

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

Finder findErrorWidget([Object error]) =>
    error == null ? find.byType(ErrorWidget) : find.widgetWithText(ErrorWidget, "$error");

class WaitingWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

final findWaitingWidget = find.byType(WaitingWidget);

void useDefaultRenders() {
  setUpAll(() {
    DefaultBuildActions.registerDefaultLoadingBuilder((context) => WaitingWidget());
    DefaultBuildActions.registerDefaultErrorBuilder((context, error) => ErrorWidget(error));
  });

  tearDownAll(() {
    DefaultBuildActions.registerDefaultLoadingBuilder(null);
    DefaultBuildActions.registerDefaultErrorBuilder(null);
  });
}

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

Finder findContentWidget([String content]) =>
    content == null ? find.byType(ContentWidget) : find.widgetWithText(ContentWidget, content);
