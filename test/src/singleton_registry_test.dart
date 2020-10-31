import 'package:flutter_test/flutter_test.dart';

import 'package:response_builder/response_builder.dart';

class TestSingleton {
  TestSingleton();
}

class AnotherSingleton {
  final int instanceId;

  AnotherSingleton() : instanceId = _currentInstanceId++;

  static int _currentInstanceId = 0;

  static Future<AnotherSingleton> createAsync() async {
    await Future.delayed(Duration(microseconds: 100));
    return AnotherSingleton();
  }
}

void main() {
  test("Register singleton", () async {
    SingletonRegistry.register(TestSingleton());

    final fetched = SingletonRegistry.get<TestSingleton>();

    expect(fetched, isA<TestSingleton>());
  });

  test("Register async created object", () async {
    await SingletonRegistry.register(AnotherSingleton.createAsync());

    final fetched = SingletonRegistry.get<AnotherSingleton>();

    expect(fetched, isA<AnotherSingleton>());
  });

  test("Register lazy created singleton", () {
    SingletonRegistry.registerLazyFactory(() => TestSingleton());

    final fetched = SingletonRegistry.get<TestSingleton>();

    expect(fetched, isA<TestSingleton>());
  });

  test("Reset lazy created singleton", () {
    SingletonRegistry.registerLazyFactory(() => AnotherSingleton());

    final first = SingletonRegistry.get<AnotherSingleton>();
    SingletonRegistry.resetLazy<AnotherSingleton>();
    final second = SingletonRegistry.get<AnotherSingleton>();
    expect(second.instanceId, isNot(equals(first.instanceId)));
  });

  test("Cannot reset non-lazy singleton", () {
    SingletonRegistry.register(AnotherSingleton());

    expect(() => SingletonRegistry.resetLazy<AnotherSingleton>(), throwsAssertionError);
  });

  test("throw error when access not registered type", () {
    expect(() => SingletonRegistry.get<TestSingleton>(), throwsStateError);
  });

  tearDown(() {
    SingletonRegistry.resetRegistry();
  });
}
