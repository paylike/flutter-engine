import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:paylike_flutter_engine/src/domain/card.dart';
import 'package:paylike_flutter_engine/src/domain/payment.dart';
import 'package:paylike_flutter_engine/src/domain/plan.dart';
import 'package:paylike_money/paylike_money.dart';

void main() {
  var testAmount =
      Money.fromDouble(PaylikeCurrencies().byCode(CurrencyCode.EUR), 30.0);

  var testCard = Card(
      details: const CardTokenized(number: 'foo', cvc: 'bar'),
      expiry: const Expiry(month: 12, year: 25));
  test('Serialization should work as expected', () {
    var cardPayment = CardPayment(card: testCard, amount: testAmount);
    var expected = jsonEncode(jsonDecode('''
    {
      "amount":{
        "currency":"EUR",
        "value":300,
        "exponent":1
      },
      "card":{
        "number":"foo",
        "code":"bar",
        "expiry":{
          "month":12,
          "year":25
        }
      }
    }
    '''));
    expect(jsonEncode(cardPayment.toJSON()), expected);

    cardPayment = CardPayment(
        card: testCard,
        plans: [
          PaymentPlan(
              amount: testAmount,
              scheduled: DateTime.fromMillisecondsSinceEpoch(1648644940894)),
          PaymentPlan(
              amount: testAmount,
              repeat: PaymentPlanRepeat(
                  first: DateTime.fromMillisecondsSinceEpoch(1648644940894),
                  interval:
                      PlanInterval(unit: PlanIntervalOptions.month, value: 2)))
        ],
        unplanned: UnplannedPayment(merchant: true, customer: true),
        custom: {'foo': 'bar'});

    expected = jsonEncode(jsonDecode('''
    {
      "unplanned":{
        "merchant":true,
        "customer":true
      },
      "plan":[
        {
          "amount":{
            "currency":"EUR",
            "value":300,
            "exponent":1
          },
          "scheduled":"2022-03-30T12:55:40.894Z"
        },
        {
          "amount":{
            "currency":"EUR",
            "value":300,
            "exponent":1
          },
          "repeat":{
            "interval":{
              "unit":"month",
              "value":2
            },
            "first":"2022-03-30T12:55:40.894Z"
          }
        }
      ],
      "custom":{
        "foo":"bar"
      },
      "card":{
        "number":"foo",
        "code":"bar",
        "expiry":{
          "month":12,
          "year":25
        }
      }
    }
    '''));
    expect(jsonEncode(cardPayment.toJSON()), expected);
  });

  test("Card payment should be validated correctly", () {
    var cardPayment = CardPayment(card: testCard);
    expect(() => cardPayment.validate(),
        throwsA(isA<InvalidPaymentBodyException>()));

    cardPayment = CardPayment(
        card: testCard, plans: [PaymentPlan(scheduled: DateTime.now())]);
    expect(() => cardPayment.validate(),
        throwsA(isA<InvalidPaymentBodyException>()));

    cardPayment = CardPayment(card: testCard, plans: [
      PaymentPlan(scheduled: DateTime.now()),
      PaymentPlan(amount: testAmount, scheduled: DateTime.now())
    ]);
    expect(() => cardPayment.validate(),
        throwsA(isA<InvalidPaymentBodyException>()));

    cardPayment = CardPayment(card: testCard, amount: testAmount);
    cardPayment.validate();

    cardPayment = CardPayment(card: testCard, amount: testAmount, plans: [
      PaymentPlan(scheduled: DateTime.now()),
    ]);
    cardPayment.validate();

    cardPayment = CardPayment(card: testCard, plans: [
      PaymentPlan(scheduled: DateTime.now(), amount: testAmount),
    ]);
    cardPayment.validate();

    cardPayment = CardPayment(card: testCard, plans: [
      PaymentPlan(scheduled: DateTime.now(), amount: testAmount),
      PaymentPlan(
          repeat: PaymentPlanRepeat(
              interval: PlanInterval(unit: PlanIntervalOptions.week)),
          amount: testAmount),
    ]);
    cardPayment.validate();
  });
}
