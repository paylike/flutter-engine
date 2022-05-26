# Paylike's Flutter engine

This library includes the core elements required to implement a payment flow towards the Paylike API.

If you are looking for our high level component providing complete payment forms as well, [check here](https://github.com/paylike/flutter-payment-forms)

## Table of contents
* [API Reference](#api-reference)
* [PaylikeEngineWidget](#paylikeenginewidget) (Webview component)
  * [Box constraints](#box-constraints)
  * [Understanding TDS](#understanding-tds)
* [PaylikeEngine](#paylikeengine) (Underlying business logic service)
  * [Engine events](#engine-events)
* [Example application](#example-application)

## API Reference

For the library you can find the API reference [here](https://paylike.io#todo-link).

To get more familier with our server API you can find here the [official documentation](https:/github.com/paylike/api-reference).

## PaylikeEngineWidget

Webview component of the payment flow, able to render the webview required to execute the TDS challenge.

Simple usage:
```dart
    /// Renders the webview component automatically when the engine needs it, otherwise
    /// shows an empty state
    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      PaylikeEngineWidget(engine: _engine, showEmptyState: true)
    ])
```

For a realistic usage check out the example [here](./example/lib/main.dart).

#### Box constraints

Currently the webview component supports both unlimited and limited constraints.
This is achieved using SizedBoxes: 

```dart
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
```

If both constraints are set to infinity, the webview will be rendered in a scrollable view.

If only one of the constraints is set to infinity, the webview will be rendered in a fixed size.

Otherwise if the constraints are set to a specific value, the webview will be rendered in a fixed size.

#### Understanding TDS

TDS is required to execute the payment flow and it is a core part of accepting payments online. Every bank is required by financial laws to provide this methodology for their customers in order to achieve higher security measures.

Apple Pay is an exception from this as their system is already integrated with the TDS challenge.

<img src="https://i.imgur.com/51Ix8AP.jpg" style="max-width: 100%;"/>

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
  /// -----------------
  /// After the createPayment function is called the engine will update its state
  /// to render TDS webview challenge
  /// NOTE: Tokenized cards can be saved and reused later with the API
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
  /// --------
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

## Example application

In the [example directory](./example/lib/main.dart) you can find a simple example of how to use the library.

On both **iOS** and **Android** you need to [register a merchant account](https://paylike.io/sign-up) with Paylike before you can use the example application. Once you have created your account you can create a new client ID for yourself and use it in the sandbox environment.

**Android**

Enter your client ID to the example's main.dart, and you are good to go with running the application.

The minimum supported SDK is 19.

**iOS**

Apple Pay is only available for iOS devices. To be able to use this service you have to make a couple of modifications and [register a merchant identification with Apple](https://developer.apple.com/library/archive/ApplePay_Guide/Configuration.html).

Once you have acquired the merchant identification from Apple, you can request a payment processing certificate to be added to your account via our [support](https://paylike.io/contact). This is vital to use our API with Apple Pay.

When you received your Payment Processing Certificate, you need to add it to the [App Store Connect](https://appstoreconnect.apple.com/). Once you are done with this your merchant will be able to execute payments with Apple Pay.

In your Xcode you also have to set your own merchant identification when you are building the applicaiton. You can find this option under the Signing & Capabilities (by opening `example/ios/Runner.xcworkspace` and adding Apple Pay capability)

Now you should be ready to run the example and execute payments using Apple Pay.

The minimum supported iOS version is 11.
