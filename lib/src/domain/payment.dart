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

/// Base class that describes options for card and apple pay payments
class BasePayment implements PaylikePaymentBody {
  /// Defines the amount of the payment
  PaymentAmount? amount;

  /// Optional. List of plans to apply
  final List<PaymentPlan> plans;

  /// Optional. Used for unplanned payments
  UnplannedPayment? unplanned;

  /// Custom fields to apply
  Map<String, dynamic> custom;
  BasePayment(
      {this.amount,
      this.plans = const [],
      this.custom = const {},
      this.unplanned})
      : assert(amount != null || plans.isNotEmpty);

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
          'currency': amount?.currency,
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
class CardPayment extends BasePayment {
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

  /// Used for creating a card payment from an already defined [BasePayment]
  CardPayment.fromBasePayment(this.card, BasePayment options)
      : super(
            amount: options.amount,
            plans: options.plans,
            unplanned: options.unplanned,
            custom: options.custom);

  @override
  Map<String, dynamic> toJSON() {
    return {
      ...super.toJSON(),
      'card': card.toJSON(),
    };
  }
}

/// Describes a payment with Apple Pay
class ApplePayPayment extends BasePayment {
  /// Apple token to use in the payment
  final String token;
  ApplePayPayment({
    required this.token,
    PaymentAmount? amount,
    List<PaymentPlan> plans = const [],
    UnplannedPayment? unplanned,
    Map<String, dynamic> custom = const {},
  })  : assert(amount != null || plans.isNotEmpty),
        super(
            amount: amount, plans: plans, unplanned: unplanned, custom: custom);

  /// Used for creating an apple pay payment from an already defined [BasePayment]
  ApplePayPayment.fromBasePayment(this.token, BasePayment options)
      : super(
            amount: options.amount,
            plans: options.plans,
            unplanned: options.unplanned,
            custom: options.custom);
}
