import 'package:flutter_test/flutter_test.dart';
import 'package:oraculo_diosa_fortuna/core/services/statistical_engine.dart';

void main() {
  test('el motor evalúa una combinación válida', () {
    final List<List<int>> history = List<List<int>>.generate(
      30,
      (int index) => <int>[
        1 + index % 4,
        7 + index % 4,
        13 + index % 4,
        20 + index % 4,
        27 + index % 4,
        34 + index % 4,
      ]..sort(),
    );

    final StatisticalEngine engine = StatisticalEngine(history);
    final result = engine.evaluate(
      <int>[4, 11, 15, 23, 24, 26],
      history.last,
    );

    expect(result.numbers.length, 6);
    expect(result.sum, 103);
  });
}
