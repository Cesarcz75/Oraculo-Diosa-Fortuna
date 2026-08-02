import 'model_config.dart';
import 'pit_audit.dart';
import 'pit_metrics.dart';
import 'ranked_combination.dart';

class PitSimulationResult {
  const PitSimulationResult({
    required this.officialModel,
    required this.experimentalModel,
    required this.officialRanking,
    required this.experimentalRanking,
    required this.officialMetrics,
    required this.experimentalMetrics,
    required this.officialAudit,
    required this.experimentalAudit,
    required this.changedPositions,
  });

  final ModelConfig officialModel;
  final ModelConfig experimentalModel;
  final List<RankedCombination> officialRanking;
  final List<RankedCombination> experimentalRanking;
  final PitMetrics officialMetrics;
  final PitMetrics experimentalMetrics;
  final PitAuditReport officialAudit;
  final PitAuditReport experimentalAudit;
  final int changedPositions;

  double get healthDelta =>
      experimentalMetrics.overallHealth - officialMetrics.overallHealth;

  double get auditDelta =>
      experimentalAudit.score - officialAudit.score;

  double get leaderScoreDelta {
    if (officialRanking.isEmpty || experimentalRanking.isEmpty) {
      return 0;
    }
    return experimentalRanking.first.score - officialRanking.first.score;
  }

  double get leaderPitIndexDelta {
    if (officialRanking.isEmpty || experimentalRanking.isEmpty) {
      return 0;
    }
    return experimentalRanking.first.pitIndex -
        officialRanking.first.pitIndex;
  }
}
