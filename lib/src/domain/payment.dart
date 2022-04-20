import 'package:paylike_flutter_engine/src/domain/card.dart';
import 'package:paylike_flutter_engine/src/domain/plan.dart';
import 'package:paylike_money/paylike_money.dart';

import '../validation/can_be_validated.dart';

/// Describes a generic payment body
///
/// [CardPayment] and [ApplePayPayment] implements this interface
abstract class PaylikePaymentBody implements CanBeValidated, JSONSerializable {}

/// Thrown when the payment body is invalid
class InvalidPaymentBodyException implements Exception {
  final String reason;
  InvalidPaymentBodyException(this.reason) : super();
}

/// Base class for payments
class _BasePayment implements PaylikePaymentBody {
  /// Defines the amount of the payment
  PaymentAmount? amount;

  /// Optional. List of plans to apply
  final List<PaymentPlan> plans;

  /// Optional. Used for unplanned payments
  UnplannedPayment? unplanned;

  /// Custom fields to apply
  Map<String, dynamic> custom;
  _BasePayment(
      {required this.amount,
      this.plans = const [],
      this.custom = const {},
      this.unplanned});

  @override
  void validate() {
    if (plans.isEmpty && amount == null) {
      throw InvalidPaymentBodyException('Either plan or amount is required');
    }
    for (var plan in plans) {
      plan.validate();
      if (amount == null && plan.amount == null) {
        throw InvalidPaymentBodyException(
            'If no overall amount is provided every plan needs an amount');
      }
    }
    unplanned?.validate();
  }

  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = {};
    if (unplanned != null) {
      json['unplanned'] = unplanned?.toJSON();
    }
    if (amount != null) {
      json = {
        ...json,
        'amount': {
          'currency': amount?.currency.code,
          'value': amount?.value,
          'exponent': amount?.exponent,
        }
      };
    }
    if (plans.isNotEmpty) {
      json['plan'] = plans.map((plan) => plan.toJSON()).toList();
    }
    if (custom.isNotEmpty) {
      json['custom'] = custom;
    }
    return json;
  }
}

/// Describes a payment with debit / credit cards
class CardPayment extends _BasePayment {
  /// Tokenized card to use in the payment
  final PaylikeCard card;
  CardPayment({
    required this.card,
    PaymentAmount? amount,
    List<PaymentPlan> plans = const [],
    UnplannedPayment? unplanned,
    Map<String, dynamic> custom = const {},
  })  : assert(amount != null || plans.isNotEmpty),
        super(
            amount: amount, plans: plans, unplanned: unplanned, custom: custom);

  @override
  Map<String, dynamic> toJSON() {
    return {
      ...super.toJSON(),
      'card': card.toJSON(),
    };
  }
}

/// Describes a payment with Apple Pay
class ApplePayPayment extends _BasePayment {
  /// Apple token to use in the payment
  final String token;
  ApplePayPayment({required this.token, required PaymentAmount amount})
      : super(amount: amount);
}
