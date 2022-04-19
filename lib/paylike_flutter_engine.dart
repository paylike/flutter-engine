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

/// Describes the different states of the engine that can occour during
/// usage
enum EngineState {
  /// Indicates that the engine is ready to be used and waiting for input
  waitingForInput,

  /// Indicates that a webview challenge is required to complete
  /// the TDS flow
  webviewChallengeRequired,

  /// Indicated that a webview challenge is at the second part
  /// of the authentication flow
  webviewChallengeFinish,

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

/// Executes payment flow
class PaylikeEngine extends ChangeNotifier {
  /// The current state of the Paylike Engine. See more at [EngineState]
  EngineState _current;

  /// Getter for the current engine state. See more at [EngineState]
  EngineState get current => _current;

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
  final SingleRepository<Card> _cardRepository;

  /// Repository to store TDS HTML Body
  final SingleRepository<String> _htmlRepository;

  /// Repository to store ongoing payment
  final SingleRepository<CardPayment> _paymentRepository;

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
        _paymentRepository = SingleRepository(),
        _current = EngineState.waitingForInput;

  /// Used for card tokenization
  ///
  /// You need to tokenize the card number and CVC code before
  /// you can create a payment
  Future<CardTokenized> tokenize(String number, String cvc) {
    return _apiService.tokenizeCard(number, cvc);
  }

  /// Used for payment creation
  Future<void> createPayment(CardPayment payment) async {
    try {
      var paymentExecution = await _apiService.cardPayment(payment);
      _paymentRepository.set(payment);
      _cardRepository.set(payment.card);
      _hintsRepository.addHints(paymentExecution.resp.hints);
      if (paymentExecution.resp.isHTML) {
        _current = EngineState.webviewChallengeRequired;
        _htmlRepository.set(paymentExecution.resp.getHTMLBody());
      } else {
        _current = EngineState.done;
      }
      notifyListeners();
    } on PaylikeException catch (e) {
      // TODO: Here we could do additional error handling
      print(e.cause);
      print(e.code);
      print(e.statusCode);
    }
  }

  /// Used when the second step of the webview challenge is done
  void continuePayment() async {
    try {
      var paymentExecution = await _apiService
          .cardPayment(_paymentRepository.item, hints: _hintsRepository.hints);
      if (paymentExecution.resp.isHTML) {
        _current = EngineState.errorHappened;
        throw Exception("Should not be HTML");
      } else {
        var transaction =
            (paymentExecution.resp.paymentResponse as PaymentResponse)
                .transaction;
        _transactionId = transaction.id;
        _current = EngineState.done;
      }
      notifyListeners();
    } on PaylikeException catch (e) {
      // TODO: Here we could do additional error handling
      print(e.cause);
      print(e.code);
      print(e.statusCode);
    }
  }

  /// Used when the acquired hints in the first step are
  /// validated by the paylike backend and service is ready to show
  /// the last validation page for the user
  /// TODO: Probably this needs more information
  void finishWebviewChallenge() {
    _current = EngineState.webviewChallengeFinish;
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
