import 'package:flutter_test/flutter_test.dart';
import 'package:oraculo_diosa_fortuna/core/models/model_config.dart';
import 'package:oraculo_diosa_fortuna/core/services/pit_audit_engine.dart';
import 'package:oraculo_diosa_fortuna/core/services/pit_metrics_engine.dart';

void main() {
  const ModelConfig model = ModelConfig(
    modelName: 'Modelo Oficial PIT',
    modelVersion: '1.0.0',
    engineName: 'Motor Fortuna',
    engineVersion: '5.4.0',
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
        weight: 1.4,
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
        evidenceLevel: 3,
        author: 'PIT',
        introducedVersion: '1.0.0',
        enabled: true,
        weight: 1.0,
      ),
    ],
    disclaimer: '',
  );

  final List<List<int>> history = List<List<int>>.generate(
    600,
    (int index) => <int>[1, 7, 13, 19, 25, 31],
  );

  test('genera indicadores válidos para el Dashboard Premium', () {
    final metrics = const PitMetricsEngine().calculate(
      model: model,
      modelHistory: const <ModelConfig>[],
      drawHistory: history,
      ranking: const [],
    );
    final audit = const PitAuditEngine().audit(
      model: model,
      drawHistory: history,
      ranking: const [],
    );

    expect(metrics.overallHealth, inInclusiveRange(0, 100));
    expect(metrics.coverage, 100);
    expect(audit.score, inInclusiveRange(0, 100));
    expect(model.activeRuleCount, 3);
  });
}
