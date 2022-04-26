library paylike_flutter_engine;

import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:paylike_dart_client/paylike_dart_client.dart';
import 'package:paylike_flutter_engine/src/config/api.dart';
import 'package:paylike_flutter_engine/src/exceptions.dart';
import 'package:paylike_flutter_engine/src/repository/hints.dart';
import 'package:paylike_flutter_engine/src/repository/single.dart';
import 'package:paylike_flutter_engine/src/service/api.dart';

import 'src/domain/card.dart';
import 'src/domain/payment.dart';

export 'src/domain/card.dart';
export 'src/domain/payment.dart';
export 'src/domain/plan.dart';
export 'package:paylike_currencies/paylike_currencies.dart';
export 'package:paylike_money/paylike_money.dart';
export 'package:pay/pay.dart';
export 'package:paylike_dart_client/paylike_dart_client.dart';

/// Describes the different states of the engine that can occour during
/// usage
enum EngineState {
  /// Indicates that the engine is ready to be used and waiting for input
  waitingForInput,

  /// Indicates that a webview challenge is required to complete
  /// the TDS flow, this is the first state when the webview has to be rendered
  webviewChallengeRequired,

  /// Indicates that the first step of the TDS flow is done and the challenge
  /// needs interraction from the end user to resolve
  webviewChallengeStarted,

  /// Indicates that all challenges are done
  /// NOTE: It does not mean that the challenge was successful
  done,

  /// Happens when the flow as not completed sucessfully
  errorHappened,
}

/// Describes the state of the current payment
enum PaymentState {
  /// State when engine is initialized
  initial,
}

/// Describes an error state of the engine
class PaylikeEngineError {
  /// Intended message for developers
  final String message;

  /// Present if the exception happened during an API request
  /// For more information see [PaylikeException]
  PaylikeException? apiException;

  /// Present if the exception happened internally in the engine
  Exception? internalException;
  PaylikeEngineError(
      {required this.message, this.apiException, this.internalException});
}

/// Executes payment flow
class PaylikeEngine extends ChangeNotifier {
  /// The current state of the Paylike Engine. See more at [EngineState]
  EngineState _current;

  /// Getter for the current engine state. See more at [EngineState]
  EngineState get current => _current;

  /// Returns if the webview should be active at the moment for the challenge or not
  bool get isWebviewActive =>
      _current != EngineState.waitingForInput &&
      _current != EngineState.done &&
      _current != EngineState.errorHappened;

  /// After a payment flow is completely done transaction id is stored here
  String? _transactionId;

  /// Returns the transaction ID if available otherwise
  /// throws an exception
  String get transactionId {
    if (_transactionId == null) {
      throw NoTransactionIdAvailableException();
    }
    return _transactionId as String;
  }

  /// Present if testConfig is provided at [createPayment]
  ///
  /// We need to store this because it potentially has to be provided
  /// multiple times during TDS
  Map<String, dynamic>? _testConfig;

  /// When the [_current] state is [EngineState.errorHappened]
  /// this is where you can access what happened
  PaylikeEngineError? error;

  /// Your client ID which can be found on our platform
  ///
  /// https://app.paylike.io/#/
  final String clientId;

  /// Indicates the API mode [API_MODE.test] by default which is the
  /// sandbox API
  ///
  /// More information at [API_MODE]
  final API_MODE mode;

  /// Service to execute api requests
  final APIService _apiService;

  /// Repository to store hints
  final HintsRepository _hintsRepository;

  /// Repository to store card for ongoing transaction
  final SingleRepository<PaylikeCard> _cardRepository;

  /// Repository to store TDS HTML Body
  final SingleRepository<String> _htmlRepository;

  /// Repository to store ongoing card payment
  final SingleRepository<CardPayment> _cardPaymentRepository;

  /// Repository to store ongoing apple payment
  final SingleRepository<ApplePayPayment> _applePaymentRepository;

  /// Logger function
  void Function(dynamic)? log;
  PaylikeEngine({
    required this.clientId,
    this.mode = API_MODE.test,
    this.log,
  })  : _apiService = APIService(clientId: clientId, mode: mode, log: log),
        _hintsRepository = HintsRepository(),
        _cardRepository = SingleRepository(),
        _htmlRepository = SingleRepository(),
        _cardPaymentRepository = SingleRepository(),
        _applePaymentRepository = SingleRepository(),
        _current = EngineState.waitingForInput;

  /// Used for card tokenization
  ///
  /// You need to tokenize the card number and CVC code before
  /// you can create a payment
  Future<CardTokenized> tokenize(String number, String cvc) {
    return _apiService.tokenizeCard(number, cvc);
  }

  /// Used for apple pay tokenization
  ///
  /// You need to tokenize your apple token before a payment can be started
  Future<String> tokenizeAppleToken(String token) {
    return _apiService.tokenizeAppleToken(token);
  }

  /// Used for creating a payment with an already tokenized apple pay token
  Future<void> createPaymentWithApple(ApplePayPayment payment,
      {Map<String, dynamic>? testConfig}) async {
    try {
      var paymentExecution =
          await _apiService.applePayPayment(payment, testConfig: testConfig);
      _testConfig = testConfig;
      _applePaymentRepository.set(payment);
      _hintsRepository.addHints(paymentExecution.resp.hints);
      if (paymentExecution.resp.isHTML) {
        _current = EngineState.webviewChallengeRequired;
        _htmlRepository.set(paymentExecution.resp.getHTMLBody());
      } else {
        _current = EngineState.done;
      }
    } on PaylikeException catch (e) {
      var message = 'An API Exception happened: ${e.code} ${e.cause}';
      log?.call(message);
      _current = EngineState.errorHappened;
      error = PaylikeEngineError(message: message, apiException: e);
    } catch (e) {
      var message = 'An internal exception happened: $e';
      log?.call(message);
      _current = EngineState.errorHappened;
      error = PaylikeEngineError(
          message: message, internalException: e as Exception);
    }
    notifyListeners();
  }

  /// Used for payment creation
  ///
  /// For more information on [testConfig] please check [here](https://github.com/paylike/api-reference/blob/main/payments/index.md#test)
  Future<void> createPayment(CardPayment payment,
      {Map<String, dynamic>? testConfig}) async {
    try {
      var paymentExecution =
          await _apiService.cardPayment(payment, testConfig: testConfig);
      _testConfig = testConfig;
      _cardPaymentRepository.set(payment);
      _cardRepository.set(payment.card);
      _hintsRepository.addHints(paymentExecution.resp.hints);
      if (paymentExecution.resp.isHTML) {
        _current = EngineState.webviewChallengeRequired;
        _htmlRepository.set(paymentExecution.resp.getHTMLBody());
      } else {
        _current = EngineState.done;
      }
    } on PaylikeException catch (e) {
      var message = 'An API Exception happened: ${e.code} ${e.cause}';
      log?.call(message);
      _current = EngineState.errorHappened;
      error = PaylikeEngineError(message: message, apiException: e);
    } catch (e) {
      var message = 'An internal exception happened: $e';
      log?.call(message);
      _current = EngineState.errorHappened;
      error = PaylikeEngineError(
          message: message, internalException: e as Exception);
    }
    notifyListeners();
  }

  /// Restarts the flow
  void restart() {
    _testConfig = null;
    _hintsRepository.reset();
    _cardRepository.reset();
    _htmlRepository.reset();
    _cardPaymentRepository.reset();
    _applePaymentRepository.reset();
    _current = EngineState.waitingForInput;
  }

  /// Used when the first step of the webview challenge is done
  /// esentially used when the [_current] is [EngineState.webviewChallengeStarted]
  void continuePayment() async {
    try {
      PaylikeClientResponse resp;
      if (_cardPaymentRepository.isAvailable) {
        var paymentExecution = await _apiService.cardPayment(
            _cardPaymentRepository.item,
            hints: _hintsRepository.hints,
            testConfig: _testConfig);
        _hintsRepository.addHints(paymentExecution.resp.hints);
        resp = paymentExecution.resp;
      } else if (_applePaymentRepository.isAvailable) {
        var paymentExecution = await _apiService.applePayPayment(
            _applePaymentRepository.item,
            hints: _hintsRepository.hints,
            testConfig: _testConfig);
        _hintsRepository.addHints(paymentExecution.resp.hints);
        resp = paymentExecution.resp;
      } else {
        throw Exception(
            "Engine does not have required information to continue payment");
      }
      if (resp.isHTML) {
        _htmlRepository.set(resp.getHTMLBody());
        if (_current == EngineState.webviewChallengeRequired) {
          _current = EngineState.webviewChallengeStarted;
        } else {
          throw Exception("Engine state invalid $_current");
        }
      } else {
        throw Exception("Payment challenge should provide HTML at this point");
      }
    } on PaylikeException catch (e) {
      var message = 'An API Exception happened: ${e.code} ${e.cause}';
      log?.call(message);
      _current = EngineState.errorHappened;
      error = PaylikeEngineError(message: message, apiException: e);
    } catch (e) {
      var message = 'An internal exception happened: $e';
      log?.call(message);
      _current = EngineState.errorHappened;
      error = PaylikeEngineError(
          message: message, internalException: e as Exception);
    }
    notifyListeners();
  }

  /// Used when the webview widget encounters an issue with the webview itself.
  /// In those scenarios we need a way to indicate to the engine that the flow
  /// ran into an error
  void setErrorState(Exception e) {
    _current = EngineState.errorHappened;
    error = PaylikeEngineError(
        message:
            "An error happened outside of the engine that stops the flow from continuing.",
        internalException: e);
    notifyListeners();
  }

  /// Used when the state is [EngineState.webviewChallengeStarted]
  /// This is naturally the last step of the webview challenge
  /// And gets called when the end user finsihed the challenge resolution
  void finishPayment() async {
    try {
      PaylikeClientResponse resp;
      if (_cardPaymentRepository.isAvailable) {
        var paymentExecution = await _apiService.cardPayment(
            _cardPaymentRepository.item,
            hints: _hintsRepository.hints,
            testConfig: _testConfig);
        resp = paymentExecution.resp;
      } else if (_applePaymentRepository.isAvailable) {
        var paymentExecution = await _apiService.applePayPayment(
            _applePaymentRepository.item,
            hints: _hintsRepository.hints,
            testConfig: _testConfig);
        resp = paymentExecution.resp;
      } else {
        throw Exception(
            "Engine does not have required information to continue payment");
      }
      if (resp.isHTML) {
        throw Exception("Should not be HTML anymore");
      } else {
        var transaction = (resp.paymentResponse as PaymentResponse).transaction;
        _transactionId = transaction.id;
        _current = EngineState.done;
      }
    } on PaylikeException catch (e) {
      var message = 'An API Exception happened: ${e.code} ${e.cause}';
      log?.call(message);
      _current = EngineState.errorHappened;
      error = PaylikeEngineError(message: message, apiException: e);
    } catch (e) {
      var message = 'An internal exception happened: $e';
      log?.call(message);
      _current = EngineState.errorHappened;
      error = PaylikeEngineError(
          message: message, internalException: e as Exception);
    }
    notifyListeners();
  }

  /// Needed after the first step of the webview challenge
  /// is done. Adds the acquired hints to the already existing ones
  void addHints(List<String> hints) {
    _hintsRepository.addHints(hints);
  }

  /// Returns the HTML body for the TDS flow
  /// Throws [TDSHTMLNotAvailableException] otherwise
  String getTDSHtml() {
    if (_htmlRepository.isAvailable) {
      return _htmlRepository.item;
    }
    throw TDSHTMLNotAvailableException();
  }
}
