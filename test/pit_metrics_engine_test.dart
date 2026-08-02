import 'package:flutter_test/flutter_test.dart';
import 'package:oraculo_diosa_fortuna/core/models/model_config.dart';
import 'package:oraculo_diosa_fortuna/core/services/pit_metrics_engine.dart';

void main() {
  const ModelConfig model = ModelConfig(
    modelName: 'Modelo Oficial PIT',
    modelVersion: '1.0.0',
    engineName: 'Motor Fortuna',
    engineVersion: '5.1.0',
    rules: <RuleConfig>[
      RuleConfig(
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
        weight: 2.0,
      ),
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
        enabled: true,
        weight: 0.8,
      ),
      RuleConfig(
        key: 'repeat',
        id: 'PIT-003',
        label: 'Repetición',
        category: 'Transición',
        description: 'Prueba',
        status: 'Experimental',
        evidenceLevel: 2,
        author: 'PIT',
        introducedVersion: '1.0.0',
        enabled: false,
        weight: 1.2,
      ),
    ],
    disclaimer: '',
  );

  test('calcula métricas dentro del rango de 0 a 100', () {
    const PitMetricsEngine engine = PitMetricsEngine();
    final metrics = engine.calculate(
      model: model,
      modelHistory: const <ModelConfig>[],
      drawHistory: List<List<int>>.generate(
        600,
        (int index) => <int>[1, 7, 13, 19, 25, 31],
      ),
      ranking: const [],
    );

    expect(metrics.overallHealth, inInclusiveRange(0, 100));
    expect(metrics.coverage, closeTo(66.666, 0.01));
    expect(metrics.evidence, inInclusiveRange(0, 100));
    expect(metrics.weightRobustness, inInclusiveRange(0, 100));
    expect(metrics.influences, isNotEmpty);
    expect(metrics.alerts, isNotEmpty);
  });

  test('advierte cuando no existe ranking', () {
    const PitMetricsEngine engine = PitMetricsEngine();
    final metrics = engine.calculate(
      model: model,
      modelHistory: const <ModelConfig>[],
      drawHistory: const <List<int>>[],
      ranking: const [],
    );

    expect(
      metrics.alerts.join(' '),
      contains('Genera un ranking'),
    );
  });
}
