import 'package:flutter_test/flutter_test.dart';
import 'package:oraculo_diosa_fortuna/core/models/model_config.dart';
import 'package:oraculo_diosa_fortuna/core/models/system_diagnostics.dart';
import 'package:oraculo_diosa_fortuna/core/services/system_diagnostics_engine.dart';

void main() {
  const ModelConfig model = ModelConfig(
    modelName: 'Modelo Oficial PIT',
    modelVersion: '1.0.0',
    engineName: 'Motor Fortuna',
    engineVersion: '5.5.0',
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
        weight: 1.0,
      ),
    ],
    disclaimer: '',
  );

  test('reporta sistema operativo con modelo e histórico', () {
    final SystemDiagnostics diagnostics =
        const SystemDiagnosticsEngine().run(
      model: model,
      drawHistory: List<List<int>>.generate(
        200,
        (int index) => <int>[1, 7, 13, 19, 25, 31],
      ),
      ranking: const [],
      savedModelVersions: 1,
    );

    expect(diagnostics.isOperational, isTrue);
    expect(diagnostics.unavailableCount, 0);
    expect(diagnostics.warningCount, greaterThanOrEqualTo(1));
    expect(diagnostics.checks, hasLength(8));
  });

  test('marca indisponible cuando faltan modelo e histórico', () {
    final SystemDiagnostics diagnostics =
        const SystemDiagnosticsEngine().run(
      model: null,
      drawHistory: const <List<int>>[],
      ranking: const [],
      savedModelVersions: 0,
    );

    expect(diagnostics.isOperational, isFalse);
    expect(diagnostics.unavailableCount, 2);
    expect(
      diagnostics.checks.first.status,
      DiagnosticStatus.unavailable,
    );
  });
}
