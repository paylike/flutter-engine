# Paylike's Flutter engine

This library includes the core elements required to implement a payment flow towards the Paylike API.

If you are looking for our high level component providing payment forms as well, [check here (TODO: Final link)](https://paylike.io)

## Table of contents
* [API Reference](https://paylike.io#todo-link)
* [PaylikeEngineWidget](#paylikeenginewidget) (Webview component)
* [PaylikeEngine](#paylikeengine) (Underlying business logic service)
  * [Engine events](#engine-events)

## PaylikeEngineWidget

Webview component of the payment flow.

Simple usage:
```dart
// TODO: Widget example
  PaylikeEngineWidget(engine: engine)
```


## PaylikeEngine

The core component of the payment flow.

Essentially designed to be event based to allow as much flexibility as possible on the implementer side.

Simple usage:
```dart
import 'package:paylike_flutter_engine/paylike_flutter_engine.dart';

void main() async {
  var engine = PaylikeEngine(clientId: 'your-client-id');

  engine.addListener(() {
    if (engine.current == PaylikeEngineStates.webviewChallengeRequired) {
      /// show webview and continue solving the iframe challenge
    }
    /// etc...
  });

  /// Simple card usage
  /// After the createPayment function is called the engine will update its state
  /// to render TDS webview challenge
  {
    var tokenizedCard = await engine.tokenize('4100000000000000', '000');
    await _engine.createPayment(CardPayment(
        card: PaylikeCard(
            details: card, expiry: const Expiry(year: 2025, month: 3)),
        amount:
            Money.fromDouble(PaylikeCurrencies().byCode(CurrencyCode.EUR), 20.5),
      ));
  }


  /// Apple Pay
  /// Apple Pay supports TDS by default so if everything is in order you should never see
  /// engine state updates here that requires a webview to render, therefore you can only listen to
  /// 3 events: waitingForInput, errorHappened, done
  {
    var applePayToken = ''; /// Acquire token using ApplePay API or use our higher level SDK: flutter-payment-forms
    var tokenizedApplePay = await engine.tokenizeApplePay(applePayToken);
    await _engine.createPaymentWithApple(ApplePayPayment(
        token: tokenized,
        amount: Money.fromDouble(
            PaylikeCurrencies().byCode(CurrencyCode.HUF), 150.0)));
  }
}
```

For further information on how the engine can be integrated into the application, please see the source of [PaylikeEngineWidget](./lib/paylike_flutter_engine/paylike_engine_widget.dart) and the library's API Reference.

#### Engine events

The library exposes an enum called EngineStates which describes the following states:

* `waitingForInput` - Indicates that the engine is ready to be used and waiting for input
* `webviewChallengeRequired` -  Indicates that a webview challenge is required to complete the TDS flow, this is the first state when the webview has to be rendered
* `webviewChallengeStarted` - Indicates that the first step of the TDS flow is done and the challenge needs interraction from the end user to resolve
* `done` - Indicates that all challenges are done successfully and the payment is being processed
* `errorHappened` - Happens when the flow could not be completed successfully

Learn more about this in the [API Reference](https://paylike.io#todo-link)
