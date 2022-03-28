import 'package:paylike_dart_client/paylike_dart_client.dart';

import '../domain/card.dart';

/// Describes a response from the underlying client library
class PaymentResponseDTO {
  PaylikeClientResponse resp;
  CardTokenized card;
  PaymentResponseDTO(this.resp, this.card);
  PaymentResponseDTO.empty()
      : resp = PaylikeClientResponse(isHTML: false),
        card = const CardTokenized(number: "", cvc: "");
}
