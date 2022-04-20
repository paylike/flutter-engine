import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:paylike_flutter_engine/paylike_flutter_engine.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// @nodoc
/// TODO: Not sure if this should be public
class HTMLHints {
  List<String> hints;
  HTMLHints.fromJSON(Map<String, dynamic> json)
      : hints = (json['hints'] as List<dynamic>).cast();
}

/// @nodoc
/// TODO: Not sure if this should be public
class HTMLSupporter {
  final String body;
  HTMLSupporter(this.body);
  String generateHTML() {
    return '''
<!DOCTYPE html><html>
<head>
</head>
$body
</html>
''';
  }
}

class PaylikeEngineWidget extends StatefulWidget {
  final PaylikeEngine engine;
  final bool showEmptyState;
  const PaylikeEngineWidget(
      {Key? key, required this.engine, this.showEmptyState = false})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _EngineWidgetState();
}

class _EngineWidgetState extends State<PaylikeEngineWidget> {
  final Completer<WebViewController> _webviewCtrl = Completer();

  void _loadEngineHTML() {
    _webviewCtrl.future.then((ctrl) => ctrl
            .loadHtmlString(
                HTMLSupporter(widget.engine.getTDSHtml()).generateHTML(),
                baseUrl: 'https:///b.paylike.io')
            .catchError((e) {
          debugPrint('Webview error $e');
        }));
  }

  void _reactForEvents() {
    debugPrint("State changed to ${widget.engine.current}");
    if (widget.engine.current == EngineState.webviewChallengeStarted ||
        widget.engine.current == EngineState.webviewChallengeFinish) {
      _loadEngineHTML();
    } else {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    widget.engine.addListener(_reactForEvents);
  }

  @override
  void dispose() {
    super.dispose();
    widget.engine.removeListener(_reactForEvents);
  }

  Widget _textOrEmptyState(String text) {
    if (widget.showEmptyState) {
      return const SizedBox.shrink();
    }
    return Expanded(child: Row(children: [Text(text)]));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.engine.current == EngineState.waitingForInput) {
      return _textOrEmptyState("Paylike engine is waiting for input");
    }
    if (widget.engine.current == EngineState.errorHappened) {
      return _textOrEmptyState("Something went wrong during payment");
    }
    if (widget.engine.current == EngineState.done) {
      return _textOrEmptyState(
          "Transaction done, id: ${widget.engine.transactionId}");
    }
    return Expanded(
        child: WebView(
      debuggingEnabled: true,
      navigationDelegate: (request) async {
        return NavigationDecision.navigate;
      },
      javascriptMode: JavascriptMode.unrestricted,
      javascriptChannels: <JavascriptChannel>{
        JavascriptChannel(
            name: 'MessageInvoker',
            onMessageReceived: (s) {
              var htmlParsedResponse =
                  HTMLHints.fromJSON(jsonDecode(s.message));
              if (htmlParsedResponse.hints.isEmpty) {
                throw Exception('Hints cannot be empty after webview auth');
              }
              widget.engine.addHints(htmlParsedResponse.hints);
              if (widget.engine.current ==
                  EngineState.webviewChallengeRequired) {
                widget.engine.continuePayment();
              } else if (widget.engine.current ==
                  EngineState.webviewChallengeStarted) {
                widget.engine.finishPayment();
              }
            })
      },
      onProgress: (progress) {
        () async {
          var controller = await _webviewCtrl.future;
          await controller.runJavascript('''
                          if (!window.paylike_listener) {
                            window.paylike_listener = (e) => {
                              MessageInvoker.postMessage(JSON.stringify(e.data)).then(() => console.log('posted')).catch((e) => console.log(e));
                            };
                            window.addEventListener("message", window.paylike_listener);
                          }
                        ''');
        }()
            .catchError((e) {
          if (e is PlatformException) {
            debugPrint(e.message);
            debugPrint(e.stacktrace);
          }
        });
      },
      onWebViewCreated: (controller) {
        debugPrint('Controller created');
        _webviewCtrl.complete(controller);
        controller
            .loadHtmlString(
                HTMLSupporter(widget.engine.getTDSHtml()).generateHTML(),
                baseUrl: 'https:///b.paylike.io')
            .catchError((e) {
          debugPrint('Webview error $e');
        });
      },
    ));
  }
}
