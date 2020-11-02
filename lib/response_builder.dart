library response_builder;

import 'package:flutter/foundation.dart';
import 'package:response_builder/src/builders/build_mixins.dart';
import 'package:response_builder/src/builders/with_empty_data.dart';
import 'package:response_builder/src/result_listenable.dart';

/// Key types
///
/// * Data Source
///   * [Request] - Listenable data source for 3-state asynchronous data
///   * [ResultListenable] and [ResultNotifier] - Listenable data source for 2-state synchronized data
/// * Build Mixins
///   * [BuildAsyncResult] - Mixin that builds asynchronous data from [Future], [Stream] or [Request]
///   * [BuildResultListenable] - Mixin that builds 2-state synchronous result from [ResultListenable]
///   * [BuildValueListenable] - Mixin that builds [ValueListenable], in a library compatible wat
///   * [WithEmptyData] - Mixin that handles empty value, can be use any of the build mixin above
///
export 'src/builders/default_build_actions.dart';
export 'src/builders/build_mixins.dart';
export 'src/builders/build_with_builder.dart';
export 'src/builders/with_empty_data.dart';
export 'src/request.dart';
export 'src/result_listenable.dart';
