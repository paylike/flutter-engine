import 'package:flutter_test/flutter_test.dart';

import 'package:paylike_flutter_engine/paylike_flutter_engine.dart';
import 'package:paylike_flutter_engine/src/config/api.dart';

void main() {
  test('Tokenization should be successful', () async {
    var engine = PaylikeEngine(
        clientId: 'e393f9ec-b2f7-4f81-b455-ce45b02d355d',
        mode: API_MODE.test,
        log: (o) => {});

    var tokenized = await engine.tokenize('4100000000000000', '111');
    expect(tokenized.number, isNotEmpty);
    expect(tokenized.cvc, isNotEmpty);
  });
}
