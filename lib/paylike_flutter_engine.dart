library paylike_flutter_engine;

import 'package:paylike_flutter_engine/src/config/api.dart';
import 'package:paylike_flutter_engine/src/service/api.dart';

import 'src/domain/card_tokenized.dart';

/// Executes payment flow
class PaylikeEngine {
  /// Your client ID which can be found on our platform
  ///
  /// https://app.paylike.io/#/
  final String clientId;

  /// Indicates the API mode
  ///
  /// More information at [API_MODE]
  final API_MODE mode;

  /// Service to execute api requests
  final PaylikeAPIService _service;
  PaylikeEngine({
    required this.clientId,
    required this.mode,
  }) : _service = PaylikeAPIService(clientId: clientId, mode: mode);

  Future<CardTokenized> tokenize(String number, String cvc) {
    return _service.tokenizeCard(number, cvc);
  }

  constructPayment() {}
}
