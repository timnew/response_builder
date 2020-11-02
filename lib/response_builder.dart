/// Key types
///
/// * Data Source
///   * [Request] - Listenable data source for 3-state asynchronous data
///   * [ResultListenable] and [ResultNotifier] - Listenable data source for 2-state synchronized data
/// * Build Protocols
///   * [BuildAsyncSnapshot] - This protocol enable [BuildAsyncSnapshotActions] to consume 3-state data from [Future], [Stream] or [Request]
///   * [BuildResult] - This protocol enable enables [BuildResultListenable] to consume 2-state data from [ResultListenable]
///   * [BuildValue] - This protocol enable enables [BuildValueListenable] to consume value from [ValueListenable]
///   * [WithEmptyValue] - Protocol implement [BuildValue.buildValue] contract, which enables building actions to handle empty value
/// * Build Actions
///   * [BuildAsyncSnapshotActions] - Actions run on [BuildAsyncSnapshot] protocol to consume 3-state `AsyncResult` data from [Future], [Stream] or [Request],
///   * [BuildResultListenable] - Actions run on [BuildResult] protocol, to consume 2-state `Result` from [ResultListenable]
///   * [BuildValueListenable] - Actions run on [BuildValue] protocol, to consume value from [ValueListenable]
library response_builder;

export 'src/data_sources.dart';
export 'src/builders.dart';
