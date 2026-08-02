enum PitAuditSeverity {
  info,
  warning,
  critical,
}

class PitAuditFinding {
  const PitAuditFinding({
    required this.code,
    required this.title,
    required this.description,
    required this.recommendation,
    required this.severity,
    this.ruleId,
    this.ruleLabel,
  });

  final String code;
  final String title;
  final String description;
  final String recommendation;
  final PitAuditSeverity severity;
  final String? ruleId;
  final String? ruleLabel;
}

class PitAuditReport {
  const PitAuditReport({
    required this.generatedAt,
    required this.score,
    required this.status,
    required this.findings,
  });

  final DateTime generatedAt;
  final double score;
  final String status;
  final List<PitAuditFinding> findings;

  int get criticalCount => findings
      .where((PitAuditFinding item) =>
          item.severity == PitAuditSeverity.critical)
      .length;

  int get warningCount => findings
      .where((PitAuditFinding item) =>
          item.severity == PitAuditSeverity.warning)
      .length;

  int get infoCount => findings
      .where((PitAuditFinding item) =>
          item.severity == PitAuditSeverity.info)
      .length;
}
