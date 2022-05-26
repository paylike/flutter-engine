import 'package:paylike_dart_client/dto.dart';

import '../domain/card.dart';

/// Describes a response from the underlying client library extended
/// with the tokenized card data
class CardPaymentResponseDTO {
  PaylikeClientResponse resp;
  CardTokenized card;
  CardPaymentResponseDTO(this.resp, this.card);
  CardPaymentResponseDTO.empty()
      : resp = PaylikeClientResponse(isHTML: false),
        card = const CardTokenized(number: "", cvc: "");
}

/// Describes a response from the underlying client library extended
/// with the tokenized apple pay token
class ApplePayPaymentResponseDTO {
  PaylikeClientResponse resp;
  String token;
  ApplePayPaymentResponseDTO(this.resp, this.token);
  ApplePayPaymentResponseDTO.empty()
      : resp = PaylikeClientResponse(isHTML: false),
        token = '';
}
