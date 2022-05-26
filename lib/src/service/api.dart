import 'package:paylike_dart_client/dto.dart';
import 'package:paylike_dart_client/paylike_dart_client.dart';
import 'package:paylike_flutter_engine/src/domain/payment.dart';
import 'package:paylike_flutter_engine/src/dto/payment.dart';

import '../config/api.dart';
import '../domain/card.dart';

/// Handles API communication towards Paylike servers
class APIService {
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

  APIService({required this.clientId, required this.mode, this.log})
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

  /// Tokenizes the received apple pay token so it can be used
  /// throughut the payment process
  Future<String> tokenizeAppleToken(String token) async {
    var request = client.tokenizeApple(token).withDefaultRetry();
    var response = await request.execute();
    return response.token;
  }

  /// Used for apple pay payment creation
  Future<ApplePayPaymentResponseDTO> applePayPayment(
      ApplePayPayment applePayPayment,
      {List<String> hints = const [],
      Map<String, dynamic>? testConfig}) async {
    Map<String, dynamic> payment = {
      'integration': {
        'key': clientId,
      },
      'applepay': {'token': applePayPayment.token},
      'custom': applePayPayment.custom,
    };
    if (applePayPayment.amount != null) {
      payment['amount'] = applePayPayment.amount!.toJSONBody();
    }
    if (applePayPayment.plans.isNotEmpty) {
      payment['plan'] = applePayPayment.plans.map((cp) => cp.toJSON());
    }
    if (applePayPayment.unplanned != null) {
      payment['unplanned'] = applePayPayment.unplanned!.toJSON();
    }
    var resp = await _payment(payment, hints: hints, testConfig: testConfig);
    return ApplePayPaymentResponseDTO(resp, applePayPayment.token);
  }

  /// Responsible for executing a given payment
  Future<PaylikeClientResponse> _payment(Map<String, dynamic> payload,
      {List<String> hints = const [], Map<String, dynamic>? testConfig}) async {
    switch (mode) {
      case API_MODE.local:
        await Future.delayed(const Duration(seconds: 2));
        return PaylikeClientResponse(isHTML: false);

      case API_MODE.test:
        payload['test'] = {};
        if (testConfig != null) {
          payload['test'] = {...testConfig};
        }
        var resp = await client
            .paymentCreate(payment: payload, hints: hints)
            .withDefaultRetry()
            .execute();
        return resp;

      case API_MODE.live:
        var resp = await client
            .paymentCreate(payment: payload, hints: hints)
            .withDefaultRetry()
            .execute();
        return resp;
    }
  }

  /// Used for card payment creation
  Future<CardPaymentResponseDTO> cardPayment(CardPayment cardPayment,
      {List<String> hints = const [], Map<String, dynamic>? testConfig}) async {
    Map<String, dynamic> payment = {
      'integration': {
        'key': clientId,
      },
      'card': {
        'number': {
          'token': cardPayment.card.details.number,
        },
        'code': {
          'token': cardPayment.card.details.cvc,
        },
        'expiry': {
          'month': cardPayment.card.expiry.month,
          'year': cardPayment.card.expiry.year > 2000
              ? cardPayment.card.expiry.year
              : cardPayment.card.expiry.year + 2000
        },
      },
      'custom': cardPayment.custom,
    };
    if (cardPayment.amount != null) {
      payment['amount'] = cardPayment.amount!.toJSONBody();
    }
    if (cardPayment.plans.isNotEmpty) {
      payment['plan'] = cardPayment.plans.map((cp) => cp.toJSON());
    }
    if (cardPayment.unplanned != null) {
      payment['unplanned'] = cardPayment.unplanned!.toJSON();
    }
    var resp = await _payment(payment, hints: hints, testConfig: testConfig);
    return CardPaymentResponseDTO(resp, cardPayment.card.details);
  }
}
