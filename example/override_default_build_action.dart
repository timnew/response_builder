import 'package:flutter/cupertino.dart';
import 'package:response_builder/response_builder.dart';

void main() {
  DefaultBuildActions.registerDefaultLoadingBuilder((context) {
    return Center(
      child: CupertinoActivityIndicator(),
    );
  });

  DefaultBuildActions.registerDefaultErrorBuilder((context, error) {
    final errorColor = CupertinoColors.systemRed;

    return Center(
      child: Row(children: [
        Icon(CupertinoIcons.xmark_circle, color: errorColor),
        Text(error.toString(), style: TextStyle(color: errorColor)),
      ]),
    );
  });
}
