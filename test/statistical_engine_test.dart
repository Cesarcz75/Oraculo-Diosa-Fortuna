import 'package:flutter_test/flutter_test.dart';
import 'package:oraculo_diosa_fortuna/core/services/statistical_engine.dart';
import 'package:oraculo_diosa_fortuna/core/models/model_config.dart';

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

    final ModelConfig config = ModelConfig.fromMap(<String, dynamic>{
      'modelName': 'Prueba',
      'modelVersion': '1.0.0',
      'engineName': 'Motor Fortuna',
      'engineVersion': '4.1.0',
      'rules': <String, dynamic>{
        'sum': <String, dynamic>{'enabled': true, 'weight': 2.0},
        'parity': <String, dynamic>{'enabled': true, 'weight': 0.8},
        'repeat': <String, dynamic>{'enabled': true, 'weight': 1.2},
        'numberFrequency': <String, dynamic>{'enabled': true, 'weight': 0.35},
        'pairLift': <String, dynamic>{'enabled': true, 'weight': 0.45},
        'consecutive': <String, dynamic>{'enabled': true, 'weight': 0.25},
        'lowHigh': <String, dynamic>{'enabled': true, 'weight': 0.08},
      },
    });
    final StatisticalEngine engine = StatisticalEngine(history, config);
    final result = engine.evaluate(
      <int>[4, 11, 15, 23, 24, 26],
      history.last,
    );

    expect(result.numbers.length, 6);
    expect(result.sum, 103);
    expect(result.breakdown.rules, isNotEmpty);
    expect(result.pitIndex, inInclusiveRange(0, 100));
    expect(
      result.contributions.values.fold<double>(
        0,
        (double total, double value) => total + value,
      ),
      closeTo(result.score, 0.000001),
    );
  });
}
