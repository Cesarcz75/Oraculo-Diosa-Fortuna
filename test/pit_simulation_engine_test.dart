import 'package:flutter_test/flutter_test.dart';
import 'package:oraculo_diosa_fortuna/core/models/model_config.dart';
import 'package:oraculo_diosa_fortuna/core/services/pit_simulation_engine.dart';
import 'package:oraculo_diosa_fortuna/core/services/statistical_engine.dart';

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

  const ModelConfig official = ModelConfig(
    modelName: 'Modelo PIT',
    modelVersion: '1.0.0',
    engineName: 'Motor Fortuna',
    engineVersion: '5.3.0',
    rules: <RuleConfig>[
      RuleConfig(
        key: 'sum',
        id: 'PIT-001',
        label: 'Suma histórica',
        category: 'Distribución',
        description: 'Prueba',
        status: 'Oficial',
        evidenceLevel: 5,
        author: 'PIT',
        introducedVersion: '1.0.0',
        enabled: true,
        weight: 1.0,
      ),
      RuleConfig(
        key: 'parity',
        id: 'PIT-002',
        label: 'Paridad',
        category: 'Composición',
        description: 'Prueba',
        status: 'Oficial',
        evidenceLevel: 4,
        author: 'PIT',
        introducedVersion: '1.0.0',
        enabled: true,
        weight: 1.0,
      ),
    ],
    disclaimer: '',
  );

  test('recalcula el ranking actual con un modelo temporal', () {
    final StatisticalEngine officialEngine =
        StatisticalEngine(history, official);
    final officialRanking = <List<int>>[
      <int>[1, 7, 13, 19, 25, 31],
      <int>[2, 8, 14, 20, 26, 32],
      <int>[3, 9, 15, 21, 27, 33],
    ]
        .map(
          (List<int> item) =>
              officialEngine.evaluate(item, history.last),
        )
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    final ModelConfig experimental = official.copyWith(
      modelVersion: '1.0.1',
      rules: <RuleConfig>[
        official.rules[0].copyWith(weight: 2.5),
        official.rules[1].copyWith(weight: 0.2),
      ],
    );

    final result = const PitSimulationEngine().simulate(
      officialModel: official,
      experimentalModel: experimental,
      modelHistory: const <ModelConfig>[],
      drawHistory: history,
      officialRanking: officialRanking,
    );

    expect(result.experimentalRanking, hasLength(3));
    expect(result.officialModel.modelVersion, '1.0.0');
    expect(result.experimentalModel.modelVersion, '1.0.1');
    expect(result.experimentalMetrics.overallHealth, inInclusiveRange(0, 100));
    expect(result.experimentalAudit.score, inInclusiveRange(0, 100));
  });

  test('rechaza históricos demasiado pequeños', () {
    expect(
      () => const PitSimulationEngine().simulate(
        officialModel: official,
        experimentalModel: official,
        modelHistory: const <ModelConfig>[],
        drawHistory: history.take(10).toList(),
        officialRanking: const [],
      ),
      throwsArgumentError,
    );
  });
}
