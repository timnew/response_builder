import 'dart:async';

import 'package:flutter/material.dart';
import 'package:response_builder/response_builder.dart';

class FormData {
  final Map<String, ResultStore<String>> fields;

  FormData(Map<String, String> initialValues)
      : fields = Map.fromIterables(
          initialValues.keys, // field keys
          initialValues.values.map((initialValue) =>
              ResultStore(initialValue)), // wrap initial with ResultStore
        );

  void invalidField(String fieldName) {
    fields[fieldName].updateValue((current) => throw current);
  }

  void validField(String fieldName) {
    fields[fieldName].fixError((error) => error);
  }
}

class FormFieldView extends StatelessWidget with BuildResultListenable<String> {
  final String fieldName;
  final ResultStore<String> fieldStore;

  const FormFieldView({Key key, this.fieldName, this.fieldStore})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(fieldName),
        buildStore(fieldStore),
      ],
    );
  }

  @override
  Widget buildData(BuildContext context, String data) {
    return Text(data);
  }

  @override
  Widget buildError(BuildContext context, Object error) {
    final errorColor = Theme.of(context).errorColor;

    final badData = error as String;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Icon(Icons.error_outline, color: errorColor),
        ),
        Text(badData, style: TextStyle(color: errorColor)),
      ],
    );
  }
}
