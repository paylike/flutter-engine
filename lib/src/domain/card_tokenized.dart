/// Describes a card that already has tokenzied fields
class CardTokenized {
  final String number;
  final String cvc;
  const CardTokenized({required this.number, required this.cvc});
}
