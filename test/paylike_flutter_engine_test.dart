import 'package:flutter_test/flutter_test.dart';

import 'package:paylike_flutter_engine/paylike_flutter_engine.dart';
import 'package:paylike_flutter_engine/src/config/api.dart';

void main() {
  test('adds one to input values', () {
    PaylikeEngine(clientId: 'xxxx', mode: API_MODE.local);
  });
}
