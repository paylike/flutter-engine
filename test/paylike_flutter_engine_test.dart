import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:paylike_flutter_engine/paylike_flutter_engine.dart';
import 'package:paylike_flutter_engine/src/config/api.dart';
import 'package:paylike_flutter_engine/src/domain/card.dart';
import 'package:paylike_flutter_engine/src/domain/payment.dart';
import 'package:paylike_money/paylike_money.dart';

void main() {
  test('Serialization', () {
    var cardPayment = CardPayment(
        card: Card(
            details: const CardTokenized(number: 'foo', cvc: 'bar'),
            expiry: const Expiry(month: 12, year: 25)),
        amount: Money.fromDouble(
            PaylikeCurrencies().byCode(CurrencyCode.EUR), 30.0));
    print(jsonEncode(cardPayment.toJSON()));
  });

  test('Tokenization should be successful', () async {
    var engine = PaylikeEngine(
        clientId: 'e393f9ec-b2f7-4f81-b455-ce45b02d355d', mode: API_MODE.test);

    var tokenized = await engine.tokenize('4100000000000000', '111');
    expect(tokenized.number, isNotEmpty);
    expect(tokenized.cvc, isNotEmpty);
  });
}
