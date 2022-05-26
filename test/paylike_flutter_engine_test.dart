import 'package:flutter_test/flutter_test.dart';
import 'package:paylike_flutter_engine/domain.dart';

import 'package:paylike_flutter_engine/paylike_flutter_engine.dart';
import 'package:paylike_flutter_engine/src/config/api.dart';

void main() {
  var engine = PaylikeEngine(
      clientId: 'your-client-id', mode: API_MODE.test, log: (o) => {});
  test('Tokenization should be successful', () async {
    var tokenized = await engine.tokenize('4100000000000000', '111');
    expect(tokenized.number, isNotEmpty);
    expect(tokenized.cvc, isNotEmpty);
  });

  test('Should be able to create payments', () async {
    var tokenized = await engine.tokenize('4100000000000000', '111');
    var cardPayment = CardPayment(
        card: PaylikeCard(
            details: tokenized, expiry: const Expiry(month: 12, year: 2025)),
        amount:
            Money.fromDouble(PaylikeCurrencies().byCode(CurrencyCode.EUR), 25));
    await engine.createPayment(cardPayment);
  });
}
