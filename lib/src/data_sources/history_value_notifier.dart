import 'dart:collection';

import 'package:flutter/foundation.dart';

/// A [ValueListenable] implementation that kept the history of the changes
///
/// [capacity] specifies how many history the [HistoryValueNotifier] can remember
/// when history is full, [HistoryValueNotifier] drops the oldest memory
///
/// Unlike [ValueNotifier], [HistoryValueNotifier] is allowed to be created without initial value
/// [HistoryValueNotifier.value] returns `null` before any value is given
class HistoryValueNotifier<T> extends ChangeNotifier implements ValueListenable<T> {
  /// The number of the history changes that [HistoryValueNotifier] can keep
  final int capacity;
  final ListQueue<T> _queue;
  int _current;

  /// Create new instance of [HistoryValueNotifier]
  ///
  /// [capacity] specifies how many history the [HistoryValueNotifier] can remember, current value always occupies one from capacity
  /// [capacity] is required at least 2.
  ///
  /// [initialValue] is optional, which specify the initial value of the [HistoryValueNotifier]
  HistoryValueNotifier(this.capacity, {T initialValue})
      : assert(capacity > 1),
        // create queue with 1 more to avoid resizing
        _queue = ListQueue(capacity + 1) {
    if (initialValue != null) _queue.addLast(initialValue);
    _updateCurrent();
  }

  /// Current value holds by  [HistoryValueNotifier]
  /// Returns `null` if it holds nothing
  @override
  get value => _queue.length == 0 ? null : _queue.elementAt(_current);

  /// Set current value, kept it into change history, and then notify listeners
  set value(value) {
    putValue(value);
  }

  /// Set current value to [newValue]
  ///
  /// * [offRecord] controls whether record this change as part of the history, set as `false` by default
  /// * [silent] determines whether notifies the listeners for this change
  ///
  /// If [newValue] is same as current [value], no new record would be created, but listeners will be notified
  ///
  /// All the change history after the current would be purged if [undo] can been called.
  /// This would happen even if [offRecord] is set to `true`, otherwise it breaks data time-integrity
  T putValue(T newValue, {bool offRecord: false, bool silent: false}) {
    if (_queue.isEmpty || value != newValue) {
      if (_current < _queue.length - 1) _purgeHistory();
      if (offRecord && _queue.isNotEmpty) _queue.removeLast();
      if (_queue.length == capacity) _queue.removeFirst();
      _queue.addLast(newValue);
      _updateCurrent();
    }
    if (!silent) notifyListeners();

    return newValue;
  }

  void _updateCurrent() {
    _current = _queue.length - 1;
  }

  void _purgeHistory() {
    while (_current < _queue.length - 1) _queue.removeLast();
  }

  /// Keep current value but drops all change history records
  void truncateHistory() {
    final current = value;
    _queue.clear();
    _queue.addLast(current);
    _updateCurrent();
  }

  /// The change history recorded
  ///
  /// [historyLength] is guaranteed to be always less or equal to [capacity]
  int get historyLength => _queue.length;

  /// How many times of [undo] operations can be done
  int get undoCount => _current <= 0 ? 0 : _current;

  /// Whether [undo] can be done
  bool get canUndo => _current > 0;

  /// Revert current value to previous recorded in change history
  /// Notifies listeners
  /// Returns recovered value
  ///
  /// Returns current value is undo cannot be executed
  T undo() {
    if (!canUndo) return value;

    _current--;
    notifyListeners();
    return value;
  }

  /// Returns [undo] when [canUndo] returns 'true' otherwise returns 'null`
  ///
  /// It can be useful when if wish to disable the button if [canUndo] is `false`
  VoidCallback get undoCallback => canUndo ? undo : null;

  /// How many times of [redo] operations can be done
  int get redoCount => historyLength - _current - 1;

  /// Whether [redo] can be done
  bool get canRedo => redoCount > 0;

  /// Revert the the [undo] operation, change the value to next recorded value in change history
  /// Notifies listeners
  /// Returns recovered value
  ///
  /// Returns current value is redo cannot be executed
  T redo() {
    if (!canRedo) return value;

    _current++;
    notifyListeners();
    return value;
  }

  /// Returns [redo] when [canRedo] returns 'true' otherwise returns 'null`
  ///
  /// It can be useful when if wish to disable the button if [canRedo] is `false`
  VoidCallback get redoCallback => canRedo ? redo : null;
}
