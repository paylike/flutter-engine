/// Describes a class that has a validate function
abstract class CanBeValidated {
  void validate();
}

/// Describes a class that can get JSON Serialized
abstract class JSONSerializable {
  Map<String, dynamic> toJSON();
}
