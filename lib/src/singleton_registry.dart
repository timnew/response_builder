import 'dart:async';

import 'package:flutter/foundation.dart';

typedef T SingletonFactory<T>();

class SingletonRegistry {
  static final Map<Type, dynamic> _instances = Map();
  static final Map<Type, SingletonFactory> _factories = Map();

  // ignore: sdk_version_never
  static Never _notInitialized<T>() {
    throw StateError("$T hasn't been initialized yet");
  }

  static T _tryCreate<T>() => _instances[T] = _factories[T]?.call() ?? _notInitialized<T>();

  static T get<T>() => _instances[T] ?? _tryCreate<T>();

  static Future<T> register<T>(FutureOr<T> value) async {
    final instance = value is Future<T> ? await value : value;

    _instances[T] = instance;

    return instance;
  }

  static void registerLazyFactory<T>(SingletonFactory<T> factory) {
    _factories[T] = ArgumentError.checkNotNull(factory, "factory");
  }

  static bool resetLazy<T>() {
    assert(_factories.containsKey(T), "Should only clear lazy instance");
    return _instances.remove(T) != null;
  }

  @visibleForTesting
  static void resetRegistry() {
    _factories.clear();
    _instances.clear();
  }
}
