import '../models/model_config.dart';
import '../models/ranked_combination.dart';
import '../models/system_diagnostics.dart';

class SystemDiagnosticsEngine {
  const SystemDiagnosticsEngine();

  SystemDiagnostics run({
    required ModelConfig? model,
    required List<List<int>> drawHistory,
    required List<RankedCombination> ranking,
    required int savedModelVersions,
  }) {
    final List<DiagnosticCheck> checks = <DiagnosticCheck>[
      DiagnosticCheck(
        title: 'Modelo PIT',
        detail: model == null
            ? 'No se pudo cargar la configuración del modelo.'
            : 'Modelo v${model.modelVersion} con '
                '${model.activeRuleCount} reglas activas.',
        status: model == null
            ? DiagnosticStatus.unavailable
            : model.activeRuleCount == 0
                ? DiagnosticStatus.warning
                : DiagnosticStatus.ready,
      ),
      DiagnosticCheck(
        title: 'Histórico',
        detail: drawHistory.isEmpty
            ? 'No hay sorteos disponibles.'
            : '${drawHistory.length} sorteos cargados.',
        status: drawHistory.isEmpty
            ? DiagnosticStatus.unavailable
            : drawHistory.length < 100
                ? DiagnosticStatus.warning
                : DiagnosticStatus.ready,
      ),
      DiagnosticCheck(
        title: 'Ranking',
        detail: ranking.isEmpty
            ? 'Todavía no se ha generado un ranking en esta sesión.'
            : '${ranking.length} combinaciones evaluadas.',
        status: ranking.isEmpty
            ? DiagnosticStatus.warning
            : DiagnosticStatus.ready,
      ),
      DiagnosticCheck(
        title: 'Versionado',
        detail: savedModelVersions == 0
            ? 'No hay versiones personalizadas guardadas.'
            : '$savedModelVersions versiones disponibles.',
        status: savedModelVersions == 0
            ? DiagnosticStatus.warning
            : DiagnosticStatus.ready,
      ),
      const DiagnosticCheck(
        title: 'ATHENA',
        detail: 'Motor analítico local disponible.',
        status: DiagnosticStatus.ready,
      ),
      const DiagnosticCheck(
        title: 'Métricas y Auditor',
        detail: 'Motores metodológicos disponibles.',
        status: DiagnosticStatus.ready,
      ),
      const DiagnosticCheck(
        title: 'Simulador PIT',
        detail: 'Simulación temporal disponible.',
        status: DiagnosticStatus.ready,
      ),
      const DiagnosticCheck(
        title: 'Reportes PDF',
        detail: 'Generador profesional disponible.',
        status: DiagnosticStatus.ready,
      ),
    ];

    return SystemDiagnostics(
      generatedAt: DateTime.now(),
      checks: List<DiagnosticCheck>.unmodifiable(checks),
    );
  }
}
