library paylike_flutter_engine;

import 'dart:convert';

import 'package:paylike_dart_client/paylike_dart_client.dart';
import 'package:paylike_flutter_engine/src/config/api.dart';
import 'package:paylike_flutter_engine/src/service/api.dart';

import 'src/domain/card.dart';
import 'src/domain/payment.dart';

/// Executes payment flow
class PaylikeEngine {
  /// Your client ID which can be found on our platform
  ///
  /// https://app.paylike.io/#/
  final String clientId;

  /// Indicates the API mode [API_MODE.test] by default which is the
  /// sandbox API
  ///
  /// More information at [API_MODE]
  final API_MODE mode;

  /// Service to execute api requests
  final PaylikeAPIService _service;

  /// Logger function
  void Function(dynamic)? log;
  PaylikeEngine({
    required this.clientId,
    this.mode = API_MODE.test,
    this.log,
  }) : _service = PaylikeAPIService(clientId: clientId, mode: mode, log: log);

  /// Used for card tokenization
  ///
  /// You need to tokenize the card number and CVC code before
  /// you can create a payment
  Future<CardTokenized> tokenize(String number, String cvc) {
    return _service.tokenizeCard(number, cvc);
  }

  /// Used for payment creation
  Future<void> createPayment(CardPayment payment) async {
    try {
      var resp = await _service.cardPayment(payment);
      print(resp.resp.hints);
      print(resp.resp.isHTML);
      print(resp.resp.getHTMLBody());
    } on PaylikeException catch (e) {
      // TODO: Here we could do additional error handling
      print(e.cause);
      print(e.code);
      print(e.statusCode);
    }
  }
}
