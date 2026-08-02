import 'package:flutter_test/flutter_test.dart';
import 'package:oraculo_diosa_fortuna/core/models/model_config.dart';
import 'package:oraculo_diosa_fortuna/core/models/professional_report_data.dart';

void main() {
  test('calcula reglas activas y peso total del reporte', () {
    final ProfessionalReportData data = ProfessionalReportData(
      generatedAt: DateTime(2026, 8, 2),
      softwareVersion: '4.4.0',
      model: const ModelConfig(
        modelName: 'Modelo Oficial PIT',
        modelVersion: '1.0.0',
        engineName: 'Motor Fortuna',
        engineVersion: '4.4.0',
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
            enabled: false,
            weight: 0.8,
          ),
        ],
        disclaimer: '',
      ),
      historyCount: 1651,
      ranking: const [],
      observations: '',
    );

    expect(data.activeRuleCount, 1);
    expect(data.activeWeightTotal, 2.0);
    expect(data.leader, isNull);
  });
}
