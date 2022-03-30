import 'package:paylike_dart_client/paylike_dart_client.dart';
import 'package:paylike_flutter_engine/src/dto/payment.dart';
import 'package:paylike_money/paylike_money.dart';

import '../config/api.dart';
import '../domain/card.dart';

/// Handles API communication towards Paylike servers
class PaylikeAPIService {
  /// Your client id
  ///
  /// You can find your own client id [here](https:///app.paylike.io/)
  /// after you register a new account at Paylike
  final String clientId;

  /// Describes how the API should operate
  ///
  /// Ideally you would use [API_MODE.test] for sandbox testing
  /// and [API_MODE.live] for production
  /// Check [API_MODE] for more information
  final API_MODE mode;

  /// API Client for communication
  ///
  /// You can find examples on how to create an instance of
  /// an API client in the example application.
  final PaylikeClient client;

  /// Logger function
  void Function(dynamic)? log;

  PaylikeAPIService({required this.clientId, required this.mode, this.log})
      : client = PaylikeClient().setLog((d) {}) {
    if (log != null) {
      client.setLog(log as void Function(dynamic));
    }
  }

  /// Used for card tokenization
  Future<CardTokenized> tokenizeCard(String number, String cvc) async {
    String cardNumberTokenized = "";
    String cardCvcTokenized = "";
    numberFuture() async {
      var request =
          client.tokenize(TokenizeTypes.PCN, number).withDefaultRetry();
      var response = await request.execute();
      cardNumberTokenized = response.token;
    }

    cvcFuture() async {
      var request = client.tokenize(TokenizeTypes.PCSC, cvc).withDefaultRetry();
      var response = await request.execute();
      cardCvcTokenized = response.token;
    }

    await Future.wait([numberFuture(), cvcFuture()]);
    return CardTokenized(number: cardNumberTokenized, cvc: cardCvcTokenized);
  }

  /// Used for payment creation
  Future<PaymentResponseDTO> capture({
    required String number,
    required Expiry expiry,
    required String cvc,
    PaymentAmount? amount,
    required Map<String, dynamic> custom,
    List<String> hints = const [],
    CardTokenized? card,
    List<Map<String, dynamic>>? plan,
    Map<String, dynamic>? unplanned,
    Map<String, dynamic>? test,
  }) async {
    var tokenizedCard = card ?? await tokenizeCard(number, cvc);
    Map<String, dynamic> payment = {
      'integration': {
        'key': clientId,
      },
      'card': {
        'number': {
          'token': tokenizedCard.number,
        },
        'code': {
          'token': tokenizedCard.cvc,
        },
        'expiry': {'month': expiry.month, 'year': expiry.year},
      },
      'custom': custom,
    };

    /// From API Reference: Body needs either an amount, an unplanned or a plan field, but it can have both as well
    var isBodyCorrect = false;
    if (plan != null) {
      isBodyCorrect = true;
    }
    if (unplanned != null) {
      isBodyCorrect = true;
      payment['unplanned'] = unplanned;
    }
    if (amount != null) {
      isBodyCorrect = true;
      payment['amount'] = amount.toJSONBody();
    }
    if (!isBodyCorrect) {
      throw Exception('Either amount, plan or unplanned has to be provided');
    }
    switch (mode) {
      case API_MODE.local:
        await Future.delayed(const Duration(seconds: 2));
        return PaymentResponseDTO.empty();

      case API_MODE.test:
        payment['test'] = {...?test};
        var resp = await client
            .paymentCreate(payment: payment, hints: hints)
            .withDefaultRetry()
            .execute();
        return PaymentResponseDTO(resp, tokenizedCard);

      case API_MODE.live:
        var resp = await client
            .paymentCreate(payment: payment, hints: hints)
            .withDefaultRetry()
            .execute();
        return PaymentResponseDTO(resp, tokenizedCard);
    }
  }
}
