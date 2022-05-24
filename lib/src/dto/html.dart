/// Describes hints received via webview
class HTMLHints {
  /// Hints received during the webview TDS flow
  List<String> hints;
  HTMLHints.fromJSON(Map<String, dynamic> json)
      : hints = (json['hints'] as List<dynamic>).cast();
}
