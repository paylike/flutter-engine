import 'dart:core';

/// Stores hints throughut the progress
class HintsRepository {
  /// [transactionID, hint]
  List<String> _hints = [];

  /// Getter for hints
  List<String> get hints => _hints;

  /// Adds new hints to a transactionID
  void addHints(List<String> hints) {
    var newList = [..._hints, ...hints];
    _hints = newList.toSet().toList();
  }

  /// Resets the list
  void reset() {
    _hints = [];
  }
}
