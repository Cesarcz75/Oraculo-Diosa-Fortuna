import 'package:flutter_test/flutter_test.dart';
import 'package:oraculo_diosa_fortuna/core/models/model_config.dart';
import 'package:oraculo_diosa_fortuna/core/models/model_comparison.dart';
import 'package:oraculo_diosa_fortuna/core/services/model_comparison_engine.dart';

void main() {
  const RuleConfig sumA = RuleConfig(
    key: 'sum',
    id: 'PIT-001',
    label: 'Suma',
    category: 'Distribución',
    description: 'Prueba',
    status: 'Oficial',
    evidenceLevel: 5,
    author: 'PIT',
    introducedVersion: '1.0.0',
    enabled: true,
    weight: 1.0,
  );

  test('detecta cambio de peso y activación', () {
    const ModelConfig first = ModelConfig(
      modelName: 'PIT',
      modelVersion: '1.0.0',
      engineName: 'Fortuna',
      engineVersion: '4.2.0',
      rules: <RuleConfig>[
        sumA,
        RuleConfig(
          key: 'parity',
          id: 'PIT-002',
          label: 'Paridad',
          category: 'Composición',
          description: 'Prueba',
          status: 'Validada',
          evidenceLevel: 4,
          author: 'PIT',
          introducedVersion: '1.0.0',
          enabled: false,
          weight: 0.8,
        ),
      ],
      disclaimer: '',
    );

    final ModelConfig second = first.copyWith(
      modelVersion: '1.0.1',
      rules: <RuleConfig>[
        sumA.copyWith(weight: 1.5),
        first.rule('parity').copyWith(enabled: true),
      ],
    );

    const ModelComparisonEngine engine = ModelComparisonEngine();
    final ModelComparisonReport report = engine.compare(
      first: first,
      second: second,
    );

    expect(report.changedRules, 2);
    expect(
      report.rules.firstWhere((rule) => rule.key == 'sum').changeType,
      RuleChangeType.weightChanged,
    );
    expect(
      report.rules.firstWhere((rule) => rule.key == 'parity').changeType,
      RuleChangeType.activated,
    );
  });

  test('calcula índice PIT dentro de rango', () {
    const ModelConfig model = ModelConfig(
      modelName: 'PIT',
      modelVersion: '1.0.0',
      engineName: 'Fortuna',
      engineVersion: '4.2.0',
      rules: <RuleConfig>[sumA],
      disclaimer: '',
    );

    const ModelComparisonEngine engine = ModelComparisonEngine();
    final ModelHealthSnapshot health = engine.health(model);

    expect(health.pitIndex, inInclusiveRange(0, 100));
    expect(health.activeRules, 1);
  });
}
