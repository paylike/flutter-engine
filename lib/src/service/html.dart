/// Utility class to help the generation of a standard
/// html structure that can be loaded to the webview
class HTMLService {
  /// <body></body> part of the HTML
  final String body;
  HTMLService(this.body);

  /// Generates the correct body of the HTML
  String generateHTML() {
    return '''
<!DOCTYPE html><html>
<head>
</head>
$body
</html>
''';
  }

  String generateWhatcher() {
    return '''
<!DOCTYPE html><html>
<head>
<style>
#iframe-div {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  display: flex;
  justify-content: center;
}
#iamframe {
  width: 100%;
}
</style>
</head>
<body>
<div id="iframe-div">
  <iframe id="iamframe">
  </iframe>
</div>
<script>
  (function() {
    function waitForWindowListener() {
      if (!window.paylike_listener || !MessageInvoker) {
        setTimeout(waitForWindowListener, 100);
        return;
      }
      window.postMessage("ready");
    }
    waitForWindowListener();
  })();
</script>
</body>
</html>
''';
  }
}
