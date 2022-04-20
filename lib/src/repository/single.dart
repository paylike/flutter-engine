import 'package:paylike_flutter_engine/src/exceptions.dart';

/// Stores a single item
class SingleRepository<T> {
  T? _single;
  T get item {
    if (_single != null) {
      return _single as T;
    }
    throw NotFoundException();
  }

  /// Returns if the item is available
  bool get isAvailable => _single != null;

  /// Sets the single
  void set(T single) {
    _single = single;
  }

  /// Resets the current state
  void reset() {
    _single = null;
  }
}
