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

  /// Used for card payment creation
  Future<PaymentResponseDTO> cardPayment(CardPayment cardPayment,
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

    switch (mode) {
      case API_MODE.local:
        await Future.delayed(const Duration(seconds: 2));
        return PaymentResponseDTO.empty();

      case API_MODE.test:
        payment['test'] = {};
        if (testConfig != null) {
          payment['test'] = {...testConfig};
        }
        var resp = await client
            .paymentCreate(payment: payment, hints: hints)
            .withDefaultRetry()
            .execute();
        return PaymentResponseDTO(resp, cardPayment.card.details);

      case API_MODE.live:
        var resp = await client
            .paymentCreate(payment: payment, hints: hints)
            .withDefaultRetry()
            .execute();
        return PaymentResponseDTO(resp, cardPayment.card.details);
    }
  }
}
