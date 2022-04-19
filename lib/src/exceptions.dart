/// Thrown if somethings is not found
class NotFoundException implements Exception {}

/// Thrown when the TDS flow cannot provide HTML
class TDSHTMLNotAvailableException implements Exception {}

/// Thrown when the engine did not get to the final part
/// of the flow and does not have a transaction ID to provide
class NoTransactionIdAvailableException implements Exception {}
