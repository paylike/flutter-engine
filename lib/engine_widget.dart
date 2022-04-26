import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:paylike_flutter_engine/paylike_flutter_engine.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Describes hints received via webview
class HTMLHints {
  /// Hints received during the webview TDS flow
  List<String> hints;
  HTMLHints.fromJSON(Map<String, dynamic> json)
      : hints = (json['hints'] as List<dynamic>).cast();
}

/// Utility class to help the generation of a standard
/// html structure that can be loaded to the webview
class HTMLSupporter {
  /// <body></body> part of the HTML
  final String body;
  HTMLSupporter(this.body);

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
}

/// Used for webview rendering during the TDS challenge flow
class PaylikeEngineWidget extends StatefulWidget {
  /// PaylikeEngine instance to use
  final PaylikeEngine engine;

  /// If the [PaylikeEngine] instance is in a state
  /// in which it makes no sense to render any webviews ([EngineState.errorHappened] or [EngineState.waitingForInput])
  /// then the widget should show nothing or a text
  ///
  /// NOTE: Use [true] for production and [false] for development
  final bool showEmptyState;
  const PaylikeEngineWidget(
      {Key? key, required this.engine, this.showEmptyState = false})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _EngineWidgetState();
}

class _EngineWidgetState extends State<PaylikeEngineWidget> {
  final Completer<WebViewController> _webviewCtrl = Completer();

  /// Loads the HTML from the Engine
  void _loadEngineHTML() {
    _webviewCtrl.future.then((ctrl) => ctrl
            .loadHtmlString(
                HTMLSupporter(widget.engine.getTDSHtml()).generateHTML(),
                baseUrl: 'https:///b.paylike.io')
            .catchError((e) {
          debugPrint('Webview error $e');
        }));
  }

  /// Event listener for engine state changes
  void _reactForEvents() {
    debugPrint("State changed to ${widget.engine.current}");
    if (widget.engine.current == EngineState.webviewChallengeStarted) {
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

  /// Either renders [SizedBox.shrink] or an [Expanded] element
  /// to show a given text
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
    return LayoutBuilder(builder: (context, constraints) {
      var webviewContent = WebView(
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
                  widget.engine.setErrorState(
                      Exception('Hints cannot be empty after webview auth'));
                  return;
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
            widget.engine.setErrorState(e as Exception);
          });
        },
        onWebViewCreated: (controller) {
          _webviewCtrl.complete(controller);
          controller
              .loadHtmlString(
                  HTMLSupporter(widget.engine.getTDSHtml()).generateHTML(),
                  baseUrl: 'https:///b.paylike.io')
              .catchError((e) {
            widget.engine.setErrorState(e as Exception);
          });
        },
      );
      if (constraints.maxHeight == double.infinity &&
          constraints.maxWidth == double.infinity) {
        return Center(
            child: SizedBox(
                child: webviewContent,
                height: max(MediaQuery.of(context).size.width, 600),
                width: MediaQuery.of(context).size.width - 100));
      }
      return webviewContent;
    });
  }
}
