import 'dart:math';
import '../models/model_comparison.dart';
import '../models/model_config.dart';

class ModelComparisonEngine {
  const ModelComparisonEngine();

  ModelComparisonReport compare({
    required ModelConfig first,
    required ModelConfig second,
  }) {
    final Map<String, RuleConfig> firstRules = <String, RuleConfig>{
      for (final RuleConfig rule in first.rules) rule.key: rule,
    };
    final Map<String, RuleConfig> secondRules = <String, RuleConfig>{
      for (final RuleConfig rule in second.rules) rule.key: rule,
    };
    final List<String> keys = <String>{
      ...firstRules.keys,
      ...secondRules.keys,
    }.toList()
      ..sort();

    final List<RuleComparison> comparisons = keys.map((String key) {
      final RuleConfig? a = firstRules[key];
      final RuleConfig? b = secondRules[key];
      final RuleChangeType changeType;

      if (a == null && b != null) {
        changeType = RuleChangeType.added;
      } else if (a != null && b == null) {
        changeType = RuleChangeType.removed;
      } else if (a!.enabled != b!.enabled) {
        changeType = b.enabled
            ? RuleChangeType.activated
            : RuleChangeType.deactivated;
      } else if ((a.weight - b.weight).abs() > 0.000001) {
        changeType = RuleChangeType.weightChanged;
      } else {
        changeType = RuleChangeType.unchanged;
      }

      return RuleComparison(
        key: key,
        label: b?.label ?? a?.label ?? key,
        changeType: changeType,
        firstEnabled: a?.enabled ?? false,
        secondEnabled: b?.enabled ?? false,
        firstWeight: a?.weight ?? 0,
        secondWeight: b?.weight ?? 0,
      );
    }).toList(growable: false);

    return ModelComparisonReport(
      first: first,
      second: second,
      firstHealth: health(first),
      secondHealth: health(second),
      rules: comparisons,
    );
  }

  ModelHealthSnapshot health(ModelConfig config) {
    final List<RuleConfig> active = config.rules
        .where((RuleConfig rule) => rule.enabled)
        .toList(growable: false);
    final double totalWeight = active.fold<double>(
      0,
      (double total, RuleConfig rule) => total + rule.weight,
    );
    final double averageEvidence = active.isEmpty
        ? 0
        : active.fold<double>(
              0,
              (double total, RuleConfig rule) =>
                  total + rule.evidenceLevel,
            ) /
            active.length;

    double balance = 0;
    if (active.length > 1 && totalWeight > 0) {
      final double mean = totalWeight / active.length;
      final double variance = active.fold<double>(
            0,
            (double total, RuleConfig rule) =>
                total + pow(rule.weight - mean, 2).toDouble(),
          ) /
          active.length;
      final double coefficient = mean == 0 ? 1 : sqrt(variance) / mean;
      balance = (100 * (1 - coefficient)).clamp(0, 100).toDouble();
    } else if (active.length == 1) {
      balance = 50;
    }

    final double coverage = config.rules.isEmpty
        ? 0
        : 100 * active.length / config.rules.length;
    final double evidenceScore = 20 * averageEvidence;
    final double pitIndex =
        (coverage * 0.30 + evidenceScore * 0.40 + balance * 0.30)
            .clamp(0, 100)
            .toDouble();

    return ModelHealthSnapshot(
      activeRules: active.length,
      totalRules: config.rules.length,
      totalWeight: totalWeight,
      averageEvidence: averageEvidence,
      weightBalance: balance,
      pitIndex: pitIndex,
    );
  }
}
