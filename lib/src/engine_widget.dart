import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:paylike_flutter_engine/paylike_flutter_engine.dart';
import 'package:paylike_flutter_engine/src/service/html.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'dto/html.dart';

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
  Completer<WebViewController> _webviewCtrl = Completer();

  /// Loads the HTML from the Engine
  Future<void> _loadEngineHTML() =>
      _webviewCtrl.future.then((ctrl) => ctrl.runJavascript('''
  var iframe = document.getElementById('iamframe');
  iframe = iframe.contentWindow || ( iframe.contentDocument.document || iframe.contentDocument);
  iframe.document.open();
  window.iframeContent = `${base64.encode(utf8.encode(HTMLService(widget.engine.getTDSHtml()).generateHTML()))}`;
  iframe.document.write(window.b64Decoder(window.iframeContent));
  iframe.document.close();
''')).catchError((e) {
        widget.engine.log?.call(e);
        widget.engine.setErrorState(Exception('Could not load TDS HTML'));
      });

  /// Loads the necessary scripts to the webview window
  Future<void> _populateWindowObject() =>
      _webviewCtrl.future.then((ctrl) => ctrl.runJavascript('''
if (!window.paylike_listener) {
  window.paylike_listener = (e) => {
    if (!MessageInvoker || !MessageInvoker.postMessage) {
      setTimeout(() => {
        window.paylike_listener(e);
      }, 100);
      return;
    }
    MessageInvoker.postMessage(JSON.stringify(e.data));
  };
  window.addEventListener("message", window.paylike_listener);
}
if (!window.b64Decoder) {
  window.b64Decoder = (str) =>
    decodeURIComponent(
      atob(str)
        .split("")
        .map((c) => "%" + ("00" + c.charCodeAt(0).toString(16)).slice(-2))
        .join("")
    );
}
''')).catchError((e) {
        widget.engine.log?.call(e);
        widget.engine
            .setErrorState(Exception('Could not populate window object'));
      });

  /// Event listener for engine state changes
  void _reactForEvents() {
    widget.engine.log
        ?.call("[DEBUG] State changed to ${widget.engine.current}");
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
                if (s.message == '"ready"') {
                  _loadEngineHTML();
                  return;
                }
                var htmlParsedResponse =
                    HTMLHintsDTO.fromJSON(jsonDecode(s.message));
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
          _populateWindowObject();
        },
        onWebViewCreated: (controller) async {
          try {
            _webviewCtrl = Completer()..complete(controller);
            await _populateWindowObject();
            await controller.loadHtmlString(
                HTMLService(widget.engine.getTDSHtml()).generateWhatcher(),
                baseUrl: 'https:///b.paylike.io');
          } on Exception catch (e) {
            widget.engine.setErrorState(e);
          }
        },
      );
      if (constraints.maxHeight == double.infinity &&
          constraints.maxWidth == double.infinity) {
        return Center(
            child: SingleChildScrollView(
                child: SizedBox(
                    child: webviewContent,
                    height: 400,
                    width: MediaQuery.of(context).size.width - 150)));
      }
      if (constraints.maxHeight == double.infinity) {
        return SizedBox(height: 400, child: Expanded(child: webviewContent));
      }
      if (constraints.maxWidth == double.infinity) {
        return SizedBox(
            width: MediaQuery.of(context).size.width - 150,
            child: Expanded(child: webviewContent));
      }
      return SizedBox.expand(child: webviewContent);
    });
  }
}
