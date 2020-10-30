import 'package:flutter/src/foundation/change_notifier.dart';

class ValueListenableTester<T> {
  final ValueListenable<T> listenable;

  final List<T> pastValues = List();

  int get changeCount => pastValues.length;

  bool get hasChanges => changeCount > 0;

  T get lastChange => pastValues.last;

  T popLastChange() => pastValues.removeLast();

  void clear() => pastValues.clear();

  ValueListenableTester(this.listenable) {
    listenable.addListener(onChange);
  }

  void onChange() {
    pastValues.add(listenable.value);
  }

  void detachListenable() {
    listenable.removeListener(onChange);
  }
}
