import 'package:paylike_flutter_engine/src/domain/card_tokenized.dart';
import 'package:paylike_flutter_engine/src/domain/plan.dart';
import 'package:paylike_money/paylike_money.dart';

/// Base class for payments
class _BasePayment {
  /// Defines the amount of the payment
  final PaymentAmount amount;

  /// Optional. List of plans to apply
  final List<PaymentPlan> plans;

  /// Custom fields to apply
  Map<String, dynamic> custom;
  _BasePayment(
      {required this.amount, this.plans = const [], this.custom = const {}});
}

/// Describes a payment with debit / credit cards
class CardPayment extends _BasePayment {
  /// Tokenized card to use in the payment
  final CardTokenized card;
  CardPayment({required this.card, required PaymentAmount amount})
      : super(amount: amount);
}

/// Describes a payment with Apple Pay
class ApplePayPayment extends _BasePayment {
  /// Apple token to use in the payment
  final String token;
  ApplePayPayment({required this.token, required PaymentAmount amount})
      : super(amount: amount);
}
