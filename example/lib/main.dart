// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:pay/pay.dart';
import 'package:paylike_flutter_engine/domain.dart';
import 'package:paylike_flutter_engine/exception.dart';
import 'package:paylike_flutter_engine/paylike_flutter_engine.dart';

void main() {
  runApp(const MyApp());
}

/// Register your own account [here](https://paylike.io)
var clientID = 'your-client-id';

const _paymentItems = [
  PaymentItem(
    label: 'Total',
    amount: '150',
    status: PaymentItemStatus.final_price,
  )
];

/// This is the same example application you would get with
/// flutter create -t app .
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paylike Engine Usage Demo',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const MyHomePage(title: 'Paylike Engine Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String transactionId = "";
  String error = "";
  final PaylikeEngine _engine = PaylikeEngine(clientId: clientID);

  /// Used for listening to engine events
  void _engineListener() {
    switch (_engine.current) {
      case EngineState.errorHappened:
        setState(() {
          error = _engine.error!.message;
        });
        break;
      case EngineState.done:
        setState(() {
          transactionId = _engine.transactionId;
        });
        break;
      default:
        break;
    }
  }

  /// Start listening to [PaylikeEngine] events in the initState
  @override
  void initState() {
    super.initState();
    _engine.addListener(_engineListener);
  }

  /// Stop listening to [PaylikeEngine] events in dispose
  ///
  /// Or stop listening when you don't need it anymore
  @override
  void dispose() {
    super.dispose();
    _engine.removeListener(_engineListener);
  }

  /// Important for the Engine usage example executing a single
  /// card transaction
  void _doPaymentFlow() async {
    _engine.restart();
    var card = await _engine.tokenize("410000000000000", "123");
    await _engine.createPayment(CardPayment(
      card: PaylikeCard(
          details: card, expiry: const Expiry(year: 2025, month: 3)),
      amount: Money.fromDouble('EUR', 20.5),
    ));
  }

  /// Important for the Engine usage example executing a single
  /// Apple Pay transaction
  ///
  /// NOTE: You need to have Apple Merchant set up. Check our documentation for
  /// further information!
  void onApplePayResult(Map<String, dynamic> paymentResult) async {
    _engine.restart();
    try {
      var token = paymentResult['token'];
      var tokenized = await _engine.tokenizeAppleToken(token);
      await _engine.createPaymentWithApple(ApplePayPayment(
          token: tokenized, amount: Money.fromDouble('HUF', 150.0)));
    } on PaylikeException catch (e) {
      print(e.cause);
      print(e.code);
      print(e.statusCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: SingleChildScrollView(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Press button to start payment flow',
            ),
            Text(
              'TransactionID: $transactionId',
            ),
            Text(
              'Error: $error',
            ),

            /// Notice that the widget is always rendered, but only visible
            /// when the webview flow is being done
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              PaylikeEngineWidget(engine: _engine, showEmptyState: true)
            ]),
            const SizedBox(height: 50),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ElevatedButton(
                  onPressed: _doPaymentFlow, child: const Text('Pay')),
            ]),
            ApplePayButton(
              paymentConfigurationAsset: 'payment_config.json',
              paymentItems: _paymentItems,
              style: ApplePayButtonStyle.black,
              type: ApplePayButtonType.buy,
              margin: const EdgeInsets.only(top: 15.0),
              onPaymentResult: onApplePayResult,
              loadingIndicator: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ],
        )),
      ),
    );
  }
}
