import 'package:flutter_test/flutter_test.dart';
import 'package:oraculo_diosa_fortuna/core/services/score_engine.dart';

void main() {
  test('suma contribuciones y calcula influencias', () {
    const ScoreEngine engine = ScoreEngine();
    final breakdown = engine.build(<String, double>{
      'Suma': -4,
      'Paridad': -2,
      'Pares': 1,
    });

    expect(breakdown.total, -5);
    expect(breakdown.rules, hasLength(3));
    expect(
      breakdown.rules.fold<double>(
        0,
        (double total, item) => total + item.influence,
      ),
      closeTo(1, 0.000001),
    );
    expect(breakdown.pitIndex, inInclusiveRange(0, 100));
  });

  test('el índice PIT aumenta cuando el aporte está más equilibrado', () {
    const ScoreEngine engine = ScoreEngine();
    final concentrated = engine.build(<String, double>{
      'A': 9,
      'B': 1,
      'C': 0.1,
    });
    final balanced = engine.build(<String, double>{
      'A': 3,
      'B': 3,
      'C': 3,
    });

    expect(balanced.pitIndex, greaterThan(concentrated.pitIndex));
    expect(balanced.pitIndex, closeTo(100, 0.000001));
  });
}
