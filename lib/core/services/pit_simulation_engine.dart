import '../models/model_config.dart';
import '../models/pit_audit.dart';
import '../models/pit_metrics.dart';
import '../models/pit_simulation.dart';
import '../models/ranked_combination.dart';
import 'pit_audit_engine.dart';
import 'pit_metrics_engine.dart';
import 'statistical_engine.dart';

class PitSimulationEngine {
  const PitSimulationEngine();

  PitSimulationResult simulate({
    required ModelConfig officialModel,
    required ModelConfig experimentalModel,
    required List<ModelConfig> modelHistory,
    required List<List<int>> drawHistory,
    required List<RankedCombination> officialRanking,
  }) {
    if (drawHistory.length < 20) {
      throw ArgumentError('Se requieren al menos 20 sorteos.');
    }

    final List<int> latest = drawHistory.last;
    final StatisticalEngine experimentalEngine =
        StatisticalEngine(drawHistory, experimentalModel);

    final List<RankedCombination> experimentalRanking = officialRanking
        .map(
          (RankedCombination item) =>
              experimentalEngine.evaluate(item.numbers, latest),
        )
        .toList(growable: false)
      ..sort(
        (RankedCombination a, RankedCombination b) =>
            b.score.compareTo(a.score),
      );

    final PitMetrics officialMetrics =
        const PitMetricsEngine().calculate(
      model: officialModel,
      modelHistory: modelHistory,
      drawHistory: drawHistory,
      ranking: officialRanking,
    );

    final PitMetrics experimentalMetrics =
        const PitMetricsEngine().calculate(
      model: experimentalModel,
      modelHistory: modelHistory,
      drawHistory: drawHistory,
      ranking: experimentalRanking,
    );

    final PitAuditReport officialAudit =
        const PitAuditEngine().audit(
      model: officialModel,
      drawHistory: drawHistory,
      ranking: officialRanking,
    );

    final PitAuditReport experimentalAudit =
        const PitAuditEngine().audit(
      model: experimentalModel,
      drawHistory: drawHistory,
      ranking: experimentalRanking,
    );

    return PitSimulationResult(
      officialModel: officialModel,
      experimentalModel: experimentalModel,
      officialRanking:
          List<RankedCombination>.unmodifiable(officialRanking),
      experimentalRanking:
          List<RankedCombination>.unmodifiable(experimentalRanking),
      officialMetrics: officialMetrics,
      experimentalMetrics: experimentalMetrics,
      officialAudit: officialAudit,
      experimentalAudit: experimentalAudit,
      changedPositions: _changedPositions(
        officialRanking,
        experimentalRanking,
      ),
    );
  }

  int _changedPositions(
    List<RankedCombination> official,
    List<RankedCombination> experimental,
  ) {
    final int count =
        official.length < experimental.length
            ? official.length
            : experimental.length;
    int changed = 0;

    for (int index = 0; index < count; index++) {
      if (official[index].label != experimental[index].label) {
        changed++;
      }
    }

    return changed;
  }
}
