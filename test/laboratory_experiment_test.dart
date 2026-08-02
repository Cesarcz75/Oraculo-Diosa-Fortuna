import 'package:flutter_test/flutter_test.dart';
import 'package:oraculo_diosa_fortuna/core/models/laboratory_experiment.dart';

void main() {
  test('duplica los parámetros de un experimento', () {
    final LaboratoryExperiment original = LaboratoryExperiment(
      id: 'EXP-1',
      name: 'Original',
      description: 'Descripción',
      ruleType: ExperimentRuleType.sumRange,
      minimum: 103,
      maximum: 136,
      createdAt: DateTime(2026),
    );

    final LaboratoryExperiment copy = original.copyWith(
      id: 'EXP-2',
      name: 'Copia',
      createdAt: DateTime(2026, 8, 2),
    );

    expect(copy.id, 'EXP-2');
    expect(copy.name, 'Copia');
    expect(copy.minimum, original.minimum);
    expect(copy.maximum, original.maximum);
    expect(copy.ruleType, original.ruleType);
  });

  test('archiva y restaura un experimento administrado', () {
    final LaboratoryExperiment experiment = LaboratoryExperiment(
      id: 'EXP-1',
      name: 'Prueba',
      description: 'Descripción',
      ruleType: ExperimentRuleType.exactEvenCount,
      minimum: 3,
      maximum: 3,
      createdAt: DateTime(2026),
    );

    final ExperimentResult result = ExperimentResult(
      experiment: experiment,
      trainingSamples: 70,
      validationSamples: 30,
      trainingMatches: 40,
      validationMatches: 17,
      trainingRate: 40 / 70,
      validationRate: 17 / 30,
      absoluteGap: (40 / 70 - 17 / 30).abs(),
      stabilityScore: 99.5,
    );

    final ManagedExperiment managed = ManagedExperiment(result: result);
    final ManagedExperiment archived = managed.copyWith(archived: true);
    final ManagedExperiment restored = archived.copyWith(archived: false);

    expect(managed.archived, isFalse);
    expect(archived.archived, isTrue);
    expect(restored.archived, isFalse);
  });
}
