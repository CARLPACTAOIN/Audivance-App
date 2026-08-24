import 'identity.dart';

abstract class StableIdGenerator {
  StableId nextId(String prefix);
}

class TimestampStableIdGenerator implements StableIdGenerator {
  TimestampStableIdGenerator({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  int _counter = 0;

  @override
  StableId nextId(String prefix) {
    _counter += 1;
    final timestamp = _now().toUtc().microsecondsSinceEpoch;
    return '$prefix-$timestamp-$_counter';
  }
}
