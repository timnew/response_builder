/// Contract of synchronous value updater
typedef T ValueUpdater<T>(T current);

/// Contract of asynchronous value updater
typedef Future<T> AsyncValueUpdater<T>(T current);

/// Contract of error fixer
typedef T ErrorFixer<T>(Object error);
