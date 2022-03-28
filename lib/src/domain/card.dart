import 'package:paylike_flutter_engine/src/validation/can_be_validated.dart';

/// Describes a card that already has tokenzied fields
class CardTokenized {
  final String number;
  final String cvc;
  const CardTokenized({required this.number, required this.cvc});
}

/// Describes a card that already has a tokenized number and CVC
class Card implements JSONSerializable {
  final CardTokenized details;
  final Expiry expiry;
  Card({required this.details, required this.expiry});

  @override
  Map<String, dynamic> toJSON() {
    return {
      'number': details.number,
      'code': details.cvc,
      'expiry': {
        'month': expiry.month,
        'year': expiry.year,
      }
    };
  }
}

/// Describes expiry information for cards
class Expiry {
  final int month;
  final int year;
  const Expiry({required this.year, required this.month});
}
