import 'package:flutter_test/flutter_test.dart';
import 'package:trymeyourpartner/shared/errors/report_error.dart';

void main() {
  test('recovered errors reach the error sink with where they happened', () {
    final seen = <String>[];
    final previous = errorSink;
    errorSink = (e, st, {required where}) => seen.add('$where: $e');
    addTearDown(() => errorSink = previous);

    try {
      throw StateError('presence lookup failed');
    } catch (e, st) {
      reportError(e, st, where: 'presence_indicator');
    }

    expect(seen, ['presence_indicator: Bad state: presence lookup failed']);
  });
}
