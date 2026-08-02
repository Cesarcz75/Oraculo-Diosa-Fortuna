enum DiagnosticStatus {
  ready,
  warning,
  unavailable,
}

class DiagnosticCheck {
  const DiagnosticCheck({
    required this.title,
    required this.detail,
    required this.status,
  });

  final String title;
  final String detail;
  final DiagnosticStatus status;
}

class SystemDiagnostics {
  const SystemDiagnostics({
    required this.generatedAt,
    required this.checks,
  });

  final DateTime generatedAt;
  final List<DiagnosticCheck> checks;

  int get readyCount => checks
      .where((DiagnosticCheck item) =>
          item.status == DiagnosticStatus.ready)
      .length;

  int get warningCount => checks
      .where((DiagnosticCheck item) =>
          item.status == DiagnosticStatus.warning)
      .length;

  int get unavailableCount => checks
      .where((DiagnosticCheck item) =>
          item.status == DiagnosticStatus.unavailable)
      .length;

  bool get isOperational => unavailableCount == 0;

  String get overallLabel {
    if (unavailableCount > 0) {
      return 'Requiere atención';
    }
    if (warningCount > 0) {
      return 'Operativo con observaciones';
    }
    return 'Sistema listo';
  }
}
