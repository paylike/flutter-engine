import 'package:paylike_money/paylike_money.dart';

/// Available options for a plan interval
enum PlanIntervalOptions {
  /// Plan will be executed every day
  day,

  /// Plan will be executed every week
  week,

  /// Plan will be executed every month
  month,

  /// Plan will be executed every year
  year
}

/// Describes an interval for a plan
class PlanInterval {
  /// Defines the frequency, see [PlanIntervalOptions] for more information
  final PlanIntervalOptions unit;

  /// Optional, it is the number of executions overall for
  /// this given plan
  int? value;
  PlanInterval({required this.unit, this.value});
}

/// Describes a repeat pattern in a payment plan
class PaymentPlanRepeat {
  /// Optional and used to define the time of the first execution.
  DateTime? first;

  /// Defines the repeat pattern for the plan
  PlanInterval interval;

  PaymentPlanRepeat({required this.interval, this.first});
}

/// Defines a payment plan
///
/// Note that you are required to define at least one repeat or scheduled element
///
/// [More information on how plans work](https://github.com/paylike/api-reference/blob/main/payments/index.md#payment-plans)
class PaymentPlan {
  /// Amount used for the payment plan
  final PaymentAmount amount;

  /// Defines the repeat interval for the plan
  ///
  /// You can also set different amounts in the payment plan
  /// if you already know them
  PaymentPlanRepeat? repeat;

  /// Defines a scheduled payment at a given date
  DateTime? scheduled;
  PaymentPlan({
    required this.amount,
    this.repeat,
    this.scheduled,
  });
}

/// Describes unplanned payment creations
///
/// [More info](https://github.com/paylike/api-reference/blob/main/payments/index.md#unplanned)
/// about how unplanned payments work
class UnplannedPayment {
  /// Initiated by the customer (from your application)
  bool? merchant;

  /// Initiated by the merchant (or off-site customer)
  bool? customer;
  UnplannedPayment({this.merchant, this.customer});
}
