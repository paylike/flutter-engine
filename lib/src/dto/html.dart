/// Describes hints received via webview
class HTMLHintsDTO {
  /// Hints received during the webview TDS flow
  List<String> hints;
  HTMLHintsDTO.fromJSON(Map<String, dynamic> json)
      : hints = (json['hints'] as List<dynamic>).cast();
}
