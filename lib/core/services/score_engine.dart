import 'dart:math';
import '../models/score_breakdown.dart';

class ScoreEngine {
  const ScoreEngine();

  ScoreBreakdown build(Map<String, double> weightedContributions) {
    final List<MapEntry<String, double>> entries =
        weightedContributions.entries.toList(growable: false);

    final double total = entries.fold<double>(
      0,
      (double value, MapEntry<String, double> entry) => value + entry.value,
    );

    final double magnitude = entries.fold<double>(
      0,
      (double value, MapEntry<String, double> entry) =>
          value + entry.value.abs(),
    );

    final List<RuleScore> rules = entries.map((MapEntry<String, double> entry) {
      return RuleScore(
        label: entry.key,
        weightedValue: entry.value,
        influence: magnitude == 0 ? 0 : entry.value.abs() / magnitude,
      );
    }).toList(growable: false)
      ..sort(
        (RuleScore a, RuleScore b) =>
            b.influence.compareTo(a.influence),
      );

    return ScoreBreakdown(
      total: total,
      pitIndex: _calculatePitIndex(rules),
      rules: List<RuleScore>.unmodifiable(rules),
    );
  }

  double _calculatePitIndex(List<RuleScore> rules) {
    final List<double> shares = rules
        .map((RuleScore item) => item.influence)
        .where((double value) => value > 0)
        .toList(growable: false);

    if (shares.length <= 1) {
      return shares.isEmpty ? 0 : 50;
    }

    final double entropy = shares.fold<double>(
      0,
      (double total, double share) => total - share * log(share),
    );
    final double maximumEntropy = log(shares.length);
    return (100 * entropy / maximumEntropy).clamp(0, 100).toDouble();
  }
}
