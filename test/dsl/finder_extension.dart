import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

extension AssertionExtension on Finder {
  Finder should(
    Matcher matcher, {
    String reason,
    dynamic skip, // true or a String
  }) {
    expect(this, matcher, reason: reason, skip: skip);

    return this;
  }

  Finder shouldFindOne({
    String reason,
    dynamic skip, // true or a String
  }) =>
      should(findsOneWidget, reason: reason, skip: skip);

  Finder shouldFindNone({
    String reason,
    dynamic skip, // true or a String
  }) =>
      should(findsNothing, reason: reason, skip: skip);
}

extension FindChildExtension on Finder {
  Finder findChildBy(Finder finder) => find.descendant(of: this, matching: finder);

  Finder findChildText(String text, {bool skipOffstage = true}) =>
      find.descendant(of: this, matching: find.text(text, skipOffstage: skipOffstage));

  Finder findChildWithText<T extends Widget>(String text, {bool skipOffstage = true}) =>
      find.descendant(of: this, matching: find.widgetWithText(T, text, skipOffstage: skipOffstage));

  Finder findChildByKey(Key key, {bool skipOffstage = true}) =>
      find.descendant(of: this, matching: find.byKey(key, skipOffstage: skipOffstage));

  Finder findChild<T extends Widget>({bool skipOffstage = true}) =>
      find.descendant(of: this, matching: find.byType(T, skipOffstage: skipOffstage));

  Finder findChildIcon(IconData icon, {bool skipOffstage = true}) =>
      find.descendant(of: this, matching: find.byIcon(icon, skipOffstage: skipOffstage));

  Finder findChildWithIcon<T extends Widget>(IconData icon, {bool skipOffstage = true}) =>
      find.descendant(of: this, matching: find.widgetWithIcon(T, icon, skipOffstage: skipOffstage));

  Finder findChildByElementType<T extends Element>(Type type, {bool skipOffstage = true}) =>
      find.descendant(of: this, matching: find.byElementType(T, skipOffstage: skipOffstage));

  Finder findChildInstance(Widget widget, {bool skipOffstage = true}) =>
      find.descendant(of: this, matching: find.byWidget(widget, skipOffstage: skipOffstage));

  Finder findChildByPredicate(WidgetPredicate predicate, {String description, bool skipOffstage = true}) =>
      find.descendant(
        of: this,
        matching: find.byWidgetPredicate(predicate, description: description, skipOffstage: skipOffstage),
      );

  Finder findChildByTooltip(String message, {bool skipOffstage = true}) =>
      find.descendant(of: this, matching: find.byTooltip(message, skipOffstage: skipOffstage));

  Finder findChildByElementPredicate(ElementPredicate predicate, {String description, bool skipOffstage = true}) =>
      find.descendant(
        of: this,
        matching: find.byElementPredicate(predicate, description: description, skipOffstage: skipOffstage),
      );

  Finder findChildBySemanticsLabel(Pattern label, {bool skipOffstage = true}) =>
      find.descendant(of: this, matching: find.bySemanticsLabel(label, skipOffstage: skipOffstage));
}

extension FindAncestorExtension on Finder {
  Finder findAncestorBy(Finder finder) => find.ancestor(of: this, matching: finder);

  Finder findAncestorText(String text, {bool skipOffstage = true}) =>
      find.ancestor(of: this, matching: find.text(text, skipOffstage: skipOffstage));

  Finder findAncestorWithText<T extends Widget>(String text, {bool skipOffstage = true}) =>
      find.ancestor(of: this, matching: find.widgetWithText(T, text, skipOffstage: skipOffstage));

  Finder findAncestorByKey(Key key, {bool skipOffstage = true}) =>
      find.ancestor(of: this, matching: find.byKey(key, skipOffstage: skipOffstage));

  Finder findAncestor<T extends Widget>({bool skipOffstage = true}) =>
      find.ancestor(of: this, matching: find.byType(T, skipOffstage: skipOffstage));

  Finder findAncestorIcon(IconData icon, {bool skipOffstage = true}) =>
      find.ancestor(of: this, matching: find.byIcon(icon, skipOffstage: skipOffstage));

  Finder findAncestorWithIcon<T extends Widget>(IconData icon, {bool skipOffstage = true}) =>
      find.ancestor(of: this, matching: find.widgetWithIcon(T, icon, skipOffstage: skipOffstage));

  Finder findAncestorByElementType<T extends Element>(Type type, {bool skipOffstage = true}) =>
      find.ancestor(of: this, matching: find.byElementType(T, skipOffstage: skipOffstage));

  Finder findAncestorInstance(Widget widget, {bool skipOffstage = true}) =>
      find.ancestor(of: this, matching: find.byWidget(widget, skipOffstage: skipOffstage));

  Finder findAncestorByPredicate(WidgetPredicate predicate, {String description, bool skipOffstage = true}) =>
      find.ancestor(
        of: this,
        matching: find.byWidgetPredicate(predicate, description: description, skipOffstage: skipOffstage),
      );

  Finder findAncestorByTooltip(String message, {bool skipOffstage = true}) =>
      find.ancestor(of: this, matching: find.byTooltip(message, skipOffstage: skipOffstage));

  Finder findAncestorByElementPredicate(ElementPredicate predicate, {String description, bool skipOffstage = true}) =>
      find.ancestor(
        of: this,
        matching: find.byElementPredicate(predicate, description: description, skipOffstage: skipOffstage),
      );

  Finder findAncestorBySemanticsLabel(Pattern label, {bool skipOffstage = true}) =>
      find.ancestor(of: this, matching: find.bySemanticsLabel(label, skipOffstage: skipOffstage));
}
