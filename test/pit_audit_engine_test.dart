import 'package:flutter_test/flutter_test.dart';
import 'package:oraculo_diosa_fortuna/core/models/model_config.dart';
import 'package:oraculo_diosa_fortuna/core/models/pit_audit.dart';
import 'package:oraculo_diosa_fortuna/core/services/pit_audit_engine.dart';

void main() {
  test('detecta evidencia baja y pesos elevados', () {
    const ModelConfig model = ModelConfig(
      modelName: 'Modelo PIT',
      modelVersion: '1.0.0',
      engineName: 'Motor Fortuna',
      engineVersion: '5.2.0',
      rules: <RuleConfig>[
        RuleConfig(
          key: 'sum',
          id: 'PIT-001',
          label: 'Suma',
          category: 'Distribución',
          description: 'Prueba',
          status: 'Experimental',
          evidenceLevel: 1,
          author: 'PIT',
          introducedVersion: '1.0.0',
          enabled: true,
          weight: 2.8,
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
      ],
      disclaimer: '',
    );

    final PitAuditReport report = const PitAuditEngine().audit(
      model: model,
      drawHistory: List<List<int>>.generate(
        600,
        (int index) => <int>[1, 7, 13, 19, 25, 31],
      ),
      ranking: const [],
    );

    expect(report.findings, isNotEmpty);
    expect(
      report.findings.any(
        (PitAuditFinding item) => item.code == 'AUD-101',
      ),
      isTrue,
    );
    expect(
      report.findings.any(
        (PitAuditFinding item) => item.code == 'AUD-202',
      ),
      isTrue,
    );
    expect(report.score, inInclusiveRange(0, 100));
  });

  test('detecta un modelo sin reglas activas', () {
    const ModelConfig model = ModelConfig(
      modelName: 'Modelo PIT',
      modelVersion: '1.0.0',
      engineName: 'Motor Fortuna',
      engineVersion: '5.2.0',
      rules: <RuleConfig>[],
      disclaimer: '',
    );

    final PitAuditReport report = const PitAuditEngine().audit(
      model: model,
      drawHistory: const <List<int>>[],
      ranking: const [],
    );

    expect(report.criticalCount, greaterThan(0));
    expect(
      report.findings.any(
        (PitAuditFinding item) => item.code == 'AUD-001',
      ),
      isTrue,
    );
  });
}
