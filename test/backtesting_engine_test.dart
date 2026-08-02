import 'package:flutter_test/flutter_test.dart';
import 'package:oraculo_diosa_fortuna/core/models/laboratory_experiment.dart';
import 'package:oraculo_diosa_fortuna/core/services/backtesting_engine.dart';

void main() {
  final List<List<int>> history = List<List<int>>.generate(
    120,
    (int index) => <int>[
      1 + index % 3,
      7 + index % 3,
      13 + index % 3,
      19 + index % 3,
      25 + index % 3,
      31 + index % 3,
    ]..sort(),
  );

  test('genera ventanas móviles y métricas válidas', () {
    final LaboratoryExperiment experiment = LaboratoryExperiment(
      id: 'BT-1',
      name: 'Suma',
      description: 'Prueba',
      ruleType: ExperimentRuleType.sumRange,
      minimum: 90,
      maximum: 110,
      createdAt: DateTime(2026),
    );

    const BacktestingEngine engine = BacktestingEngine();
    final report = engine.run(
      experiment: experiment,
      history: history,
      windowSize: 40,
      step: 20,
    );

    expect(report.windows, hasLength(5));
    expect(report.averageRate, inInclusiveRange(0, 1));
    expect(report.standardDeviation, greaterThanOrEqualTo(0));
    expect(report.consistencyScore, inInclusiveRange(0, 100));
  });

  test('rechaza ventanas mayores que el histórico', () {
    final LaboratoryExperiment experiment = LaboratoryExperiment(
      id: 'BT-2',
      name: 'Paridad',
      description: 'Prueba',
      ruleType: ExperimentRuleType.exactEvenCount,
      minimum: 3,
      maximum: 3,
      createdAt: DateTime(2026),
    );

    const BacktestingEngine engine = BacktestingEngine();

    expect(
      () => engine.run(
        experiment: experiment,
        history: history,
        windowSize: 200,
        step: 20,
      ),
      throwsArgumentError,
    );
  });
}
