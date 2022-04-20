import 'package:flutter/material.dart';
import 'package:paylike_flutter_engine/engine_widget.dart';
import 'package:paylike_flutter_engine/paylike_flutter_engine.dart';

void main() {
  runApp(const MyApp());
}

/// This is the same example application you would get with
/// flutter create -t app .
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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
  final PaylikeEngine _engine =
      PaylikeEngine(clientId: 'e393f9ec-b2f7-4f81-b455-ce45b02d355d');

  /// Used for listening to engine events
  void _engineListener() {
    if (_engine.current == EngineState.done) {
      setState(() {
        transactionId = _engine.transactionId;
      });
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

  /// This is the function important for the Engine usage example
  void _doPaymentFlow() async {
    var card = await _engine.tokenize("410000000000000", "123");
    await _engine.createPayment(CardPayment(
      card: PaylikeCard(
          details: card, expiry: const Expiry(year: 2025, month: 3)),
      amount:
          Money.fromDouble(PaylikeCurrencies().byCode(CurrencyCode.EUR), 20.5),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Welcome to our example application',
            ),
            Text(
              'Press button to start payment flow',
              style: Theme.of(context).textTheme.headline4,
            ),

            /// Notice that the widget is always rendered, but only visible
            /// when the webview flow is being done
            PaylikeEngineWidget(engine: _engine, showEmptyState: false),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _doPaymentFlow,
        tooltip: 'PaymentFlow',
        child: const Icon(Icons.add_shopping_cart_sharp),
      ),
    );
  }
}
