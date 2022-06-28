import 'package:flutter_test/flutter_test.dart';
import 'package:paylike_flutter_engine/domain.dart';

import 'package:paylike_flutter_engine/paylike_flutter_engine.dart';

void main() {
  var engine = PaylikeEngine(
      clientId: 'e393f9ec-b2f7-4f81-b455-ce45b02d355d',
      mode: API_MODE.test,
      log: (o) => {});
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
        amount: Money.fromDouble('EUR', 25));
    await engine.createPayment(cardPayment);
  });
}
