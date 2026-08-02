import 'model_config.dart';

enum RuleChangeType {
  added,
  removed,
  activated,
  deactivated,
  weightChanged,
  unchanged,
}

class RuleComparison {
  const RuleComparison({
    required this.key,
    required this.label,
    required this.changeType,
    required this.firstEnabled,
    required this.secondEnabled,
    required this.firstWeight,
    required this.secondWeight,
  });

  final String key;
  final String label;
  final RuleChangeType changeType;
  final bool firstEnabled;
  final bool secondEnabled;
  final double firstWeight;
  final double secondWeight;

  double get weightDelta => secondWeight - firstWeight;
}

class ModelHealthSnapshot {
  const ModelHealthSnapshot({
    required this.activeRules,
    required this.totalRules,
    required this.totalWeight,
    required this.averageEvidence,
    required this.weightBalance,
    required this.pitIndex,
  });

  final int activeRules;
  final int totalRules;
  final double totalWeight;
  final double averageEvidence;
  final double weightBalance;
  final double pitIndex;
}

class ModelComparisonReport {
  const ModelComparisonReport({
    required this.first,
    required this.second,
    required this.firstHealth,
    required this.secondHealth,
    required this.rules,
  });

  final ModelConfig first;
  final ModelConfig second;
  final ModelHealthSnapshot firstHealth;
  final ModelHealthSnapshot secondHealth;
  final List<RuleComparison> rules;

  int get changedRules => rules
      .where((RuleComparison rule) =>
          rule.changeType != RuleChangeType.unchanged)
      .length;

  double get pitIndexDelta => secondHealth.pitIndex - firstHealth.pitIndex;

  List<RuleComparison> get onlyChanges => rules
      .where((RuleComparison rule) =>
          rule.changeType != RuleChangeType.unchanged)
      .toList(growable: false);
}
