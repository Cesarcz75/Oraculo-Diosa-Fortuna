import 'package:flutter_test/flutter_test.dart';
import 'package:oraculo_diosa_fortuna/core/models/laboratory_experiment.dart';
import 'package:oraculo_diosa_fortuna/core/services/laboratory_engine.dart';

void main() {
  final List<List<int>> history = List<List<int>>.generate(
    100,
    (int index) => <int>[
      1 + index % 4,
      7 + index % 4,
      13 + index % 4,
      20 + index % 4,
      27 + index % 4,
      34 + index % 4,
    ]..sort(),
  );

  test('evalúa estabilidad de un rango de suma', () {
    final LaboratoryExperiment experiment = LaboratoryExperiment(
      id: 'EXP-1',
      name: 'Suma',
      description: 'Prueba',
      ruleType: ExperimentRuleType.sumRange,
      minimum: 95,
      maximum: 120,
      createdAt: DateTime(2026),
    );

    const LaboratoryEngine engine = LaboratoryEngine();
    final ExperimentResult result = engine.evaluate(
      experiment: experiment,
      history: history,
    );

    expect(result.trainingSamples, 70);
    expect(result.validationSamples, 30);
    expect(result.stabilityScore, inInclusiveRange(0, 100));
  });

  test('rechaza históricos demasiado pequeños', () {
    final LaboratoryExperiment experiment = LaboratoryExperiment(
      id: 'EXP-2',
      name: 'Paridad',
      description: 'Prueba',
      ruleType: ExperimentRuleType.exactEvenCount,
      minimum: 3,
      maximum: 3,
      createdAt: DateTime(2026),
    );

    const LaboratoryEngine engine = LaboratoryEngine();

    expect(
      () => engine.evaluate(
        experiment: experiment,
        history: history.take(20).toList(),
      ),
      throwsArgumentError,
    );
  });
}
