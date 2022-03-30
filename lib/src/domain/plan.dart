import 'package:paylike_flutter_engine/src/domain/payment.dart';
import 'package:paylike_money/paylike_money.dart';

import '../validation/can_be_validated.dart';

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
class PlanInterval implements JSONSerializable {
  /// Defines the frequency, see [PlanIntervalOptions] for more information
  final PlanIntervalOptions unit;

  /// Optional, it is the number of executions overall for
  /// this given plan
  int? value;
  PlanInterval({required this.unit, this.value});

  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = {
      'unit': unit.name,
    };
    if (value != null) {
      json = {...json, 'value': value};
    }
    return json;
  }
}

/// Describes a repeat pattern in a payment plan
class PaymentPlanRepeat implements JSONSerializable {
  /// Optional and used to define the time of the first execution.
  DateTime? first;

  /// Defines the repeat pattern for the plan
  PlanInterval interval;

  PaymentPlanRepeat({required this.interval, this.first});

  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = {'interval': interval.toJSON()};
    if (first != null) {
      json = {...json, 'first': first?.toUtc().toIso8601String()};
    }
    return json;
  }
}

/// Defines a payment plan
///
/// Note that you are required to define at least one repeat or scheduled element
///
/// [More information on how plans work](https://github.com/paylike/api-reference/blob/main/payments/index.md#payment-plans)
class PaymentPlan implements CanBeValidated, JSONSerializable {
  /// Amount used for the payment plan
  PaymentAmount? amount;

  /// Defines the repeat interval for the plan
  ///
  /// You can also set different amounts in the payment plan
  /// if you already know them
  PaymentPlanRepeat? repeat;

  /// Defines a scheduled payment at a given date
  DateTime? scheduled;
  PaymentPlan({
    this.amount,
    this.repeat,
    this.scheduled,
  });

  @override
  void validate() {
    if (scheduled == null && repeat == null) {
      throw InvalidPaymentBodyException(
          'Plan needs either repeat or scheduled');
    }
  }

  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = {};
    if (amount != null) {
      json['amount'] = amount?.toJSONBody();
    }
    if (repeat != null) {
      json['repeat'] = repeat?.toJSON();
    }
    if (scheduled != null) {
      json['scheduled'] = scheduled?.toUtc().toIso8601String();
    }
    return json;
  }
}

/// Describes unplanned payment creations
///
/// [More info](https://github.com/paylike/api-reference/blob/main/payments/index.md#unplanned)
/// about how unplanned payments work
class UnplannedPayment implements CanBeValidated, JSONSerializable {
  /// Initiated by the customer (from your application)
  bool? merchant;

  /// Initiated by the merchant (or off-site customer)
  bool? customer;
  UnplannedPayment({this.merchant, this.customer});

  @override
  void validate() {
    if (merchant == null && customer == null) {
      throw InvalidPaymentBodyException('Unplan field is invalid');
    }
  }

  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = {};
    if (merchant != null) {
      json['merchant'] = merchant;
    }
    if (customer != null) {
      json['customer'] = customer;
    }
    return json;
  }
}
