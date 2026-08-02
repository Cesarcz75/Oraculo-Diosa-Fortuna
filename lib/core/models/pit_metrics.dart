class PitRuleInfluence {
  const PitRuleInfluence({
    required this.label,
    required this.value,
    required this.share,
  });

  final String label;
  final double value;
  final double share;
}

class PitMetrics {
  const PitMetrics({
    required this.overallHealth,
    required this.coverage,
    required this.evidence,
    required this.scoreBalance,
    required this.weightRobustness,
    required this.historicalDepth,
    required this.versionMaturity,
    required this.healthLabel,
    required this.influences,
    required this.alerts,
  });

  final double overallHealth;
  final double coverage;
  final double evidence;
  final double scoreBalance;
  final double weightRobustness;
  final double historicalDepth;
  final double versionMaturity;
  final String healthLabel;
  final List<PitRuleInfluence> influences;
  final List<String> alerts;
}
