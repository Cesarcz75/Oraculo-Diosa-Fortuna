import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oraculo_diosa_fortuna/core/models/laboratory_experiment.dart';
import 'package:oraculo_diosa_fortuna/core/services/experiment_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('serializa y restaura un expediente completo', () {
    final LaboratoryExperiment experiment = LaboratoryExperiment(
      id: 'EXP-100',
      name: 'Ventana de suma',
      description: 'Prueba de persistencia',
      ruleType: ExperimentRuleType.sumRange,
      minimum: 103,
      maximum: 136,
      createdAt: DateTime(2026, 8, 2),
    );

    final ManagedExperiment original = ManagedExperiment(
      archived: true,
      result: ExperimentResult(
        experiment: experiment,
        trainingSamples: 70,
        validationSamples: 30,
        trainingMatches: 50,
        validationMatches: 20,
        trainingRate: 50 / 70,
        validationRate: 20 / 30,
        absoluteGap: (50 / 70 - 20 / 30).abs(),
        stabilityScore: 95.2,
      ),
    );

    final ManagedExperiment restored = ManagedExperiment.fromMap(
      Map<String, dynamic>.from(original.toMap()),
    );

    expect(restored.archived, isTrue);
    expect(restored.result.experiment.id, 'EXP-100');
    expect(restored.result.experiment.ruleType, ExperimentRuleType.sumRange);
    expect(restored.result.stabilityScore, 95.2);
  });

  test('guarda y recupera expedientes desde el repositorio', () async {
    const ExperimentRepository repository = ExperimentRepository();

    final ManagedExperiment experiment = ManagedExperiment(
      result: ExperimentResult(
        experiment: LaboratoryExperiment(
          id: 'EXP-200',
          name: 'Paridad',
          description: 'Prueba',
          ruleType: ExperimentRuleType.exactEvenCount,
          minimum: 3,
          maximum: 3,
          createdAt: DateTime(2026, 8, 2),
        ),
        trainingSamples: 70,
        validationSamples: 30,
        trainingMatches: 30,
        validationMatches: 13,
        trainingRate: 30 / 70,
        validationRate: 13 / 30,
        absoluteGap: (30 / 70 - 13 / 30).abs(),
        stabilityScore: 99.5,
      ),
    );

    await repository.save(<ManagedExperiment>[experiment]);
    final List<ManagedExperiment> restored = await repository.load();

    expect(restored, hasLength(1));
    expect(restored.single.result.experiment.id, 'EXP-200');
  });
}
