# Paylike's Flutter engine

This library includes the core elements required to implement a payment flow towards the Paylike API.

If you are looking for our high level component providing payment forms as well, [check here (TODO: Final link)](https://paylike.io)

## Table of contents
* [PaylikeEngine](#paylikeengine)
* [PaylikeEngineWidget](#paylikeenginewidget)

## PaylikeEngine

The core component of the payment flow.

Essentially designed to be event based to allow as much flexibility on the implementer side as possible.

Simple usage:
```dart
  var engine = PaylikeEngine(clientId: 'your-client-id');
```


## PaylikeEngineWidget

Webview component of the payment flow.

Simple usage:
```dart
// TODO: Widget example
  PaylikeEngineWidget(engine: engine)
```
